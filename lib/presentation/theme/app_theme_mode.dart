import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/presentation/theme/app_theme.dart';

class AppThemeMode {
  AppThemeMode._();

  static const List<AdaptiveThemeMode> values = [
    AdaptiveThemeMode.light,
    AdaptiveThemeMode.dark,
    AdaptiveThemeMode.system,
  ];

  static String label(BuildContext context, AdaptiveThemeMode mode) {
    switch (mode) {
      case AdaptiveThemeMode.light:
        return 'Light';
      case AdaptiveThemeMode.dark:
        return 'Dark';
      case AdaptiveThemeMode.system:
        return 'System';
    }
  }

   static void setThemeMode(BuildContext context, AdaptiveThemeMode mode) {
    getIt<AppTheme>().setThemeTo(mode, context);
  }

   static AdaptiveThemeMode getThemeMode(BuildContext context) {
    return getIt<AppTheme>().getThemeMode(context);
  }
}

 extension AppThemeModeX on BuildContext {
  AdaptiveThemeMode get themeMode => AppThemeMode.getThemeMode(this);

  void setThemeMode(AdaptiveThemeMode mode) {
    AppThemeMode.setThemeMode(this, mode);
  }
}

 class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key, this.title, this.dense = false});

  final String? title;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final currentMode = context.themeMode;
    final theme = Theme.of(context);

    Widget buildOption(AdaptiveThemeMode mode) {
      final isSelected = currentMode == mode;
      return ListTile(
        dense: dense,
        title: Text(AppThemeMode.label(context, mode)),
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isSelected ? theme.colorScheme.primary : theme.disabledColor,
        ),
        onTap: () => context.setThemeMode(mode),
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: AppThemeMode.values.map(buildOption).toList(),
    );

    if (title != null && title!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          content,
        ],
      );
    }

    return content;
  }
}
