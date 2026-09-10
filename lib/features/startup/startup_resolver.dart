import 'package:app_template/core/infra/session/data_origin_guard.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/features/auth/shared/current_user_repository.dart';
import 'package:app_template/features/startup/startup_destination.dart';
import 'package:app_template/modules/modules_bootstrap.dart';

/// **يقرّر أوّلَ شاشةٍ يراها المستخدم — قبل أن يُرسم أول إطار.**
///
/// يُنادى من `main()` مرّةً واحدة، ويُمرَّر ما يُعيده إلى `App`.
///
/// ## ولماذا ليس cubit ولا شاشة
///
/// كان المنطقُ نفسُه `SplashCubit` خلف `SplashScreen`: مسارٌ أوّليّ يعرض الشعار
/// ويقرّر ثم يستبدل نفسَه. فينتج **شعاران متتاليان** — راجع [StartupDestination].
/// والقرارُ لم يتغيّر حرفاً؛ ما تغيّر أنه لم يعد يحتاج شاشةً ليقع خلفها، فسقط
/// معه `SplashState` و`freezed` و`BlocListener` والمسارُ نفسُه.
///
/// **ولا يرمي.** كلُّ فرعٍ ينتهي بوجهة: لقطةٌ تالفة، أو موديولٌ أخفق إقلاعُه —
/// كلُّها تُقرأ «ادخل من الدخول» لا «قف». ودالّةٌ ترمي هنا تعني تطبيقاً لا يرسم
/// إطاراً أبداً.
class StartupResolver {
  const StartupResolver(
    this._sessionRepository,
    this._currentUserRepository,
    this._originGuard,
  );

  final SessionRepository _sessionRepository;
  final CurrentUserRepository _currentUserRepository;
  final DataOriginGuard _originGuard;

  Future<StartupDestination> resolve() async {
    // **ما كان `main()` ينتظره قبل `runApp` ثم نُقل، عاد إلى هنا.**
    //
    // النقلُ كان لأجل شاشة السبلاش: تُرسم أوّلاً ثم يجري العمل خلفها. ولا شاشةَ
    // الآن — و`splash` النظام يحمل الشعار طوال هذا. فانتظارُه هنا يعني إطاراً
    // أوّلَ **صحيحاً**، لا إطاراً مؤقّتاً يُستبدل.
    //
    // **وقبل فرع `debugSkipLogin`**: ذلك الفرع يدخل الغلاف مباشرةً، والغلافُ قد
    // يحلّ مستودعاتٍ لا تُبدَّل إلا بذيل التهيئة — ودخولٌ يسبقها يعني شاشاتٍ
    // تقرأ من المستودع غير المُغلَّف بصمت.
    await ModulesBootstrap.ready;

    if (AppFeatures.debugSkipLogin) return StartupDestination.shell;

    // **أوّلُ سؤال: هل بيانات هذا الجهاز من هذا الخادم؟**
    //
    // قبل `loadCachedToken` بقصد: أيُّ ترتيبٍ آخر يعني أننا قرأنا توكناً من
    // مصدرٍ آخر ومضينا عليه قبل أن يُسأل عن أصله. راجع [DataOriginGuard].
    //
    // ولا فرعَ لجوابه هنا: إن مُسح الجهاز فالجلسة مُسحت معه، والسطر التالي يقرأ
    // توكناً غائباً فيمضي إلى شاشة الدخول من نفسه.
    await _originGuard.ensureCurrentOrigin();

    final token = await _sessionRepository.loadCachedToken();
    if (token == null || token.isEmpty) return StartupDestination.login;

    // تُستعاد **قبل** أول إطار لا بعده.
    //
    // `CurrentUserRepository` بالذاكرة، فإقلاعٌ بتوكنٍ صالح يبدأ بلا مستخدم —
    // وكلُّ ما يقرأ `currentUser` يرسم حالتَه الفارغة ما دامت الشبكة تعمل.
    //
    // ولا ترمي أبداً — لقطةٌ تالفة تُقرأ «لا شيء مخزَّن» — فتُبلّغ بالطريقة
    // الوحيدة الممكنة: تترك `currentUser` فارغاً، وهو ما يقرؤه الفرع أدناه.
    await _currentUserRepository.restoreFromCache();

    // **توكنٌ بلا هوية ليس جلسة — فتُنهى هنا، لا تُحمل إلى الشاشة التالية.**
    //
    // `restoreFromCache` تُرجع بصمت بثلاث حالات: لا لقطة، لقطةٌ تالفة، ولقطةٌ
    // بشكلٍ قديم لا يُقرأ (وقع فعلاً يوم تبدّل حقلُ الهوية). وبثلاثتها يبقى
    // التوكن صالحاً و`currentUser == null`.
    //
    // والثمنُ لو مضى: مستخدمٌ يعمل جولةً كاملة وكلُّ ما يُنشئه بلا صاحب —
    // إسنادٌ يضيع بصمت.
    //
    // **ومسحُ التوكن جزءٌ من القرار لا زينة**: تركُه يعني جهازاً يحمل اعتماداً
    // لا يعرف صاحبَه، وشاشةَ دخولٍ تُكتب فوقه لحظةَ نجاحها على أي حال.
    if (_currentUserRepository.currentUser == null) {
      _sessionRepository.clearSession();
      _currentUserRepository.clear();
      return StartupDestination.login;
    }

    return StartupDestination.shell;
  }
}
