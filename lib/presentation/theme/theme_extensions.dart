import 'package:flutter/material.dart';

import 'package:app_template/presentation/theme/app_colors.dart';

extension AppThemeX on BuildContext {
  ThemeData get _theme => Theme.of(this);

  AppColors get colors => _theme.extension<AppColors>()!;

  ColorScheme get colorScheme => _theme.colorScheme;

  TextTheme get textTheme => _theme.textTheme;

  TextStyle get baseTextStyle =>
      textTheme.bodyMedium ??
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
}
