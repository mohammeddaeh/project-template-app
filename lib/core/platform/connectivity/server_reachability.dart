import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:app_template/core/platform/logging/log_service.dart';

/// **هل يجيب خادمُ هذا التطبيق؟** — لا «هل الإنترنت يعمل؟».
///
/// ## ما كان يُسأل فعلاً
///
/// `InternetConnectionChecker.instance` بإعداده الافتراضي (v3.0.1) يُرسل `HEAD`
/// إلى **ثلاثة APIs تجريبية عامّة**:
///
/// ```
/// https://dummyapi.online/api/movies/1
/// https://jsonplaceholder.typicode.com/albums/1
/// https://fakestoreapi.com/products/1
/// ```
///
/// وأيُّ ردٍّ بين ١٠٠ و٥٩٩ يُقرأ «الإنترنت يعمل». وذلك كان يُسأل **قبل كل طلب**
/// و**قبل كل دورة مزامنة**. وأربعةُ أعطالٍ تخرج منه:
///
/// | العطل | الأثر |
/// |---|---|
/// | شبكةٌ حكومية أو داخلية تحجب هذه النطاقات | **التطبيق أوف‑لاين للأبد** بينما الخادم متاح — ولا مزامنة تحدث إطلاقاً |
/// | تلك الخدمات تسقط أو تُحدِّد المعدّل | التطبيق يسقط معها |
/// | الإنترنت يعمل والخادمُ ساقط | البوّابة تسمح، والدورة تحرق ميزانية التراجع على ٥٠٠ات |
/// | خصوصية | تطبيقٌ ميدانيّ لوزارة يُنادي `fakestoreapi.com` مع كل طلب |
///
/// والسؤال الصحيح ليس «هل الإنترنت يعمل» بل **«هل يمكن أن يصل طلبي؟»** —
/// وجوابُه عند مضيف الـAPI وحده. وأيُّ حالةٍ يردّها كافية: `HEAD` على جذر
/// الـAPI قد يعود ٤٠٤، وذلك **إثباتٌ تامّ** أن المضيف تُكلَّم معه.
///
/// ## والنتيجة تُخزَّن لثانيتين — وذلك نصفُ الغرض
///
/// دورةُ مزامنةٍ واحدة تُرسل عشرات الطلبات: ثلاثون صفّاً بالطابور، وحتى خمسين
/// صفحة سحب. وفحصٌ لكل واحدٍ منها يعني عشرات الرحلات الزائدة — وبمضيفٍ لا يجيب،
/// **عشرات المهلات المتتالية** قبل أن تُخفق الدورة.
class ServerReachability {
  ServerReachability(this._checker, this._connectivity) {
    // **عودةُ الاتصال تُبطل المخزَّن فوراً.** بدونها يبقى «لا يصل» صادقاً
    // لثانيتين بعد أن يعود الهوائي — وهما بالضبط الثانيتان اللتان يضغط فيهما
    // الموظّف «مزامنة الآن» لأنه رأى الإشارة تعود.
    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      invalidate();
    });
  }

  final InternetConnectionChecker _checker;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// مهلةُ صلاحية الجواب المخزَّن.
  ///
  /// ثانيتان: أطولُ من دفعةِ طلباتٍ متتالية، وأقصرُ من أن يلاحظ إنسان. وجوابٌ
  /// عمرُه ثانيتان أسوأ ما يفعله أن يُمرّر طلباً سيفشل بخطأ شبكةٍ عاديّ —
  /// وذلك ما كان سيحدث بلا فحصٍ أصلاً.
  static const _ttl = Duration(seconds: 2);

  bool? _cached;
  DateTime? _cachedAt;

  static const _tag = 'REACHABILITY';

  /// `true` حين يُتوقَّع أن يصل الطلب.
  ///
  /// **ولا يفحص وجود الواجهة** — ذلك سؤالٌ أرخص يسبقه بالمستدعي
  /// (`ConnectivityService.isOnline`). فحصُه هنا ثانيةً تكرارٌ، وتركُه للمستدعي
  /// يُبقي هذا الصنف على سؤالٍ واحد.
  Future<bool> isReachable() async {
    final cachedAt = _cachedAt;
    final cached = _cached;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _ttl) {
      return cached;
    }

    bool result;
    try {
      result = await _checker.hasConnection;
    } catch (e) {
      // **يُقرأ «يصل».** فاحصٌ انهار ليس إثباتاً على أن الخادم ساقط، وردُّ
      // `false` هنا يمنع كل طلبٍ بالتطبيق لعطلٍ بأداة القياس وحدها. ودعُ الطلبَ
      // يمضي: إن كان الخادم ساقطاً فعلاً فسيقول ذلك بنفسه، بخطأٍ يعرف المستدعي
      // كيف يُصنّفه.
      LogService.warning(
        'The reachability probe threw — treating the server as reachable and '
        'letting the request answer for itself: $e',
        tag: _tag,
      );
      result = true;
    }

    _cached = result;
    _cachedAt = DateTime.now();
    return result;
  }

  /// يُسقط الجواب المخزَّن — يُنادى تلقائياً عند كل تغيّر بالاتصال.
  void invalidate() {
    _cached = null;
    _cachedAt = null;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
