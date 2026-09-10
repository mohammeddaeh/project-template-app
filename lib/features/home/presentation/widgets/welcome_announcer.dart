import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/infra/session/welcome_greeting.dart';
import 'package:app_template/features/auth/shared/current_user_repository.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';

/// **يستقبل الداخلَ حديثاً** — تحيّةٌ باسمه، وسطرٌ يقول ما صار ممكناً.
///
/// ## ولماذا رايةٌ لا نداءٌ مباشر
///
/// الترحيبُ يخصّ **لحظةً** لا شاشة: أوّلَ دخولٍ اكتمل تجهيزُه. ومن يعرف تلك
/// اللحظة (كيوبتُ الدخول، أو جردٌ أوّلٌ انتهى) **ينتهي قبل أن تُبنى الشجرة**،
/// فلا `BuildContext` بيده ولا شيء يعرضه.
///
/// فالرايةُ تفصل الطرفين: من عرف اللحظة يرفعها، وهذا يقرؤها **بعد أوّل إطار**
/// (`context.feedback` يحتاج شجرةً مركَّبة)، و[WelcomeGreeting.take] تمحوها —
/// فتُقرأ مرّةً واحدة لا مرّةً بكل بناء.
///
/// ⛔ **ولا رافعَ لها بالقالب.** `WelcomeGreeting.raise()` يُنادى من الشريحة
/// التي تملك «متى صار الحسابُ جاهزاً» — بعد الدخول، أو بذيل أوّل جردٍ إن كانت
/// المزامنةُ مُشعَلة. وحتى يُنادى، هذا المعلِنُ مركَّبٌ وصامت.
///
/// 📝 **ونصُّ [LocaleKeys.welcomeReady] يخصّ مشروعك** — «حسابك جاهز على هذا
/// الجهاز» جوابٌ عامّ؛ ومن أشعل المزامنة يبدّله بما يقوله جهازٌ صار يعمل بلا
/// إنترنت. الجملةُ تصف ما تغيّر فعلاً، لا ترحيباً مجرّداً.
class WelcomeAnnouncer extends StatefulWidget {
  const WelcomeAnnouncer({required this.child, super.key});

  final Widget child;

  @override
  State<WelcomeAnnouncer> createState() => _WelcomeAnnouncerState();
}

class _WelcomeAnnouncerState extends State<WelcomeAnnouncer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _greet());
  }

  void _greet() {
    if (!mounted) return;
    if (!getIt<WelcomeGreeting>().take()) return;

    // **الاسمُ إن وُجد، وتحيّةٌ عامّة إن لم يوجد** — و`displayName` تعود
    // فارغةً لمستخدمٍ بلا اسمٍ ولا كنية، فتصير التحيّة «أهلاً ،» بفاصلةٍ
    // معلّقة على لا أحد.
    final name = getIt<CurrentUserRepository>().currentUser?.displayName ?? '';
    context.feedback.success(
      LocaleKeys.welcomeReady.tr(),
      title: name.isEmpty
          ? LocaleKeys.welcomeGreetingAnon.tr()
          : LocaleKeys.welcomeGreeting.tr(args: [name]),
      // خمسٌ لا ثلاث: جملتان تُقرآن، وإحداهما تقول قاعدةَ عملٍ جديدة.
      duration: const Duration(seconds: 5),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
