import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/ui/theme/app_theme.dart';

class AppThemeMode {
  AppThemeMode._();

  /// The order the picker renders in — see `theme_switcher.dart`.
  static const List<AdaptiveThemeMode> values = [
    AdaptiveThemeMode.light,
    AdaptiveThemeMode.dark,
    AdaptiveThemeMode.system,
  ];

  static void setThemeMode(BuildContext context, AdaptiveThemeMode mode) {
    getIt<AppTheme>().setThemeTo(mode, context);
  }

  /// The brightness actually on screen — **never [AdaptiveThemeMode.system]**.
  ///
  /// `system` is resolved against the platform brightness, so this answers
  /// "what is the user looking at", not "what did the user pick". For the
  /// stored preference — which is what a picker must highlight — read
  /// `AdaptiveTheme.of(context).mode` instead.
  static AdaptiveThemeMode getThemeMode(BuildContext context) {
    return getIt<AppTheme>().getThemeMode(context);
  }
}

extension AppThemeModeX on BuildContext {
  /// See [AppThemeMode.getThemeMode] — resolves `system`, so it can never
  /// return it.
  AdaptiveThemeMode get themeMode => AppThemeMode.getThemeMode(this);

  void setThemeMode(AdaptiveThemeMode mode) {
    AppThemeMode.setThemeMode(this, mode);
  }
}
