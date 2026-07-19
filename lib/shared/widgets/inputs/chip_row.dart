import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChipRow<T> — صف chips قابلة للتحديد
// ─────────────────────────────────────────────────────────────────────────────

/// صف أفقي من الـ chips لاختيار عنصر واحد أو أكثر.
///
/// **Single-select (الافتراضي):** مرر [selectedValue] + [onSelected].
/// **Multi-select:** مرر [selectedValues] + [onMultiChanged] + `multiSelect: true`.
/// **Wrap (متعدد الأسطر):** `scrollable: false` — يستخدم [Wrap] بدل [Row].
///
/// ```dart
/// // Single-select — اختيار فئة
/// ChipRow<Category>(
///   items: categories,
///   labelResolver: (c) => c.name,
///   selectedValue: _selectedCategory,
///   onSelected: (c) => setState(() => _selectedCategory = c),
/// )
///
/// // Multi-select — اختيار مهارات
/// ChipRow<Skill>(
///   items: skills,
///   labelResolver: (s) => s.name,
///   multiSelect: true,
///   selectedValues: _selectedSkills,
///   onMultiChanged: (set) => setState(() => _selectedSkills = set),
/// )
///
/// // Wrap (متعدد الأسطر)
/// ChipRow<String>(
///   items: tags,
///   labelResolver: (t) => t,
///   selectedValue: _tag,
///   onSelected: (t) => setState(() => _tag = t),
///   scrollable: false,
/// )
/// ```
class ChipRow<T> extends StatelessWidget {
  /// Single-select
  const ChipRow({
    super.key,
    required this.items,
    required this.labelResolver,
    required this.onSelected,
    this.selectedValue,
    this.scrollable = true,
    this.activeColor,
    this.inactiveColor,
    this.padding,
    this.spacing = 8,
  })  : multiSelect = false,
        selectedValues = const [],
        onMultiChanged = null;

  /// Multi-select
  const ChipRow.multi({
    super.key,
    required this.items,
    required this.labelResolver,
    required ValueChanged<List<T>> onChanged,
    this.selectedValues = const [],
    this.scrollable = true,
    this.activeColor,
    this.inactiveColor,
    this.padding,
    this.spacing = 8,
  })  : multiSelect = true,
        selectedValue = null,
        onSelected = null,
        onMultiChanged = onChanged;

  final List<T> items;

  /// محوّل من [T] إلى نص معروض
  final String Function(T) labelResolver;

  // ── Single-select ─────────────────────────────────────────────────────────

  /// العنصر المحدد حالياً (null = لا اختيار). ضع null للرفع.
  final T? selectedValue;

  /// callback عند الاختيار — null إن أُعيد الضغط على المحدد (رفع).
  final ValueChanged<T?>? onSelected;

  // ── Multi-select ──────────────────────────────────────────────────────────

  final bool multiSelect;

  /// قائمة العناصر المحددة (multi-select)
  final List<T> selectedValues;

  /// callback عند تغيير التحديد (multi-select)
  final ValueChanged<List<T>>? onMultiChanged;

  // ── Visual ────────────────────────────────────────────────────────────────

  /// true = [SingleChildScrollView] أفقي · false = [Wrap] متعدد الأسطر
  final bool scrollable;

  /// لون الـ chip المحدد — الافتراضي: primary
  final Color? activeColor;

  /// لون نص الـ chip غير المحدد — الافتراضي: textMuted
  final Color? inactiveColor;

  final EdgeInsets? padding;

  /// مسافة بين الـ chips
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final chips = items.map((item) => _ChipItem<T>(
          item: item,
          label: labelResolver(item),
          isSelected: multiSelect
              ? selectedValues.contains(item)
              : item == selectedValue,
          activeColor: activeColor ?? context.colors.primary,
          inactiveColor: inactiveColor ?? context.colors.textMuted,
          borderColor: context.colors.borderSubtle,
          bgSelected: (activeColor ?? context.colors.primary).withValues(alpha: 0.12),
          onTap: () => _handleTap(item),
        )).toList();

    if (!scrollable) {
      return Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: chips,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            chips[i],
            if (i < chips.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }

  void _handleTap(T item) {
    if (multiSelect) {
      final updated = List<T>.from(selectedValues);
      if (updated.contains(item)) {
        updated.remove(item);
      } else {
        updated.add(item);
      }
      onMultiChanged?.call(updated);
    } else {
      // تحديد نفس العنصر → رفع الاختيار
      onSelected?.call(item == selectedValue ? null : item);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ChipItem — chip فردي داخلي
// ─────────────────────────────────────────────────────────────────────────────

class _ChipItem<T> extends StatelessWidget {
  const _ChipItem({
    required this.item,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.borderColor,
    required this.bgSelected,
    required this.onTap,
  });

  final T item;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final Color borderColor;
  final Color bgSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? bgSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : borderColor,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: isSelected ? activeColor : inactiveColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
