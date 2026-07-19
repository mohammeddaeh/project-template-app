import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KeyValueRow — صف تسمية + قيمة
// ─────────────────────────────────────────────────────────────────────────────

/// صف يعرض تسمية (يسار) وقيمة (يمين)، مع دعم النسخ والاتجاه.
///
/// ```dart
/// // بسيط
/// KeyValueRow(labelKey: LocaleKeys.name, value: user.name)
///
/// // قابل للنسخ + LTR (للأرقام والـ IDs)
/// KeyValueRow(
///   labelKey: LocaleKeys.iban,
///   value: account.iban,
///   copyable: true,
///   ltr: true,
/// )
///
/// // قيمة مخصصة (chip، badge، إلخ)
/// KeyValueRow(
///   labelKey: LocaleKeys.status,
///   valueWidget: StatusChip(status: order.status),
/// )
/// ```
class KeyValueRow extends StatefulWidget {
  const KeyValueRow({
    super.key,
    required this.labelKey,
    this.value,
    this.valueWidget,
    this.copyable = false,
    this.ltr = false,
    this.showDivider = true,
    this.padding,
    this.labelStyle,
    this.valueStyle,
    this.copySuccessKey = 'copied',
  }) : assert(
          value != null || valueWidget != null,
          'KeyValueRow: either value or valueWidget must be provided',
        );

  /// مفتاح ترجمة التسمية
  final String labelKey;

  /// نص القيمة — يُستخدم مع [copyable]
  final String? value;

  /// widget مخصص بدلاً من النص (أعلى أولوية من [value])
  final Widget? valueWidget;

  /// إظهار أيقونة نسخ — مفيد لـ IBAN وأرقام الهاتف والرموز
  final bool copyable;

  /// إجبار اتجاه النص LTR للقيمة (أرقام، معرفات، روابط)
  final bool ltr;

  /// إظهار فاصل أسفل الصف (الافتراضي: true)
  final bool showDivider;

  final EdgeInsets? padding;

  /// override لنمط التسمية — الافتراضي: `bodyMedium` بلون `textMuted`
  final TextStyle? labelStyle;

  /// override لنمط القيمة — الافتراضي: `bodyMedium` بلون `onSurface`
  final TextStyle? valueStyle;

  /// مفتاح ترجمة رسالة نجاح النسخ (الافتراضي: `'copied'`)
  final String copySuccessKey;

  @override
  State<KeyValueRow> createState() => _KeyValueRowState();
}

class _KeyValueRowState extends State<KeyValueRow> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    if (widget.value == null || _copied) return;
    await Clipboard.setData(ClipboardData(text: widget.value!));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final scheme = context.colorScheme;

    Widget valueContent;
    if (widget.valueWidget != null) {
      valueContent = widget.valueWidget!;
    } else {
      valueContent = Text(
        widget.value ?? '',
        style: widget.valueStyle ??
            textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        textAlign: TextAlign.end,
      );
    }

    if (widget.ltr) {
      valueContent = Directionality(
        textDirection: TextDirection.ltr,
        child: valueContent,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: widget.padding ??
              const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.labelKey.tr(),
                  style: widget.labelStyle ??
                      textTheme.bodyMedium
                          ?.copyWith(color: colors.textMuted),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: valueContent),
                    if (widget.copyable && widget.value != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _handleCopy,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _copied
                                ? Icon(
                                    Icons.check_rounded,
                                    key: const ValueKey('check'),
                                    size: 16,
                                    color: scheme.primary,
                                  )
                                : Icon(
                                    Icons.copy_rounded,
                                    key: const ValueKey('copy'),
                                    size: 16,
                                    color: colors.iconSubtle,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.showDivider)
          Divider(height: 1, thickness: 0.5, color: colors.dividerSubtle),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KeyValueSection — مجموعة صفوف داخل بطاقة
// ─────────────────────────────────────────────────────────────────────────────

/// يجمع عدة [KeyValueRow] داخل بطاقة مع عنوان اختياري.
/// يتحكم تلقائياً في الفاصل بين الصفوف (لا فاصل بعد الأخير).
///
/// ```dart
/// KeyValueSection(
///   titleKey: LocaleKeys.personalInfo,
///   rows: [
///     KeyValueRow(labelKey: LocaleKeys.name,  value: user.name),
///     KeyValueRow(labelKey: LocaleKeys.email, value: user.email),
///     KeyValueRow(
///       labelKey: LocaleKeys.phone,
///       value: user.phone,
///       copyable: true,
///       ltr: true,
///     ),
///   ],
/// )
/// ```
class KeyValueSection extends StatelessWidget {
  const KeyValueSection({
    super.key,
    required this.rows,
    this.titleKey,
    this.padding,
  }) : assert(rows.length > 0, 'KeyValueSection requires at least one row');

  final List<KeyValueRow> rows;

  /// مفتاح ترجمة عنوان القسم (اختياري)
  final String? titleKey;

  /// padding خارجي للمقطع كاملاً
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titleKey != null) ...[
            Text(
              titleKey!.tr(),
              style: textTheme.titleSmall?.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < rows.length; i++)
                  _buildRow(rows[i], showDivider: i < rows.length - 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // يُعيد بناء الصف مع تجاوز showDivider — Section تتحكم بالفواصل
  KeyValueRow _buildRow(KeyValueRow row, {required bool showDivider}) {
    return KeyValueRow(
      labelKey: row.labelKey,
      value: row.value,
      valueWidget: row.valueWidget,
      copyable: row.copyable,
      ltr: row.ltr,
      showDivider: showDivider,
      padding: row.padding,
      labelStyle: row.labelStyle,
      valueStyle: row.valueStyle,
      copySuccessKey: row.copySuccessKey,
    );
  }
}
