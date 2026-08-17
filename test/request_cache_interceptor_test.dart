import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/infra/network/interceptors/request_cache_interceptor.dart';
import 'package:app_template/core/platform/storage/adapters/in_memory_storage_adapter.dart';

/// Regression tests for a cache that **wrote entries it could never read back**.
///
/// [RequestCacheInterceptor.onRequest] did not `await` the storage read, so it
/// compared a `Future` against `null` (never null), cast it to `String`, threw,
/// and swallowed the throw in a bare `catch (_) {}`. Every request missed. The
/// module behaved exactly like a cold cache — correct answers, full latency,
/// growing storage — so nothing failed and there was no symptom to search for.
///
/// `dart analyze` was clean and the whole suite was green throughout, which is
/// the point of these tests: the only observable difference between "the cache
/// works" and "the cache has never once worked" is a hit, so a hit is what has
/// to be asserted.
void main() {
  late InMemoryStorageAdapter storage;
  late RequestCacheInterceptor interceptor;

  setUp(() {
    storage = InMemoryStorageAdapter();
    interceptor = RequestCacheInterceptor(storage);
  });

  /// Runs a request through the interceptor and reports whether it was answered
  /// from the cache (`resolve`) or passed to the network (`next`).
  Future<Response<dynamic>?> ask(RequestOptions options) async {
    Response<dynamic>? resolved;
    final handler = _RecordingRequestHandler(onResolve: (r) => resolved = r);
    interceptor.onRequest(options, handler);
    await handler.settled;
    return resolved;
  }

  RequestOptions cacheable(String path, {Duration? ttl}) => RequestOptions(
        path: path,
        method: 'GET',
        extra: <String, dynamic>{
          RequestCacheInterceptor.cacheKey: true,
          RequestCacheInterceptor.ttlKey: ?ttl,
        },
      );

  group('read path', () {
    test('a written entry is served back — the bug this file exists for',
        () async {
      final options = cacheable('/notes');

      interceptor.onResponse(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {'status': true, 'data': 'from-cache'},
        ),
        _NoopResponseHandler(),
      );
      await Future<void>.delayed(Duration.zero);

      final hit = await ask(cacheable('/notes'));

      expect(hit, isNotNull, reason: 'the cache must answer a repeat GET');
      expect((hit!.data as Map)['data'], 'from-cache');
      expect(hit.headers.value('x-from-cache'), 'true');
    });

    test('an expired entry falls through to the network', () async {
      final options = cacheable('/notes', ttl: Duration.zero);

      interceptor.onResponse(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {'data': 'stale'},
        ),
        _NoopResponseHandler(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(await ask(cacheable('/notes', ttl: Duration.zero)), isNull);
    });

    test('a request that did not opt in is never served from cache', () async {
      final opted = cacheable('/notes');
      interceptor.onResponse(
        Response<dynamic>(
          requestOptions: opted,
          statusCode: 200,
          data: {'data': 'x'},
        ),
        _NoopResponseHandler(),
      );
      await Future<void>.delayed(Duration.zero);

      final plain = RequestOptions(path: '/notes', method: 'GET');
      expect(await ask(plain), isNull);
    });

    test('query parameters are part of the key', () async {
      final page1 = RequestOptions(
        path: '/notes',
        method: 'GET',
        queryParameters: {'page': 1},
        extra: {RequestCacheInterceptor.cacheKey: true},
      );
      interceptor.onResponse(
        Response<dynamic>(
          requestOptions: page1,
          statusCode: 200,
          data: {'data': 'page-1'},
        ),
        _NoopResponseHandler(),
      );
      await Future<void>.delayed(Duration.zero);

      final page2 = RequestOptions(
        path: '/notes',
        method: 'GET',
        queryParameters: {'page': 2},
        extra: {RequestCacheInterceptor.cacheKey: true},
      );
      expect(await ask(page2), isNull, reason: 'page 2 is not page 1');
    });
  });

  group('invalidateAll', () {
    test('removes cached responses and NOTHING else', () async {
      // A preference living alongside the cache in the same store — exactly
      // what `_storage.clear()` used to destroy.
      await storage.writeString('app_theme_mode', 'dark');
      await storage.writeString('app_locale', 'ar');

      interceptor.onResponse(
        Response<dynamic>(
          requestOptions: cacheable('/notes'),
          statusCode: 200,
          data: {'data': 'x'},
        ),
        _NoopResponseHandler(),
      );
      await Future<void>.delayed(Duration.zero);

      await interceptor.invalidateAll();

      expect(await ask(cacheable('/notes')), isNull,
          reason: 'the cached response must be gone');
      expect(await storage.readString('app_theme_mode'), 'dark',
          reason: 'invalidating the HTTP cache must not sign the user out of '
              'their own settings');
      expect(await storage.readString('app_locale'), 'ar');
    });
  });
}

// ── Test doubles ─────────────────────────────────────────────────────────────

/// Captures whichever terminal call the interceptor makes, and exposes a future
/// that completes when one arrives — [RequestCacheInterceptor.onRequest] is
/// asynchronous, so the assertion must wait for it rather than run beside it.
class _RecordingRequestHandler extends RequestInterceptorHandler {
  _RecordingRequestHandler({required this.onResolve});

  final void Function(Response<dynamic>) onResolve;
  final _done = Completer<void>();

  Future<void> get settled => _done.future;

  void _settle() {
    if (!_done.isCompleted) _done.complete();
  }

  @override
  void next(RequestOptions requestOptions) => _settle();

  @override
  void resolve(
    Response<dynamic> response, [
    bool callFollowingResponseInterceptor = false,
  ]) {
    onResolve(response);
    _settle();
  }

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) =>
      _settle();

  @override
  bool get isCompleted => _done.isCompleted;
}

class _NoopResponseHandler extends ResponseInterceptorHandler {
  @override
  void next(Response<dynamic> response) {}

  @override
  void resolve(Response<dynamic> response) {}

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) {}

  @override
  bool get isCompleted => false;
}
