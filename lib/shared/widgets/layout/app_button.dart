import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

/// نوع زر موحَّد يحدد اللون والأسلوب البصري.
enum AppButtonVariant {
  /// زر مملوء بلون primary — للإجراءات الرئيسية
  filled,

  /// زر tonal بلون primaryContainer — للإجراءات الثانوية
  tonal,

  /// زر بحدود فقط — للبدائل المحايدة
  outlined,

  /// زر نصي بدون خلفية — للإجراءات الأخف
  text,

  /// زر أحمر — للحذف والإجراءات التدميرية
  danger,
}

/// حجم زر موحَّد يحدد الـ padding والارتفاع.
enum AppButtonSize {
  /// 36 dp — للأزرار داخل البطاقات أو الـ chips
  small,

  /// 44 dp — الحجم الافتراضي
  medium,

  /// 52 dp — للشاشات الرئيسية والـ CTA
  large,
}

/// زر موحَّد يستبدل [ElevatedButton] / [TextButton] / [OutlinedButton] المباشر.
///
/// **للإجراءات الرئيسية (تعبئة كاملة بـ primary):**
/// ```dart
/// AppButton(
///   text: LocaleKeys.save.tr(),
///   onTap: _submit,
/// )
/// ```
///
/// **للإجراءات الثانوية:**
/// ```dart
/// AppButton(
///   text: LocaleKeys.cancel.tr(),
///   variant: AppButtonVariant.outlined,
///   width: double.infinity,
/// )
/// ```
///
/// **زر حذف تدميري:**
/// ```dart
/// AppButton(
///   text: LocaleKeys.delete.tr(),
///   variant: AppButtonVariant.danger,
///   leadingIcon: Icons.delete_outline_rounded,
///   isLoading: state is DeletingState,
///   onTap: _confirmDelete,
/// )
/// ```
///
/// **صغير داخل بطاقة:**
/// ```dart
/// AppButton(
///   text: LocaleKeys.edit.tr(),
///   variant: AppButtonVariant.tonal,
///   size: AppButtonSize.small,
///   onTap: () => context.router.push(EditRoute()),
/// )
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    this.onTap,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isEnabled = true,
    this.leadingIcon,
    this.width,
  });

  final String text;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isEnabled;

  /// أيقونة يسار النص
  final IconData? leadingIcon;

  /// null = shrink حول المحتوى · double.infinity = عرض كامل
  final double? width;

  bool get _interactive => isEnabled && !isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    final (bgColor, fgColor, borderColor) = switch (variant) {
      AppButtonVariant.filled =>
        (colors.primary, colors.textOnPrimary, colors.primary),
      AppButtonVariant.tonal =>
        (colors.secondaryContainer, colors.onSecondaryContainer, Colors.transparent),
      AppButtonVariant.outlined =>
        (Colors.transparent, colors.primary, colors.primary),
      AppButtonVariant.text =>
        (Colors.transparent, colors.primary, Colors.transparent),
      AppButtonVariant.danger =>
        (colors.error, colors.onError, colors.error),
    };

    final vPad = switch (size) {
      AppButtonSize.small  => 8.0,
      AppButtonSize.medium => 12.0,
      AppButtonSize.large  => 16.0,
    };

    final hPad = switch (size) {
      AppButtonSize.small  => 16.0,
      AppButtonSize.medium => 24.0,
      AppButtonSize.large  => 32.0,
    };

    final minHeight = switch (size) {
      AppButtonSize.small  => 36.0,
      AppButtonSize.medium => 44.0,
      AppButtonSize.large  => 52.0,
    };

    final labelStyle = switch (size) {
      AppButtonSize.small  => textTheme.labelMedium,
      AppButtonSize.medium => textTheme.labelLarge,
      AppButtonSize.large  => textTheme.bodyMedium,
    };

    final padding = EdgeInsets.symmetric(horizontal: hPad, vertical: vPad);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    final child = isLoading ? _buildLoader(fgColor) : _buildLabel(labelStyle, fgColor);

    if (variant == AppButtonVariant.outlined) {
      return SizedBox(
        width: width,
        height: minHeight,
        child: OutlinedButton(
          onPressed: _interactive ? onTap : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: fgColor,
            side: BorderSide(
              color: _interactive
                  ? borderColor
                  : borderColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            shape: shape,
            padding: padding,
            minimumSize: Size.zero,
          ),
          child: child,
        ),
      );
    }

    if (variant == AppButtonVariant.text) {
      return SizedBox(
        width: width,
        child: TextButton(
          onPressed: _interactive ? onTap : null,
          style: TextButton.styleFrom(
            foregroundColor: fgColor,
            shape: shape,
            padding: padding,
            minimumSize: Size.zero,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width,
      height: minHeight,
      child: ElevatedButton(
        onPressed: _interactive ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _interactive ? bgColor : bgColor.withValues(alpha: 0.5),
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.5),
          disabledForegroundColor: fgColor.withValues(alpha: 0.6),
          shape: shape,
          padding: padding,
          elevation: 0,
          minimumSize: Size.zero,
        ),
        child: child,
      ),
    );
  }

  Widget _buildLoader(Color color) => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );

  Widget _buildLabel(TextStyle? style, Color color) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 18, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: style?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      );
}
