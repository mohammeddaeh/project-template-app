import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

/// نوع عرض مؤشر الخطوات.
enum StepIndicatorType {
  /// نقاط أفقية (الأبسط)
  dots,

  /// أرقام داخل دوائر مع خطوط رابطة
  numbered,

  /// شريط تقدم خطي مع نسبة مئوية
  bar,
}

/// مؤشر تقدم متعدد الأنواع للـ wizard / multi-step forms.
///
/// ```dart
/// // Numbered (الافتراضي)
/// StepProgressIndicator(currentStep: 2, totalSteps: 4)
///
/// // Dots
/// StepProgressIndicator(
///   currentStep: _step,
///   totalSteps: 5,
///   type: StepIndicatorType.dots,
/// )
///
/// // Bar مع labels
/// StepProgressIndicator(
///   currentStep: _step,
///   totalSteps: 3,
///   type: StepIndicatorType.bar,
/// )
///
/// // Numbered مع labels مخصصة
/// StepProgressIndicator(
///   currentStep: _step,
///   totalSteps: 4,
///   stepLabelResolver: (s) => switch (s) {
///     1 => LocaleKeys.personalInfo.tr(),
///     2 => LocaleKeys.contact.tr(),
///     3 => LocaleKeys.documents.tr(),
///     _ => LocaleKeys.review.tr(),
///   },
/// )
/// ```
class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.type = StepIndicatorType.numbered,
    this.activeColor,
    this.inactiveColor,
    this.stepLabelResolver,
  }) : assert(
          currentStep >= 1 && currentStep <= totalSteps,
          'currentStep must be between 1 and totalSteps',
        );

  final int currentStep;
  final int totalSteps;
  final StepIndicatorType type;

  /// لون الخطوة النشطة والمكتملة — الافتراضي: primary
  final Color? activeColor;

  /// لون الخطوات غير النشطة — الافتراضي: borderSubtle
  final Color? inactiveColor;

  /// دالة لتوليد label لكل خطوة (numbered + dots فقط)
  final String? Function(int step)? stepLabelResolver;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = activeColor ?? colors.primary;
    final inactive = inactiveColor ?? colors.borderSubtle;

    return switch (type) {
      StepIndicatorType.bar => _Bar(
          currentStep: currentStep,
          totalSteps: totalSteps,
          activeColor: active,
          inactiveColor: inactive,
        ),
      StepIndicatorType.dots => _Dots(
          currentStep: currentStep,
          totalSteps: totalSteps,
          activeColor: active,
          inactiveColor: inactive,
          stepLabelResolver: stepLabelResolver,
        ),
      StepIndicatorType.numbered => _Numbered(
          currentStep: currentStep,
          totalSteps: totalSteps,
          activeColor: active,
          inactiveColor: inactive,
          stepLabelResolver: stepLabelResolver,
        ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bar
// ─────────────────────────────────────────────────────────────────────────────

class _Bar extends StatelessWidget {
  const _Bar({
    required this.currentStep,
    required this.totalSteps,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int currentStep;
  final int totalSteps;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colors;
    final progress = currentStep / totalSteps;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currentStep / $totalSteps',
              style: textTheme.bodySmall?.copyWith(
                color: activeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (_, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: inactiveColor,
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dots
// ─────────────────────────────────────────────────────────────────────────────

class _Dots extends StatelessWidget {
  const _Dots({
    required this.currentStep,
    required this.totalSteps,
    required this.activeColor,
    required this.inactiveColor,
    this.stepLabelResolver,
  });

  final int currentStep;
  final int totalSteps;
  final Color activeColor;
  final Color inactiveColor;
  final String? Function(int)? stepLabelResolver;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 1; i <= totalSteps; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: i == currentStep ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i <= currentStep ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              if (i < totalSteps) const SizedBox(width: 6),
            ],
          ],
        ),
        if (stepLabelResolver != null) ...[
          const SizedBox(height: 6),
          Text(
            stepLabelResolver!(currentStep) ?? '',
            style: textTheme.labelSmall?.copyWith(color: activeColor),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Numbered
// ─────────────────────────────────────────────────────────────────────────────

class _Numbered extends StatelessWidget {
  const _Numbered({
    required this.currentStep,
    required this.totalSteps,
    required this.activeColor,
    required this.inactiveColor,
    this.stepLabelResolver,
  });

  final int currentStep;
  final int totalSteps;
  final Color activeColor;
  final Color inactiveColor;
  final String? Function(int)? stepLabelResolver;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 1; i <= totalSteps; i++) ...[
          _StepCircle(
            step: i,
            isActive: i == currentStep,
            isCompleted: i < currentStep,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            label: stepLabelResolver?.call(i),
          ),
          if (i < totalSteps)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 1.5,
                color: i < currentStep ? activeColor : inactiveColor,
              ),
            ),
        ],
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.step,
    required this.isActive,
    required this.isCompleted,
    required this.activeColor,
    required this.inactiveColor,
    this.label,
  });

  final int step;
  final bool isActive;
  final bool isCompleted;
  final Color activeColor;
  final Color inactiveColor;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colors;

    final filled = isActive || isCompleted;
    final bg = filled ? activeColor : Colors.transparent;
    final border = filled ? activeColor : inactiveColor;
    final fg = filled ? colors.textOnPrimary : colors.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 1.5),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check_rounded, size: 14, color: fg)
                : Text(
                    '$step',
                    style: textTheme.labelSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: textTheme.labelSmall?.copyWith(
              color: isActive ? activeColor : colors.textMuted,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
