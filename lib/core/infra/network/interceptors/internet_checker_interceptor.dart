import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:app_template/core/platform/connectivity/server_reachability.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// يرفض الطلب قبل أن يغادر حين لا سبيل لأن يصل.
///
/// ## سؤالان بترتيبٍ مقصود
///
/// 1. **هل بالجهاز واجهةُ شبكة؟** — `Connectivity`، جوابٌ فوريّ من النظام بلا
///    أي رحلة. وضعُ الطيران يُحسم هنا بلا تكلفة.
/// 2. **هل يجيب مضيفُ الخادم؟** — [ServerReachability]، ولا تُسأل إلا إن كانت
///    الأولى `true`. «واي‑فاي متصل» ليست «يصل»: بوّابةٌ مقيَّدة بمقهى تُجيب
///    الأولى وتبتلع الثانية.
///
/// ## وما تغيّر بالثانية (2026-08-26)
///
/// كانت `InternetConnectionChecker.hasConnection` تُنادى هنا مباشرةً — **بكل
/// طلب**، وبإعدادها الافتراضي الذي يفحص ثلاثة APIs تجريبية عامّة لا علاقة لها
/// بخادم هذا التطبيق. جدولُ ما يخرج من ذلك بـ[ServerReachability]، وأخطرُه:
/// شبكةٌ تحجب تلك النطاقات تجعل التطبيق أوف‑لاين للأبد بينما الخادم متاح.
///
/// و«بكل طلب» كانت نصفَ المشكلة: دورةُ مزامنةٍ واحدة تُرسل عشرات الطلبات، فتدفع
/// عشرات الفحوص — وبمضيفٍ لا يجيب، عشراتِ المهلات المتتالية.
///
/// ## وما تغيّر بالرفض نفسه (2026-08-30)
///
/// صار المنعُ **يُرى**: سطرٌ بالطرفية لحظةَ وقوعه، والخطأ يمرّ على معترضات
/// الخطأ بعده. راجع [_block] — كان يحجب بصمتٍ تامّ.
@lazySingleton
class InternetCheckerInterceptor extends Interceptor {
  InternetCheckerInterceptor(this._reachability, this._connectivity);

  final ServerReachability _reachability;
  final Connectivity _connectivity;

  static const _tag = 'NET-GUARD';

  /// وسمٌ يوضع بـ`extra` حين يُمنع الطلبُ لأن **الجهاز بلا واجهة شبكة** —
  /// يقرأه [RetryInterceptor] فلا يعيد الكرّة.
  ///
  /// كان الرفض يصل إليه بهيئة `connectionError` لا يميّزها عن انقطاعٍ عابر
  /// وسطَ رحلة، فيُعاد الطلبُ ثلاثاً بتراجعٍ ١+٢+٤ ثانية — **وثلاثتُها تُمنع
  /// من هنا قبل أن تغادر**. سبعُ ثوانٍ ومحاولاتٌ بالسجلّ ثمناً لجوابٍ معلومٍ
  /// سلفاً: لا مقبس. ووضعُ الطيران لا يزول بأربع ثوانٍ من الانتظار.
  static const blockedOfflineKey = '_netGuardBlockedOffline';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      options.extra[blockedOfflineKey] = true;
      return _block(
        handler,
        options,
        'الجهاز بلا واجهة شبكة (Connectivity = none)',
      );
    }

    if (!await _reachability.isReachable()) {
      return _block(
        handler,
        options,
        'مضيفُ الخادم لا يجيب فحصَ ServerReachability — والفحص يضرب مضيفَ '
        'BASE_URL وحده. راجع injection_module.dart.',
      );
    }

    if (!handler.isCompleted) handler.next(options);
  }

  /// **رفضٌ يُرى** — بسطرِ سجلٍّ هنا، وبتمريرِ الخطأ إلى معترضات الخطأ بعده.
  ///
  /// ## العطل الذي وُلد منه (2026-08-30)
  ///
  /// `RequestInterceptorHandler.reject(err)` وسيطُها الثاني
  /// `callFollowingErrorInterceptor` **افتراضُه `false`** — أي أن الخطأ يعود
  /// إلى المستدعي دون أن يمرّ بـ`onError` لأي معترضٍ بعده. و
  /// `NetworkLogInterceptor` مسجَّلٌ **بعد** هذا بثلاثة مواضع، و`onRequest`
  /// الخاصّ به لم يُنادَ أصلاً لأن الرفض سبقه.
  ///
  /// فكانت المحصّلة: **طلبٌ يُمنع بصمتٍ تامّ** — لا سطرَ بالطرفية، ولا طلبَ
  /// بـDevTools، وشاشةُ الدخول تقول «Login failed» بالإنجليزية. وهو أسوأ ما
  /// يفعله حارس: أن يحجب ولا يقول ما حجب ولا لماذا.
  void _block(
    RequestInterceptorHandler handler,
    RequestOptions options,
    String why,
  ) {
    LogService.warning(
      '⛔ ${options.method} ${options.uri} مُنع قبل أن يغادر الجهاز — $why',
      tag: _tag,
    );
    // `true` — مرِّر الخطأ على معترضات الخطأ بعده ليراه مسجّلُ الشبكة.
    handler.reject(_noInternetException(options), true);
  }

  DioException _noInternetException(RequestOptions options) {
    return DioException(
      type: DioExceptionType.connectionError,
      requestOptions: options,
      error: const SocketException('No internet connection'),
      message: 'No internet connection',
    );
  }
}
