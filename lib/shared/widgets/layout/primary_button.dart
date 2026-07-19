import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// Primary call-to-action button.
///
/// - [isEnabled] = `false` OR [isLoading] = `true` → non-interactive (greyed).
/// - [isTextOnly] = `true` → flat text button (no filled background).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.isEnabled = true,
    this.isTextOnly = false,
    this.vector,
    this.width,
    this.padding,
    this.borderRadius,
    this.colorButton,
    this.colorText,
    this.titleStyle,
    super.key,
  });

  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isEnabled;
  final bool isTextOnly;
  final String? vector;
  final double? width;
  final EdgeInsets? padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? colorButton;
  final Color? colorText;
  final TextStyle? titleStyle;

  bool get _interactive => isEnabled && !isLoading;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = WidgetStatePropertyAll(
      isLoading
          ? const EdgeInsets.symmetric(vertical: 10)
          : padding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    );
    final shape = WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(32),
      ),
    );

    final child = isLoading
        ? _loader(context)
        : _LabelRow(
            text: text,
            vector: vector,
            style:
                titleStyle ??
                context.textTheme.bodyMedium?.copyWith(
                  color: isTextOnly
                      ? (colorButton ?? context.colors.primary)
                      : (colorText ?? context.colors.textOnPrimary),
                  fontWeight: FontWeight.w600,
                ),
          );

    if (isTextOnly) {
      return TextButton(
        onPressed: _interactive ? onTap : null,
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(
            colorButton ?? context.colors.primary,
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: shape,
          padding: resolvedPadding,
          elevation: const WidgetStatePropertyAll(0),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: _interactive ? onTap : null,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          final base = colorButton ?? context.colors.primary;
          return states.contains(WidgetState.disabled)
              ? base.withValues(alpha: 0.4)
              : base;
        }),
        shape: shape,
        padding: resolvedPadding,
        elevation: const WidgetStatePropertyAll(0),
        minimumSize: WidgetStatePropertyAll(Size(width ?? 150, 50)),
      ),
      child: child,
    );
  }

  Widget _loader(BuildContext context) => isTextOnly
      ? Transform.scale(
          scale: 0.8,
          child: CircularProgressIndicator(
            color: colorButton ?? context.colors.primary,
          ),
        )
      : Transform.scale(
          scale: 0.7,
          child: LoadingAnimationWidget.waveDots(
            color: context.colors.textMuted,
            size: 32,
          ),
        );
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.text, required this.style, this.vector});

  final String text;
  final TextStyle? style;
  final String? vector;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (vector != null) ...[
          SvgPicture.asset(vector!),
          const SizedBox(width: 8),
        ],
        Text(text, style: style),
      ],
    );
  }
}
