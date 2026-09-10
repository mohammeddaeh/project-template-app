import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/app_theme_mode.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// Light · Dark · System, as three cards in one row.
///
/// Lives beside the theme it drives rather than under `ui/widgets/`, matching
/// [`ui/locale/locale_switcher.dart`] — a switcher belongs with its domain, and
/// both are imported by path rather than from the widgets barrel.
///
/// ```dart
/// const ThemeSwitcher()
/// ```
class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key, this.padding = _defaultPadding});

  static const _defaultPadding = EdgeInsets.fromLTRB(16, 4, 16, 12);
  static const _gap = 8.0;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    // The *stored* preference — deliberately not `context.themeMode`, which
    // resolves `system` down to light or dark. Reading that here would leave
    // `system` permanently unselectable in the UI.
    final current = AdaptiveTheme.of(context).mode;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (final mode in AppThemeMode.values) ...[
            if (mode != AppThemeMode.values.first) const SizedBox(width: _gap),
            Expanded(
              child: _ThemeOptionCard(
                icon: _iconFor(mode),
                label: _labelKeyFor(mode).tr(),
                isSelected: current == mode,
                // Routes through `AppTheme` in the DI graph, which no-ops when
                // the mode is unchanged.
                onTap: () => context.setThemeMode(mode),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Both switches are exhaustive on purpose: a fourth mode would fail to
  // compile here rather than render a blank card.
  static IconData _iconFor(AdaptiveThemeMode mode) => switch (mode) {
    AdaptiveThemeMode.light => Icons.light_mode_outlined,
    AdaptiveThemeMode.dark => Icons.dark_mode_outlined,
    AdaptiveThemeMode.system => Icons.brightness_auto_outlined,
  };

  static String _labelKeyFor(AdaptiveThemeMode mode) => switch (mode) {
    AdaptiveThemeMode.light => LocaleKeys.themeLight,
    AdaptiveThemeMode.dark => LocaleKeys.themeDark,
    AdaptiveThemeMode.system => LocaleKeys.themeSystem,
  };
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = isSelected ? colors.textOnPrimary : colors.textSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.bgNeutral,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.primary : colors.borderSubtle,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: foreground),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: foreground,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
