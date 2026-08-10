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
  ) {
    if (!_isCacheable(options)) return handler.next(options);

    final cacheKey = _buildKey(options);
    final ttl = options.extra[ttlKey] as Duration? ?? defaultTtl;
    final raw = _storage.containsKey('$_keyPrefix$cacheKey')
        ? _storage.readString('$_keyPrefix$cacheKey')
        : null;

    if (raw != null) {
      try {
        final entry = _CacheEntry.fromJson(raw as String);
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
      } catch (_) {
        // Corrupt cache entry — fall through to network
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

  /// Removes **all** cached HTTP responses.
  Future<void> invalidateAll() => _storage.clear();

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
