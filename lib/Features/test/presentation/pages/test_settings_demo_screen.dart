import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/core/platform/locale/app_locale.dart';
import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

@RoutePage()
class TestSettingsDemoScreen extends StatelessWidget {
  const TestSettingsDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.locale;
    final mode = AdaptiveTheme.of(context).mode;

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.testSettingsDemoTitle.tr()),
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Language ───────────────────────────────────────────────────────
            SectionTitle(
              titleKey: LocaleKeys.language,
              padding: const EdgeInsets.only(bottom: 8),
            ),
            AppCard(
              child: SegmentedButton<bool>(
                expandedInsets: EdgeInsets.zero,
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.language_rounded, size: 16),
                    label: Text('العربية'),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.language_rounded, size: 16),
                    label: Text('English'),
                  ),
                ],
                selected: {context.isAr},
                onSelectionChanged: (s) => context.changeLocale(
                  s.first ? AppLocale.arabic : AppLocale.english,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Theme ──────────────────────────────────────────────────────────
            SectionTitle(
              titleKey: LocaleKeys.theme,
              padding: const EdgeInsets.only(bottom: 8),
            ),
            AppCard(
              child: SegmentedButton<AdaptiveThemeMode>(
                expandedInsets: EdgeInsets.zero,
                segments: [
                  ButtonSegment<AdaptiveThemeMode>(
                    value: AdaptiveThemeMode.light,
                    icon: const Icon(Icons.light_mode_rounded, size: 16),
                    label: Text(LocaleKeys.themeLight.tr()),
                  ),
                  ButtonSegment<AdaptiveThemeMode>(
                    value: AdaptiveThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_rounded, size: 16),
                    label: Text(LocaleKeys.themeDark.tr()),
                  ),
                  ButtonSegment<AdaptiveThemeMode>(
                    value: AdaptiveThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_rounded, size: 16),
                    label: Text(LocaleKeys.themeSystem.tr()),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) {
                  switch (s.first) {
                    case AdaptiveThemeMode.light:
                      AdaptiveTheme.of(context).setLight();
                    case AdaptiveThemeMode.dark:
                      AdaptiveTheme.of(context).setDark();
                    case AdaptiveThemeMode.system:
                      AdaptiveTheme.of(context).setSystem();
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // ── Typography live preview ────────────────────────────────────────
            SectionTitle(
              titleKey: LocaleKeys.typography,
              padding: const EdgeInsets.only(bottom: 8),
            ),
            AppCard(
              child: Column(
                children: [
                  _StyleRow(name: 'displayLarge',  style: context.textTheme.displayLarge),
                  _StyleRow(name: 'headlineLarge', style: context.textTheme.headlineLarge),
                  _StyleRow(name: 'headlineMedium',style: context.textTheme.headlineMedium),
                  _StyleRow(name: 'titleMedium',   style: context.textTheme.titleMedium),
                  _StyleRow(name: 'bodyMedium',    style: context.textTheme.bodyMedium),
                  _StyleRow(name: 'bodySmall',     style: context.textTheme.bodySmall),
                  _StyleRow(name: 'labelLarge',    style: context.textTheme.labelLarge),
                ],
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _StyleRow extends StatelessWidget {
  const _StyleRow({required this.name, required this.style});

  final String name;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            child: Text(
              name,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.outline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              context.isAr ? 'نص تجريبي — Sample' : 'Sample Text — نص',
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
