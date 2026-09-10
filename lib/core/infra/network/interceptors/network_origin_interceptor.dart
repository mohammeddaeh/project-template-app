import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_template/core/foundation/contracts/network_origin.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// **يصرخ حين يخرج طلبٌ من خارج المنافذ المسمّاة** — بـ`debug` وحده.
///
/// ## القاعدة
///
/// ```
/// دورةُ المزامنة  ·  الدخول  ·  الجردُ الأوّل  ·  مرفقٌ يطلبه المستخدم
/// ──────────────────────────────────────────────────────────────────
///                      ولا شيءَ غيرها
/// ```
///
/// وفتحُ شاشةٍ ليس منها. راجع [NetworkOrigin] لسبب القاعدة وللآلية.
///
/// ## ولماذا يُحذّر ولا يمنع
///
/// المنعُ يجعل الفاحصَ ميزةً: طلبٌ نُسي وسمُه — وهو **خطأ تنفيذٍ لا خطأ
/// تصميم** — يُسقط شاشةً بالإنتاج. والغرض كشفُ الانحراف لمن يكتب، لا معاقبةُ
/// من يستعمل.
///
/// و`kDebugMode` يجعله بلا أثرٍ إطلاقاً بنسخة الإصدار: لا فرعَ ولا سطرَ سجلّ.
///
/// ## وأينَ يُقرأ أثرُه
///
/// بسطرٍ أصفر بالطرفية لحظةَ وقوعه، بمسار الطلب:
///
/// ```
/// [NET-ORIGIN] ⚠ GET /records خرج من خارج دورة المزامنة.
/// ```
class NetworkOriginInterceptor extends Interceptor {
  const NetworkOriginInterceptor();

  static const _tag = 'NET-ORIGIN';

  /// مساراتٌ تُستثنى بحكم أنها **هي** المنفذ: تُنادى من طبقاتٍ لا تملك أن
  /// تلفّ نفسها بمنطقة (معترِضُ تجديد التوكن يُعيد المحاولة من داخل Dio).
  static const _exempt = <String>['/auth/refresh', '/auth/login'];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode &&
        NetworkOrigin.current == null &&
        !_exempt.any(options.path.contains)) {
      LogService.warning(
        '${options.method} ${options.path} خرج من خارج المنافذ المسمّاة — '
        'المتوقَّع أن تقرأ الشاشات من الجهاز، وأن يمرّ كلُّ طلبٍ بدورة المزامنة. '
        'راجع NetworkOrigin.',
        tag: _tag,
      );
    }
    handler.next(options);
  }
}
