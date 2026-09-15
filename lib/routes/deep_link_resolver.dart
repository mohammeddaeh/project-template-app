import 'package:auto_route/auto_route.dart';

/// يقرّر ما تفعله كل رسالة deep-link تصل من النظام — إقلاعٌ عاديّ، رابطٌ حقيقيّ
/// عند الإقلاع، أو رابطٌ يصل والتطبيق يعمل أصلاً.
///
/// **مُستخرَجةٌ دالّةً نقيّة عن `app.dart` عمداً** — القرار يعتمد على شرطٍ واحد
/// (`initial && path فارغ/جذر`)، وعزلُه هنا يجعله قابلاً للاختبار المباشر بلا
/// تركيب `App` كاملةً بكل تبعيّاتها.
///
/// راجع `readme/23_STARTUP_SPLASH.md` و`readme/41_ROADMAP.md` بند #09.
///
/// ## الفرق عن السلوك السابق
///
/// كان `deepLinkBuilder` يتجاهل [PlatformDeepLink] كلّياً ويُعيد [startRoute]
/// **دائماً** — إقلاعٌ عاديّ أو رابطٌ حقيقيّ، سيّان. فرابطُ تفعيلٍ أو دعوةٍ
/// وصل والتطبيقُ مغلقاً كان يُفتَح على شاشة الدخول/القشرة العادية، لا وجهته.
/// **ورابطٌ يصل والتطبيقُ يعمل لم يكن يُختبَر أصلاً** — لا مسار تشغيليّ كان
/// يمرّ به قبل الآن.
DeepLink resolveDeepLink({
  required bool initial,
  required String path,
  required PageRouteInfo startRoute,
}) {
  // إقلاعٌ عاديّ (أيقونة التطبيق) — لا رابط حقيقيّ وصل، فالوجهة قرارُ
  // `StartupResolver` وحده.
  final isPlainLaunch = initial && (path.isEmpty || path == '/');
  if (isPlainLaunch) return DeepLink.single(startRoute);

  // رابطٌ حقيقيّ — عند الإقلاع أو والتطبيقُ يعمل، سيّان: يُحلّ عبر شجرة
  // المسارات المسجَّلة بـ`router.dart` (بما فيها حرّاسها، كـ`PermissionRouteGuard`).
  return DeepLink.path(path);
}
