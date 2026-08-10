import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/inputs/app_search_bar.dart';

/// Search box plus a readable summary of whatever is narrowing a list.
///
/// Composes [AppSearchBar] rather than reimplementing it — the debounce, the
/// clear button and the loading state already live there.
///
/// **Why the chips matter as much as the box:** a filtered list and an empty
/// organisation look identical. Once anything is narrowing the results, the
/// reader has to be able to see *what* without reopening the filter sheet, and
/// undo it without hunting for the control that set it.
///
/// Designed to sit in an `AppBar.bottom`, so it stays put while the list
/// scrolls — the answer to "why am I only seeing these?" must not scroll away
/// from the rows it explains.
class ListFilterBar extends StatelessWidget {
  const ListFilterBar({
    super.key,
    required this.onSearch,
    required this.onClearSearch,
    this.hint,
    this.initialQuery,
    this.activeFilters = const [],
    this.onClearAll,
    this.isLoading = false,
  });

  /// Fired after the debounce with the trimmed term.
  final ValueChanged<String> onSearch;

  /// Fired when the field becomes empty — by the clear button or by deleting.
  final VoidCallback onClearSearch;

  final String? hint;
  final String? initialQuery;

  /// Human-readable labels for everything currently filtering the list,
  /// **including the search term**: leaving it out lets "no results" read as
  /// "nothing exists".
  final List<String> activeFilters;

  /// Clears search and filters together. Omit to hide the reset chip.
  final VoidCallback? onClearAll;

  final bool isLoading;

  /// Height to reserve in `PreferredSize`. Two values, not one: the chip row
  /// only exists when something is active, and reserving its height always
  /// would leave a permanent gap under the search box.
  static double heightFor({required bool hasActiveFilters}) =>
      hasActiveFilters ? 108 : 72;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSearchBar(
            hint: hint,
            initialValue: initialQuery,
            isLoading: isLoading,
            onSearch: onSearch,
            onClear: onClearSearch,
          ),
          if (activeFilters.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final label in activeFilters) ...[
                    Chip(
                      label: Text(label),
                      labelStyle: context.textTheme.bodySmall,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Offered beside what it clears, not buried back inside the
                  // sheet the reader would have to reopen.
                  if (onClearAll != null)
                    ActionChip(
                      avatar: const Icon(Icons.close, size: 16),
                      label: Text(LocaleKeys.clearFilters.tr()),
                      labelStyle: context.textTheme.bodySmall,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onPressed: onClearAll,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
