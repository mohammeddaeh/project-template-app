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
/// Caching a response claims its data is slow-moving: true of catalogues
/// (permissions, languages), false of anything a user edits. A cached editable
/// resource returns the pre-edit state inside the TTL, and a new server field
/// stays invisible until it lapses — so each endpoint opts in explicitly.
///
/// ## Invalidation
/// [invalidate] / [invalidateAll] — required after any mutation that affects a
/// cached GET. If a resource needs invalidation logic to stay correct, prefer
/// not caching it at all.
///
/// ## Rules enforced here
/// 1. **A fallback path logs.** A silent `catch (_) {}` around the read path
///    would make a broken cache indistinguishable from a cold one.
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

  /// Explicit "do not cache". Not caching is the default, so this is a no-op
  /// kept for call sites that state it.
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
                  '${DateTime.now().millisecondsSinceEpoch - entry.cachedAt}ms',
                ],
              }),
            ),
          );
        }
        LogService.info('Cache STALE — ${options.path}', tag: 'CACHE');
      } catch (e) {
        // Corrupt entry — fall through to the network, but **say so**: a
        // fallback that cannot be observed is indistinguishable from a broken
        // one, and a read that always throws would look like a cold cache.
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
      LogService.info(
        'Cache WRITE — ${response.requestOptions.path}',
        tag: 'CACHE',
      );
    }

    handler.next(response);
  }

  // ── Cache management ───────────────────────────────────────────────────────

  /// Removes the cached response for [path] + optional [queryParameters].
  Future<void> invalidate(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final key = _buildKeyFromParts(path, queryParameters ?? {});
    return _storage.delete('$_keyPrefix$key');
  }

  /// Removes **all** cached HTTP responses — and nothing else.
  ///
  /// Deletes by prefix rather than `_storage.clear()`: the same box holds
  /// theme, language, font and the cached user snapshot, and clearing it would
  /// wipe every preference and the session along with the responses.
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
    // see the class doc for why.
    return options.extra[cacheKey] == true;
  }

  static String _buildKey(RequestOptions options) =>
      _buildKeyFromParts(options.path, options.queryParameters);

  static String _buildKeyFromParts(String path, Map<String, dynamic> params) {
    final query = params.entries.toList()
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
