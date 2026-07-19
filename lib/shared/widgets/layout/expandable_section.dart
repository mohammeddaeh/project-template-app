import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

/// قسم قابل للطي والفتح مع رأس ومحتوى.
///
/// **Uncontrolled (الافتراضي):** الـ widget يدير حالته داخلياً.
/// **Controlled:** مرر [isExpanded] + [onToggle] لتحكم خارجي.
///
/// ```dart
/// ExpandableSection(
///   titleKey: LocaleKeys.details,
///   child: Text(order.description),
/// )
///
/// // Controlled
/// ExpandableSection(
///   titleKey: LocaleKeys.faq,
///   isExpanded: _isOpen,
///   onToggle: () => setState(() => _isOpen = !_isOpen),
///   child: const FaqContent(),
/// )
/// ```
class ExpandableSection extends StatefulWidget {
  const ExpandableSection({
    super.key,
    this.titleKey,
    this.titleText,
    required this.child,
    this.subtitleKey,
    this.subtitleText,
    this.leading,
    this.initiallyExpanded = false,
    this.isExpanded,
    this.onToggle,
    this.headerPadding,
    this.contentPadding,
    this.showDivider = true,
  }) : assert(
          titleKey != null || titleText != null,
          'ExpandableSection: provide titleKey or titleText',
        );

  final String? titleKey;
  final String? titleText;
  final Widget child;
  final String? subtitleKey;
  final String? subtitleText;

  /// أيقونة أو widget تسبق العنوان
  final Widget? leading;

  /// الحالة الأولية (uncontrolled mode)
  final bool initiallyExpanded;

  /// controlled mode — اتركه null للـ uncontrolled
  final bool? isExpanded;
  final VoidCallback? onToggle;

  final EdgeInsets? headerPadding;
  final EdgeInsets? contentPadding;

  /// فاصل أسفل القسم
  final bool showDivider;

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isExpanded ?? widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant ExpandableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != null && widget.isExpanded != _expanded) {
      setState(() => _expanded = widget.isExpanded!);
    }
  }

  void _toggle() {
    if (widget.isExpanded == null) {
      setState(() => _expanded = !_expanded);
    }
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final scheme = context.colorScheme;

    final title =
        widget.titleKey != null ? widget.titleKey!.tr() : widget.titleText!;
    final subtitle = widget.subtitleKey != null
        ? widget.subtitleKey!.tr()
        : widget.subtitleText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: widget.headerPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: textTheme.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: colors.iconSubtle, size: 22),
                ),
              ],
            ),
          ),
        ),

        // ── Content ──────────────────────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: _expanded
              ? ClipRect(
                  child: Padding(
                    padding: widget.contentPadding ??
                        const EdgeInsets.only(
                            left: 16, right: 16, bottom: 12),
                    child: widget.child,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        if (widget.showDivider)
          Divider(height: 1, thickness: 0.5, color: colors.dividerSubtle),
      ],
    );
  }
}
