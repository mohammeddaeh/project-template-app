import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/infra/network/interceptors/network_log_interceptor.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// **لا يغادر سرٌّ هذا الجهاز عبر سطرِ سجلّ.**
///
/// والسجلّاتُ تُلصق بالمحادثات وبتتبُّع الأعطال — فتوكنٌ يُطبع مرّةً يصل إلى
/// حيث لا يُحصى. والعطلُ صامتٌ تماماً: كلُّ شيءٍ يعمل، والسرُّ بالطرفية.
///
/// والمقيسُ هنا **ما يُكتب فعلاً** لا دوالُّ الحجب (وهي خاصّة): لو أُعيد بناءُ
/// الداخل غداً يبقى هذا الاختبار صحيحاً.
class _CapturingLog implements LogDelegate {
  final lines = <String>[];

  String get all => lines.join('\n');

  @override
  void info(String m, {String? tag}) => lines.add(m);
  @override
  void warning(String m, {String? tag}) => lines.add(m);
  @override
  void debug(String m, {String? tag}) => lines.add(m);
  @override
  void error(String m, {String? tag, Object? error, StackTrace? stackTrace}) =>
      lines.add('$m $error');
}

class _OkAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{}',
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

const _token = 'eyJhbGciOiJIUzI1NiJ9.SUPER-SECRET-TOKEN-VALUE.xyz';
const _password = 'P@ssw0rd-do-not-log';

void main() {
  late _CapturingLog log;
  late Dio dio;

  setUp(() {
    log = _CapturingLog();
    LogService.setDelegate(log);
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _OkAdapter()
      // `verbose` هو الحالةُ الأسوأ: يطبع الترويسات والأجسام للنجاح أيضاً.
      ..interceptors.add(NetworkLogInterceptor(verbose: true));
  });

  test('the bearer token never reaches the log', () async {
    await dio.get<dynamic>(
      '/x',
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );

    expect(log.all, isNot(contains(_token)));
    // **وحضورُه يُقال** — «هل كان الطلبُ موثَّقاً؟» أوّلُ سؤالٍ يرفعه 401.
    expect(log.all, contains('present'));
  });

  test('a password in a JSON body is redacted', () async {
    await dio.post<dynamic>(
      '/login',
      data: {'username': 'u', 'password': _password},
    );

    expect(log.all, isNot(contains(_password)));
    expect(log.all, contains('<redacted>'));
  });

  test('a secret nested deeper than the top level is redacted too', () async {
    await dio.post<dynamic>(
      '/x',
      data: {
        'outer': {
          'inner': {'access_token': _token},
        },
      },
    );

    expect(log.all, isNot(contains(_token)));
  });

  test('a secret inside a list of objects is redacted', () async {
    await dio.post<dynamic>(
      '/x',
      data: {
        'items': [
          {'id': 1, 'refresh_token': _token},
        ],
      },
    );

    expect(log.all, isNot(contains(_token)));
  });

  test('a secret in a multipart field is redacted, and files are named only',
      () async {
    await dio.post<dynamic>(
      '/upload',
      data: FormData.fromMap({
        'client_secret': _token,
        'file': MultipartFile.fromBytes([1, 2, 3], filename: 'a.bin'),
      }),
    );

    expect(log.all, isNot(contains(_token)));
  });

  test('the key set covers every credential this template can carry', () {
    // مفتاحٌ يُضاف إلى العقد ولا يُضاف هنا يُطبع خاماً، ولا يشكو شيء.
    for (final key in const [
      'authorization',
      'password',
      'client_secret',
      'access_token',
      'refresh_token',
      'id_token',
    ]) {
      expect(
        NetworkLogInterceptor.sensitiveKeys,
        contains(key),
        reason: '$key would be logged in the clear',
      );
    }
  });

  test('non-secret values are still logged — redaction is not a blackout', () async {
    await dio.post<dynamic>('/x', data: {'title': 'readable-value'});

    expect(log.all, contains('readable-value'));
  });
}
