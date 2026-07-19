import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppNavBar — شريط تطبيق موحَّد (AppBar)
// ─────────────────────────────────────────────────────────────────────────────

/// AppBar قابل للتخصيص يتوافق مع نظام الثيم ويدعم الـ RTL تلقائياً.
///
/// **العنوان:** اختر واحداً من الثلاثة (بالأولوية من الأعلى):
/// - [titleWidget] — widget مخصص (الأعلى أولوية)
/// - [titleKey]   — مفتاح ترجمة (يُستدعى عبر `.tr()`)
/// - [titleText]  — نص جاهز مُترجَم
///
/// **زر الرجوع:**
/// - `null` (الافتراضي): يظهر تلقائياً إن كان `Navigator.canPop(context)` = true
/// - `false`: لا يظهر أبداً (مناسب للشاشات الجذرية)
/// - `true`: يظهر دائماً
///
/// ```dart
/// // شاشة عادية — زر رجوع تلقائي
/// appBar: AppNavBar(titleKey: LocaleKeys.profile)
///
/// // شاشة جذرية — بدون زر رجوع
/// appBar: AppNavBar.root(
///   titleKey: LocaleKeys.home,
///   actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})],
/// )
///
/// // عنوان مخصص
/// appBar: AppNavBar(
///   titleWidget: Row(children: [
///     const Icon(Icons.store_outlined, size: 18),
///     const SizedBox(width: 6),
///     Text(LocaleKeys.store.tr()),
///   ]),
/// )
/// ```
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({
    super.key,
    this.titleKey,
    this.titleText,
    this.titleWidget,
    this.leading,
    this.showBackButton,
    this.onBack,
    this.actions,
    this.backgroundColor,
    this.bottom,
    this.elevation = 0,
    this.scrolledUnderElevation = 0,
    this.centerTitle = true,
  });

  /// Named ctor للشاشات الجذرية — لا يظهر زر الرجوع.
  const AppNavBar.root({
    super.key,
    this.titleKey,
    this.titleText,
    this.titleWidget,
    this.actions,
    this.backgroundColor,
    this.bottom,
  })  : showBackButton = false,
        leading = null,
        onBack = null,
        elevation = 0,
        scrolledUnderElevation = 0,
        centerTitle = true;

  /// مفتاح ترجمة العنوان (يُستدعى عبر `.tr()`)
  final String? titleKey;

  /// نص العنوان الجاهز (إن كنت تمرر نص مُترجَم مسبقاً)
  final String? titleText;

  /// widget مخصص للعنوان (الأولوية الأعلى)
  final Widget? titleWidget;

  /// widget مخصص لأيقونة الرجوع
  final Widget? leading;

  /// تحكم في زر الرجوع: null=تلقائي، false=مخفي، true=مُجبَر
  final bool? showBackButton;

  /// callback مخصص لزر الرجوع — الافتراضي: `Navigator.maybePop`
  final VoidCallback? onBack;

  /// أزرار العمليات (يمين AppBar)
  final List<Widget>? actions;

  /// لون الخلفية — الافتراضي: `scheme.surface`
  final Color? backgroundColor;

  /// widget أسفل العنوان (e.g. TabBar) — يُضاف ارتفاعه لـ [preferredSize]
  final PreferredSizeWidget? bottom;

  final double elevation;
  final double scrolledUnderElevation;
  final bool centerTitle;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    final canGoBack = showBackButton ?? Navigator.canPop(context);

    final resolvedLeading = leading ??
        (canGoBack
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: scheme.onSurface,
                  size: 20,
                ),
                onPressed: onBack ?? () => Navigator.maybePop(context),
              )
            : null);

    Widget? resolvedTitle;
    if (titleWidget != null) {
      resolvedTitle = titleWidget;
    } else if (titleKey != null) {
      resolvedTitle = Text(
        titleKey!.tr(),
        style: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      );
    } else if (titleText != null) {
      resolvedTitle = Text(
        titleText!,
        style: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      );
    }

    return AppBar(
      leading: resolvedLeading,
      automaticallyImplyLeading: false,
      title: resolvedTitle,
      centerTitle: centerTitle,
      actions: actions,
      backgroundColor: backgroundColor ?? scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      shadowColor: Colors.transparent,
      bottom: bottom,
    );
  }
}
