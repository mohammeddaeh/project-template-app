import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

@RoutePage()
class TestThemeDemoScreen extends StatelessWidget {
  const TestThemeDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.locale;
    final scheme = context.colorScheme;
    final tt = context.textTheme;

    final colorItems = [
      _ColorItem('primary',         scheme.primary),
      _ColorItem('onPrimary',       scheme.onPrimary),
      _ColorItem('secondary',       scheme.secondary),
      _ColorItem('onSecondary',     scheme.onSecondary),
      _ColorItem('tertiary',        scheme.tertiary),
      _ColorItem('onTertiary',      scheme.onTertiary),
      _ColorItem('error',           scheme.error),
      _ColorItem('onError',         scheme.onError),
      _ColorItem('surface',         scheme.surface),
      _ColorItem('onSurface',       scheme.onSurface),
      _ColorItem('outline',         scheme.outline),
      _ColorItem('outlineVariant',  scheme.outlineVariant),
    ];

    final textStyles = [
      _TextStyleItem('displayLarge',    tt.displayLarge),
      _TextStyleItem('headlineLarge',   tt.headlineLarge),
      _TextStyleItem('headlineMedium',  tt.headlineMedium),
      _TextStyleItem('headlineSmall',   tt.headlineSmall),
      _TextStyleItem('bodyMedium',      tt.bodyMedium),
      _TextStyleItem('bodySmall',       tt.bodySmall),
      _TextStyleItem('labelLarge',      tt.labelLarge),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.testThemeDemoTitle.tr()),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Color Palette ──────────────────────────────────────────────
            SectionTitle(titleKey: LocaleKeys.colorPalette),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.8,
              children: colorItems.map((c) => _ColorTile(item: c)).toList(),
            ),
            const SizedBox(height: 32),

            // ── Typography Scale ───────────────────────────────────────────
            SectionTitle(titleKey: LocaleKeys.typography),
            const SizedBox(height: 12),
            ...textStyles.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        s.name,
                        style: tt.bodySmall?.copyWith(
                          color: scheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'النص / Sample',
                        style: s.style,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _ColorItem {
  const _ColorItem(this.name, this.color);
  final String name;
  final Color color;
}

class _TextStyleItem {
  const _TextStyleItem(this.name, this.style);
  final String name;
  final TextStyle? style;
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({required this.item});
  final _ColorItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = item.color.computeLuminance() < 0.35;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        item.name,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
