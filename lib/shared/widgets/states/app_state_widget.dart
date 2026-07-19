import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:lottie/lottie.dart';

/// نوع حالة الشاشة — كل نوع له أيقونة ولون ونمط نص افتراضية.
/// جميع القيم الافتراضية قابلة للتجاوز عبر معاملات [AppStateWidget].
enum AppStateType {
  /// قائمة فارغة أو محتوى غير موجود
  empty,

  /// خطأ عام (API أو محلي)
  error,

  /// جاري التحميل
  loading,

  /// لا يوجد اتصال بالإنترنت
  noInternet,

  /// الخادم تحت الصيانة
  maintenance,

  /// عملية ناجحة
  success,

  /// تحذير يحتاج انتباهاً
  warning,

  /// معلومة توجيهية
  info,
}

/// ويدجت موحَّد لجميع حالات الشاشة.
///
/// يحل محل: [EmptyStateWidget]، [ErrorStateWidget]، [LoadingWidget]،
/// [NoInternetWidget]، [MaintenanceWidget]، [SuccessStateWidget]،
/// [WarningStateWidget]، [InfoStateWidget].
///
/// ```dart
/// // بسيط — يستخدم الافتراضيات
/// AppStateWidget(type: AppStateType.error, titleKey: 'somethingWentWrong')
///
/// // متخصص — override كامل
/// AppStateWidget(
///   type: AppStateType.empty,
///   icon: Icons.search_off,
///   iconSize: 80,
///   titleKey: 'noResults',
///   descriptionKey: 'tryDifferentKeyword',
///   actionLabelKey: 'clearFilter',
///   onAction: () => cubit.clearFilter(),
/// )
/// ```
class AppStateWidget extends StatelessWidget {
  const AppStateWidget({
    super.key,
    required this.type,
    this.titleKey,
    this.descriptionKey,
    this.actionLabelKey,
    this.onAction,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.padding,
    this.lottieAsset,
    this.lottieSize,
  });

  /// نوع الحالة — يحدد الأيقونة واللون ونمط النص الافتراضية
  final AppStateType type;

  /// مفتاح الترجمة للنص الرئيسي.
  /// إن كان null يُستخدم النص الافتراضي للنوع (إن وُجد)
  final String? titleKey;

  /// مفتاح الترجمة للنص الثانوي الاختياري
  final String? descriptionKey;

  /// مفتاح الترجمة لزر الإجراء — إن كان null لا يظهر الزر
  final String? actionLabelKey;

  /// إجراء الزر — يُعرض الزر فقط إن كان [actionLabelKey] غير null
  final VoidCallback? onAction;

  /// override للأيقونة الافتراضية للنوع
  final IconData? icon;

  /// override لحجم الأيقونة (الافتراضي حسب النوع: 56 أو 64)
  final double? iconSize;

  /// override للون الأيقونة الافتراضي
  final Color? iconColor;

  /// override للـ padding الخارجي (الافتراضي: EdgeInsets.all(24))
  final EdgeInsets? padding;

  /// مسار ملف Lottie (من [Assets.lottie.*]) — عند توفيره يحل محل الأيقونة.
  /// Fallback: إن لم يُوجد الملف أو كان null يظهر [icon] الافتراضية.
  /// مثال: `lottieAsset: Assets.lottie.empty`
  final String? lottieAsset;

  /// عرض/ارتفاع Animation الـ Lottie بالـ logical pixels (الافتراضي: 160)
  final double? lottieSize;

  @override
  Widget build(BuildContext context) {
    if (type == AppStateType.loading) {
      if (lottieAsset != null) {
        return Center(
          child: Lottie.asset(
            lottieAsset!,
            width: lottieSize ?? 160,
            height: lottieSize ?? 160,
            repeat: true,
          ),
        );
      }
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    final resolvedIcon = icon ?? _defaultIcon;
    final resolvedIconSize = iconSize ?? _defaultIconSize;
    final resolvedIconColor = iconColor ?? _defaultIconColor(scheme);
    final resolvedTitleKey = titleKey ?? _defaultTitleKey;
    final resolvedTitleStyle = _defaultTitleStyle(textTheme);

    final Widget visual = lottieAsset != null
        ? Lottie.asset(
            lottieAsset!,
            width: lottieSize ?? 160,
            height: lottieSize ?? 160,
            repeat: type != AppStateType.success,
          )
        : Icon(resolvedIcon, size: resolvedIconSize, color: resolvedIconColor);

    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            visual,
            const SizedBox(height: 16),
            if (resolvedTitleKey != null)
              Text(
                resolvedTitleKey.tr(),
                style: resolvedTitleStyle?.copyWith(color: scheme.onSurface),
                textAlign: TextAlign.center,
              ),
            if (descriptionKey != null) ...[
              Text(
                descriptionKey!.tr(),
                style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabelKey != null) ...[
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabelKey!.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  IconData get _defaultIcon => switch (type) {
    AppStateType.empty => Icons.inbox_outlined,
    AppStateType.error => Icons.error_outline,
    AppStateType.noInternet => Icons.wifi_off_rounded,
    AppStateType.maintenance => Icons.construction_outlined,
    AppStateType.success => Icons.check_circle_outline,
    AppStateType.warning => Icons.warning_amber_rounded,
    AppStateType.info => Icons.info_outline_rounded,
    AppStateType.loading => Icons.circle, // لن يُستخدم — loading يُعالَج أعلاه
  };

  double get _defaultIconSize => switch (type) {
    AppStateType.empty || AppStateType.maintenance => 64,
    _ => 56,
  };

  Color _defaultIconColor(ColorScheme scheme) => switch (type) {
    AppStateType.empty || AppStateType.noInternet => scheme.outline,
    AppStateType.error => scheme.error,
    AppStateType.warning => scheme.tertiary,
    _ => scheme.primary,
  };

  String? get _defaultTitleKey => switch (type) {
    AppStateType.noInternet => 'noInternet',
    AppStateType.maintenance => 'maintenance',
    _ => null,
  };

  TextStyle? _defaultTitleStyle(TextTheme t) => switch (type) {
    AppStateType.empty => t.titleMedium,
    AppStateType.maintenance => t.titleLarge,
    _ => t.bodyLarge,
  };
}
