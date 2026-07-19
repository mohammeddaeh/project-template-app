import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/layout/primary_button.dart';
import 'app_bottom_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

/// خيار فلتر واحد — قابل للاختيار.
class FilterOption<T> {
  FilterOption({
    required this.value,
    required this.labelKey,
    this.isSelected = false,
  });

  final T value;

  /// مفتاح ترجمة من `LocaleKeys.*`
  final String labelKey;
  bool isSelected;

  FilterOption<T> copyWith({bool? isSelected}) => FilterOption(
        value: value,
        labelKey: labelKey,
        isSelected: isSelected ?? this.isSelected,
      );
}

/// مجموعة فلاتر ذات عنوان.
class FilterGroup<T> {
  const FilterGroup({
    required this.titleKey,
    required this.options,
    this.multiSelect = true,
  });

  final String titleKey;
  final List<FilterOption<T>> options;

  /// true = اختيار متعدد (checkboxes) / false = اختيار واحد (radio)
  final bool multiSelect;
}

/// خيار ترتيب — اختيار واحد مع اتجاه (تصاعدي/تنازلي).
class SortOption<T> {
  SortOption({
    required this.value,
    required this.labelKey,
    this.isAscending = true,
  });

  final T value;
  final String labelKey;
  bool isAscending;

  SortOption<T> copyWith({bool? isAscending}) => SortOption(
        value: value,
        labelKey: labelKey,
        isAscending: isAscending ?? this.isAscending,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppFilterSheet
// ─────────────────────────────────────────────────────────────────────────────

/// Filter sheet موحّد — فلاتر + ترتيب.
///
/// ```dart
/// AppFilterSheet.show<String>(
///   context,
///   titleKey: LocaleKeys.filter,
///   filterGroups: [
///     FilterGroup(
///       titleKey: LocaleKeys.status,
///       options: [
///         FilterOption(value: 'active',   labelKey: LocaleKeys.active),
///         FilterOption(value: 'inactive', labelKey: LocaleKeys.inactive),
///       ],
///     ),
///   ],
///   sortOptions: [
///     SortOption(value: 'name',      labelKey: LocaleKeys.name),
///     SortOption(value: 'createdAt', labelKey: LocaleKeys.date),
///   ],
///   onApply: (selectedOptions, sortOption) {
///     cubit.applyFilter(
///       statuses: selectedOptions.map((o) => o.value).toList(),
///       sort:     sortOption,
///     );
///   },
///   onReset: () => cubit.resetFilter(),
/// );
/// ```
class AppFilterSheet {
  AppFilterSheet._();

  static Future<void> show<T>(
    BuildContext context, {
    String? titleKey,
    required List<FilterGroup<T>> filterGroups,
    List<SortOption<T>>? sortOptions,
    SortOption<T>? activeSortOption,
    void Function(List<FilterOption<T>> selected, SortOption<T>? sort)? onApply,
    VoidCallback? onReset,
  }) {
    return AppBottomSheet.show(
      context,
      title: (titleKey ?? LocaleKeys.filter).tr(),
      showDivider: true,
      isScrollable: true,
      maxHeightFraction: 0.85,
      contentPadding: EdgeInsets.zero,
      child: _FilterSheetContent<T>(
        filterGroups:   filterGroups,
        sortOptions:    sortOptions ?? const [],
        activeSortOption: activeSortOption,
        onApply: onApply,
        onReset: onReset,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content (Stateful — يدير نسخة محلية من الخيارات)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterSheetContent<T> extends StatefulWidget {
  const _FilterSheetContent({
    required this.filterGroups,
    required this.sortOptions,
    this.activeSortOption,
    this.onApply,
    this.onReset,
  });

  final List<FilterGroup<T>> filterGroups;
  final List<SortOption<T>> sortOptions;
  final SortOption<T>? activeSortOption;
  final void Function(List<FilterOption<T>>, SortOption<T>?)? onApply;
  final VoidCallback? onReset;

  @override
  State<_FilterSheetContent<T>> createState() => _FilterSheetContentState<T>();
}

class _FilterSheetContentState<T> extends State<_FilterSheetContent<T>> {
  // نسخ محلية — لا نُعدّل قوائم الـ parent مباشرة
  late final List<FilterGroup<T>> _groups;
  SortOption<T>? _selectedSort;

  @override
  void initState() {
    super.initState();
    _groups = widget.filterGroups
        .map((g) => FilterGroup<T>(
              titleKey: g.titleKey,
              multiSelect: g.multiSelect,
              options: g.options
                  .map((o) => o.copyWith(isSelected: o.isSelected))
                  .toList(),
            ))
        .toList();
    _selectedSort = widget.activeSortOption;
  }

  void _toggleFilter(FilterGroup<T> group, FilterOption<T> option) {
    setState(() {
      if (group.multiSelect) {
        option.isSelected = !option.isSelected;
      } else {
        // radio — deselect others
        for (final o in group.options) {
          o.isSelected = o == option ? !o.isSelected : false;
        }
      }
    });
  }

  void _toggleSort(SortOption<T> sort) {
    setState(() {
      if (_selectedSort?.value == sort.value) {
        // نفس الترتيب → عكس الاتجاه
        _selectedSort = sort.copyWith(isAscending: !sort.isAscending);
      } else {
        _selectedSort = sort.copyWith(isAscending: true);
      }
    });
  }

  void _onApply() {
    final selected = _groups
        .expand((g) => g.options)
        .where((o) => o.isSelected)
        .toList();
    Navigator.of(context).pop();
    widget.onApply?.call(selected, _selectedSort);
  }

  void _onReset() {
    Navigator.of(context).pop();
    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── قوائم الفلاتر ──
        ..._groups.map((group) => _FilterGroupSection<T>(
              group: group,
              onToggle: (opt) => _toggleFilter(group, opt),
            )),

        // ── الترتيب ──
        if (widget.sortOptions.isNotEmpty) ...[
          _SectionTitle(titleKey: LocaleKeys.sortBy),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.sortOptions.map((sort) {
                final isSelected = _selectedSort?.value == sort.value;
                final isAsc = _selectedSort?.isAscending ?? true;
                return _SortChip(
                  label: sort.labelKey.tr(),
                  isSelected: isSelected,
                  isAscending: isSelected ? isAsc : null,
                  onTap: () => _toggleSort(sort),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── الأزرار ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            children: [
              // إعادة تعيين
              Expanded(
                child: OutlinedButton(
                  onPressed: _onReset,
                  child: Text(LocaleKeys.reset.tr()),
                ),
              ),
              const SizedBox(width: 12),
              // تطبيق
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: LocaleKeys.apply.tr(),
                  onTap: _onApply,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FilterGroupSection<T> extends StatelessWidget {
  const _FilterGroupSection({required this.group, required this.onToggle});

  final FilterGroup<T> group;
  final ValueChanged<FilterOption<T>> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(titleKey: group.titleKey),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.options.map((opt) {
              return _FilterChip(
                label: opt.labelKey.tr(),
                isSelected: opt.isSelected,
                onTap: () => onToggle(opt),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.titleKey});
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        titleKey.tr(),
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.textMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary.withValues(alpha: 0.12)
              : context.colors.bgCard,
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : context.colors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? context.colors.primary
                : context.colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isAscending,
  });

  final String label;
  final bool isSelected;
  final bool? isAscending; // null = غير محدد
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary.withValues(alpha: 0.12)
              : context.colors.bgCard,
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : context.colors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected && isAscending != null) ...[
              const SizedBox(width: 4),
              Icon(
                isAscending! ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: context.colors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
