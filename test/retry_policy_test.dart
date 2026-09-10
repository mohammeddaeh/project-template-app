import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/infra/network/interceptors/internet_checker_interceptor.dart';
import 'package:app_template/core/infra/network/interceptors/retry_interceptor.dart';

/// How many times the app hits a struggling server, and whether it listens when
/// that server asks for room.
///
/// Counted through a fake adapter rather than asserted on a private predicate:
/// the number that matters is how many requests actually leave the device.
class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter(this.statusCode, {this.headers = const {}});

  final int statusCode;
  final Map<String, List<String>> headers;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString('{}', statusCode, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  Dio dioWith(_CountingAdapter adapter, {Duration? initial}) {
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      RetryInterceptor(
        dio,
        initialDelay: initial ?? const Duration(milliseconds: 1),
      ),
    );
    return dio;
  }

  Future<int> callsFor(_CountingAdapter adapter, {Duration? initial}) async {
    try {
      await dioWith(adapter, initial: initial).get<dynamic>('/x');
    } on DioException {
      // expected — every case here ends in failure
    }
    return adapter.calls;
  }


  test(
    'a request blocked because the device has no network interface is NOT '
    'retried — it never left the device',
    () async {
      // الرفضُ يصل بهيئة `connectionError`، وهي مؤهَّلةٌ للإعادة بحقّ (انقطاعٌ
      // عابر وسطَ رحلة). والوسمُ وحده يفرّق — وبلاه تُعاد ثلاثُ محاولاتٍ
      // بتراجعٍ ١+٢+٤ ثانية، **وثلاثتُها تُمنع من الباب نفسِه**.
      //
      // ⚠️ **ويُعَدُّ ما يُحاوَل لا ما يصل**: الحارسُ الذي يمنع الطلبَ يمنع كذلك
      //    كلَّ إعادةٍ له، فعدّادُ المحوّل **صفرٌ بالحالتين** — واختبارٌ يقيسه
      //    يمرّ وهو لا يحرس شيئاً. (قِيس: بلا الحارس `attempts=4` والمحوّل `0`.)
      var attempts = 0;
      final dio = dioWith(_CountingAdapter(200));
      dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attempts++;
            options.extra[InternetCheckerInterceptor.blockedOfflineKey] = true;
            handler.reject(
              DioException(
                type: DioExceptionType.connectionError,
                requestOptions: options,
              ),
              true,
            );
          },
        ),
      );

      try {
        await dio.get<dynamic>('/x');
      } on DioException {
        // expected
      }

      expect(
        attempts,
        1,
        reason: 'a blocked request is attempted once, never retried',
      );
    },
  );
  test('503 is retried — it is the transient kind', () async {
    expect(await callsFor(_CountingAdapter(503)), 4); // 1 + 3 retries
  });

  test('500 is NOT retried — the same request reproduces the same defect',
      () async {
    expect(
      await callsFor(_CountingAdapter(500)),
      1,
      reason: 'retrying a defect triples load on an already-failing server',
    );
  });

  test('422 is not retried', () async {
    expect(await callsFor(_CountingAdapter(422)), 1);
  });

  test('a short Retry-After is honoured instead of the back-off curve',
      () async {
    final adapter = _CountingAdapter(503, headers: {
      'retry-after': ['1'],
    });
    expect(await callsFor(adapter), 4);
  });

  test('a long Retry-After stops the retries rather than freezing the request',
      () async {
    final adapter = _CountingAdapter(503, headers: {
      'retry-after': ['600'],
    });
    expect(
      await callsFor(adapter),
      1,
      reason: 'holding a request for ten minutes behind a spinner is worse '
          'than surfacing "try again in a few minutes"',
    );
  });
}
