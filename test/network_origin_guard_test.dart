import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/foundation/contracts/network_origin.dart';
import 'package:app_template/core/infra/network/interceptors/network_origin_interceptor.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// **من أين خرج هذا الطلب؟** — الحارس يصرخ على ما لم يُوسَم، ويسكت عن الموسوم.
///
/// وهو يحذّر ولا يمنع بقصد: طلبٌ نُسي وسمُه **خطأ تنفيذٍ لا خطأ تصميم**، ومنعُه
/// يُسقط شاشةً بالإنتاج. فالمقيس هنا هو **سطرُ السجلّ** لا رفضُ الطلب.
class _CapturingDelegate implements LogDelegate {
  final warnings = <String>[];

  @override
  void warning(String message, {String? tag}) => warnings.add('$tag $message');

  @override
  void info(String message, {String? tag}) {}
  @override
  void debug(String message, {String? tag}) {}
  @override
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {}
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

void main() {
  late _CapturingDelegate log;
  late Dio dio;

  setUp(() {
    log = _CapturingDelegate();
    LogService.setDelegate(log);
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _OkAdapter()
      ..interceptors.add(const NetworkOriginInterceptor());
  });

  test('an unmarked request is reported', () async {
    await dio.get<dynamic>('/some/screen/read');

    expect(log.warnings, hasLength(1));
    expect(log.warnings.single, contains('/some/screen/read'));
  });

  test('a request inside a named origin is not reported', () async {
    await NetworkOrigin.run(
      NetworkOrigin.sync,
      () => dio.get<dynamic>('/some/sync/pull'),
    );

    expect(log.warnings, isEmpty);
  });

  test('the mark survives an await inside the origin', () async {
    await NetworkOrigin.run(NetworkOrigin.sync, () async {
      await Future<void>.delayed(Duration.zero);
      await dio.get<dynamic>('/after/await');
    });

    expect(log.warnings, isEmpty);
  });

  test('a request that started outside is not covered by a concurrent origin',
      () async {
    // وهذا سببُ `Zone` بدل عَلَمٍ ساكن. العَلَمُ الساكن يبقى مضبوطاً طوال
    // الدورة، فطلبُ شاشةٍ يقع أثناءها يقرؤه موسوماً **ويمرّ** — والعطلُ الذي
    // وُجد الحارسُ لكشفه يمرّ معه.
    final fromScreen = dio.get<dynamic>('/from/screen');
    await NetworkOrigin.run(
      NetworkOrigin.sync,
      () => dio.get<dynamic>('/from/sync'),
    );
    await fromScreen;

    expect(log.warnings, hasLength(1));
    expect(log.warnings.single, contains('/from/screen'));
  });
}
