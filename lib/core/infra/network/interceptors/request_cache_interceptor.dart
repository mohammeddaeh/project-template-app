import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

/// Caches GET responses locally and serves them within the TTL window.
///
/// ## OPT-IN — a response is cached only when its request asks to be
///
/// ```dart
/// dio.get('/permissions', options: Options(extra: {
///   RequestCacheInterceptor.cacheKey: true,
///   RequestCacheInterceptor.ttlKey: const Duration(hours: 1),  // optional
/// }));
/// ```
///
/// **This used to be opt-OUT — every GET cached for five minutes — and it was
/// wrong in a way that looked like broken features rather than stale data:**
///
/// - The doc below says to call [invalidate] after a mutation. Nothing ever
///   did. So editing an assignment and re-reading the list inside the TTL
///   returned the state from *before* the edit, and the screen looked like the
///   write had silently failed.
/// - A change to a response's SHAPE (a new field on the server) stayed
///   invisible until the TTL lapsed, so a deployed backend fix appeared not to
///   work. `branch_status` on assignments was exactly this.
///
/// Caching a response is a claim that its data is slow-moving. That is true of
/// catalogues (permissions, languages) and false of everything an admin edits.
/// Defaulting to "true for everything" made that claim on every endpoint's
/// behalf. Opting in makes it a decision someone took, once, in writing.
///
/// ## Invalidation
/// [invalidate] / [invalidateAll] — required after any mutation that affects a
/// cached GET. If a resource needs invalidation logic to stay correct, prefer
/// not caching it at all.
///
/// ## ⚠️ Why this file is the reason `catch (_)` is banned in this template
///
/// For its whole life this interceptor **wrote entries it could never read
/// back**. [StorageService.readString] returns a `Future<String?>`; the read
/// path did not `await` it, compared the *Future* against `null` (never null),
/// then cast it to `String`. Every cacheable request threw a cast error on the
/// first hit — into a bare `catch (_) {}` that logged nothing and fell through
/// to the network.
///
/// So the module behaved exactly like a cold cache forever: correct answers,
/// full latency, growing storage. `dart analyze` was clean, every test passed,
/// and there was no symptom to search for. The bug was not the missing `await`
/// — that is a typo anyone makes. The bug was the empty catch that made the
/// typo unobservable.
///
/// Two rules came out of it, and both are enforced here:
/// 1. **A fallback path logs.** `catch (_) {}` converts a defect into a
///    behaviour, and a behaviour nobody specified is one nobody will fix.
/// 2. **Ordering matters.** This interceptor must sit *before*
///    `InternetCheckerInterceptor` in `injection_module.dart`, or an offline
///    device is rejected before the cache it exists to serve is ever consulted.
///
/// ## Registration
/// Created manually in [InjectionModule] — NOT annotated with `@injectable`.
class RequestCacheInterceptor extends Interceptor {
  RequestCacheInterceptor(
    this._storage, {
    this.defaultTtl = const Duration(minutes: 5),
  });

  final StorageService _storage;
  final Duration defaultTtl;

  static const ttlKey = '_cacheTtl';

  /// Opt in to caching for one request: `extra: {cacheKey: true}`.
  static const cacheKey = '_useCache';

  /// Retained so existing `skipKey: true` call sites keep meaning "do not
  /// cache" — which is now the default anyway, so it is a no-op rather than a
  /// silent behaviour change.
  static const skipKey = '_skipCache';

  static const _keyPrefix = '__http_cache__';

  // ── Interceptor hooks ──────────────────────────────────────────────────────

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isCacheable(options)) return handler.next(options);

    final cacheKey = _buildKey(options);
    final ttl = options.extra[ttlKey] as Duration? ?? defaultTtl;
    final raw = _storage.containsKey('$_keyPrefix$cacheKey')
        ? await _storage.readString('$_keyPrefix$cacheKey')
        : null;

    if (raw != null) {
      try {
        final entry = _CacheEntry.fromJson(raw);
        if (entry.isValid(ttl)) {
          LogService.info('Cache HIT — ${options.path}', tag: 'CACHE');
          return handler.resolve(
            Response(
              requestOptions: options,
              data: entry.data,
              statusCode: 200,
              headers: Headers.fromMap({
                'x-from-cache': ['true'],
                'x-cache-age': [
                  '${DateTime.now().millisecondsSinceEpoch - entry.cachedAt}ms'
                ],
              }),
            ),
          );
        }
        LogService.info('Cache STALE — ${options.path}', tag: 'CACHE');
      } catch (e) {
        // Corrupt entry — fall through to the network, but **say so**. This
        // catch used to be silent, and it is what hid the bug above for the
        // module's entire life: every read threw, every throw was swallowed,
        // and the only symptom was a cache that never hit. A fallback path
        // that cannot be observed is indistinguishable from a broken one.
        LogService.warning(
          'Cache entry unreadable — ${options.path}: $e',
          tag: 'CACHE',
        );
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (_isCacheable(response.requestOptions) &&
        response.statusCode == 200 &&
        response.data != null) {
      final cacheKey = _buildKey(response.requestOptions);
      final entry = _CacheEntry(
        data: response.data,
        cachedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _storage.writeString('$_keyPrefix$cacheKey', entry.toJson());
      LogService.info('Cache WRITE — ${response.requestOptions.path}', tag: 'CACHE');
    }

    handler.next(response);
  }

  // ── Cache management ───────────────────────────────────────────────────────

  /// Removes the cached response for [path] + optional [queryParameters].
  Future<void> invalidate(String path, {Map<String, dynamic>? queryParameters}) {
    final key = _buildKeyFromParts(path, queryParameters ?? {});
    return _storage.delete('$_keyPrefix$key');
  }

  /// Removes **all** cached HTTP responses — and nothing else.
  ///
  /// This used to be `_storage.clear()`, which empties the whole box: theme,
  /// language, chosen font, the cached user snapshot the splash screen reads
  /// before navigating. A method named "invalidate the HTTP cache" signed the
  /// user out of every preference they had set, and the doc comment right here
  /// promised it only touched cached responses.
  ///
  /// Nothing in the template called it, which is the only reason it never
  /// shipped as a bug report — the trap was armed and waiting for the first
  /// project to reach for it.
  Future<void> invalidateAll() async {
    final ours = _storage
        .keys()
        .where((k) => k.startsWith(_keyPrefix))
        .toList(growable: false);

    for (final key in ours) {
      await _storage.delete(key);
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static bool _isCacheable(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') return false;
    if (options.extra[skipKey] == true) return false;
    // Opt-in. Anything that has not asked to be cached is fetched fresh —
    // see the class doc for why the inverse was a bug factory.
    return options.extra[cacheKey] == true;
  }

  static String _buildKey(RequestOptions options) =>
      _buildKeyFromParts(options.path, options.queryParameters);

  static String _buildKeyFromParts(
    String path,
    Map<String, dynamic> params,
  ) {
    final query = params.entries
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final queryStr = query.map((e) => '${e.key}=${e.value}').join('&');
    return queryStr.isEmpty ? path : '$path?$queryStr';
  }
}

// ── Internal cache entry ───────────────────────────────────────────────────────

class _CacheEntry {
  const _CacheEntry({required this.data, required this.cachedAt});

  final dynamic data;
  final int cachedAt; // epoch milliseconds

  bool isValid(Duration ttl) =>
      DateTime.now().millisecondsSinceEpoch - cachedAt < ttl.inMilliseconds;

  String toJson() => jsonEncode({'data': data, 'cachedAt': cachedAt});

  factory _CacheEntry.fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return _CacheEntry(data: map['data'], cachedAt: map['cachedAt'] as int);
  }
}
