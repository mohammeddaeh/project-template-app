import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

/// Caches GET responses locally and serves them within the TTL window.
///
/// ## Behaviour
/// ```
/// GET /products
///   ├─ Cached + still valid  → return cached response immediately (0 ms) ✅
///   ├─ Cached but expired    → fetch + refresh cache
///   └─ Not cached            → fetch + store in cache
/// ```
///
/// ## Per-request TTL override
/// ```dart
/// // UseCase / Repository:
/// dio.get('/products', options: Options(extra: {
///   RequestCacheInterceptor.ttlKey: const Duration(hours: 1),
/// }));
/// ```
///
/// ## Skip cache for a specific request
/// ```dart
/// dio.get('/products', options: Options(extra: {
///   RequestCacheInterceptor.skipKey: true,
/// }));
/// ```
///
/// ## Invalidation
/// Call [invalidate] or [invalidateAll] from a Repository after a mutation
/// (POST/PUT/DELETE) that should bust the cache.
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
    return true;
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
