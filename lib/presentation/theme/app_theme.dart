import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/presentation/theme/app_colors.dart';

@lazySingleton
class AppTheme {
  ThemeData lightTheme(Locale locale, AppFontOption font) =>
      AppThemeData.light(locale, font);
  ThemeData darkTheme(Locale locale, AppFontOption font) =>
      AppThemeData.dark(locale, font);

  void setThemeTo(AdaptiveThemeMode mode, BuildContext context) {
    final currentMode = AdaptiveTheme.of(context).mode;
    if (mode != currentMode) {
      AdaptiveTheme.of(context).setThemeMode(mode);
    }
  }

  AdaptiveThemeMode getThemeMode(BuildContext context) {
    final isLight =
        MediaQuery.of(context).platformBrightness == Brightness.light;
    final currentMode = AdaptiveTheme.of(context).mode;
    if (currentMode == AdaptiveThemeMode.light ||
        (currentMode == AdaptiveThemeMode.system && isLight)) {
      return AdaptiveThemeMode.light;
    }
    if (currentMode == AdaptiveThemeMode.dark ||
        (currentMode == AdaptiveThemeMode.system && !isLight)) {
      return AdaptiveThemeMode.dark;
    }
    return isLight ? AdaptiveThemeMode.light : AdaptiveThemeMode.dark;
  }
}

abstract final class AppThemeData {
  AppThemeData._();

  static ColorScheme _colorSchemeLight(AppColors c) {
    return ColorScheme(
      brightness: Brightness.light,
      primary: c.primary,
      onPrimary: c.textOnAccent,
      // primaryContainer: c.primaryContainer,
      // onPrimaryContainer: c.onPrimaryContainer,
      secondary: c.secondary,
      onSecondary: c.onSecondary,
      secondaryContainer: c.secondaryContainer,
      onSecondaryContainer: c.onSecondaryContainer,
      tertiary: c.tertiary,
      onTertiary: c.onTertiary,
      tertiaryContainer: c.tertiaryContainer,
      onTertiaryContainer: c.onTertiaryContainer,
      error: c.error,
      onError: c.onError,
      surface: c.bgCard,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.bgElevated2,
      onSurfaceVariant: c.textSecondary,
      outline: c.borderSubtle,
      outlineVariant: c.outlineVariant,
      shadow: c.shadow,
      scrim: c.scrim,
      inverseSurface: c.bgInverse,
      onInverseSurface: c.textOnPrimary,
    );
  }

  static ColorScheme _colorSchemeDark(AppColors c) {
    return ColorScheme(
      brightness: Brightness.dark,
      primary: c.primary,
      onPrimary: c.textOnAccent,
      secondary: c.secondary,
      onSecondary: c.onSecondary,
      secondaryContainer: c.secondaryContainer,
      onSecondaryContainer: c.onSecondaryContainer,
      tertiary: c.tertiary,
      onTertiary: c.onTertiary,
      tertiaryContainer: c.tertiaryContainer,
      onTertiaryContainer: c.onTertiaryContainer,
      error: c.error,
      onError: c.onError,
      surface: c.bgCard,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.bgElevated2,
      onSurfaceVariant: c.textSecondary,
      outline: c.borderSubtle,
      outlineVariant: c.outlineVariant,
      shadow: c.shadow,
      scrim: c.scrim,
      inverseSurface: c.bgInverse,
      onInverseSurface: c.textOnPrimary,
    );
  }

  static ThemeData light(Locale locale, AppFontOption font) {
    final appColors = AppColors.light();
    final colorScheme = _colorSchemeLight(appColors);
    return _theme(colorScheme, appColors, Brightness.light, locale, font);
  }

  static ThemeData dark(Locale locale, AppFontOption font) {
    final appColors = AppColors.dark();
    final colorScheme = _colorSchemeDark(appColors);
    return _theme(colorScheme, appColors, Brightness.dark, locale, font);
  }

  static ThemeData _theme(
    ColorScheme scheme,
    AppColors c,
    Brightness brightness,
    Locale locale,
    AppFontOption font,
  ) {
    final String fontFamily = font.familyFor(locale.languageCode);
    const transparent = Colors.transparent;
    return ThemeData(
      useMaterial3: false,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: c.bgPage,
      cardColor: c.bgCard,
      dividerColor: c.dividerSubtle,
      fontFamily: fontFamily,
      shadowColor: c.shadowColor,
      hintColor: c.textMuted,
      disabledColor: c.textMuted,
      splashColor: scheme.primary.withValues(alpha: 0.2),
      highlightColor: scheme.primary.withValues(alpha: 0.1),
      unselectedWidgetColor: c.textMuted,
      canvasColor: c.bgCard,

      appBarTheme: AppBarTheme(
        backgroundColor: c.bgPage,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: transparent,
        iconTheme: IconThemeData(color: c.textPrimary),
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),

      cardTheme: CardThemeData(
        color: c.bgCard,
        surfaceTintColor: transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.borderSubtle),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: c.dividerSubtle,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bgNeutral,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.stateError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.stateError, width: 1.5),
        ),
        labelStyle: TextStyle(color: c.textSecondary, fontFamily: fontFamily),
        hintStyle: TextStyle(color: c.textMuted, fontFamily: fontFamily),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: fontFamily,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            fontFamily: fontFamily,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            fontFamily: fontFamily,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: fontFamily,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.bgCard,
        selectedItemColor: scheme.primary,
        unselectedItemColor: c.textMuted,
        selectedLabelStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          fontFamily: fontFamily,
        ),
        unselectedLabelStyle: TextStyle(
          color: c.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontFamily: fontFamily,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return transparent;
        }),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
        side: BorderSide(color: c.borderSubtle, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return c.borderSubtle;
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return c.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.5);
          }
          return c.borderSubtle;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: c.borderSubtle,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.2),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: c.borderSubtle,
        circularTrackColor: c.borderSubtle,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.bgCard,
        surfaceTintColor: transparent,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        contentTextStyle: TextStyle(
          color: c.textSecondary,
          fontSize: 14,
          fontFamily: fontFamily,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.textPrimary,
        contentTextStyle: TextStyle(
          color: c.textOnPrimary,
          fontSize: 14,
          fontFamily: fontFamily,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      iconTheme: IconThemeData(color: c.textSecondary),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.2),
        selectionHandleColor: scheme.primary,
      ),

      listTileTheme: ListTileThemeData(
        textColor: c.textPrimary,
        iconColor: c.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: c.borderSubtle.withValues(alpha: 0.5),
        selectedColor: scheme.primary.withValues(alpha: 0.3),
        labelStyle: TextStyle(color: c.textPrimary, fontFamily: fontFamily),
        secondaryLabelStyle: TextStyle(
          color: c.textSecondary,
          fontFamily: fontFamily,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: c.textMuted,
        indicatorColor: scheme.primary,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.bgCard,
        modalBackgroundColor: c.bgCard,
        showDragHandle: false,
        dragHandleColor: c.dividerSubtle,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      textTheme: _textTheme(c.textPrimary, c.textSecondary, fontFamily),
      primaryTextTheme: _textTheme(c.textPrimary, c.textSecondary, fontFamily),

      extensions: <ThemeExtension<dynamic>>[c],
    );
  }

  static TextTheme _textTheme(
    Color primary,
    Color secondary,
    String fontFamily,
  ) {
    return TextTheme(
      titleLarge: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        fontFamily: fontFamily,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        fontFamily: fontFamily,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        fontFamily: fontFamily,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        fontFamily: fontFamily,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        fontFamily: fontFamily,
        color: primary,
      ),
      bodySmall: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 12,
        fontFamily: fontFamily,
        color: primary,
      ),
      displayLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        fontFamily: fontFamily,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: fontFamily,
        color: primary,
      ),
      displaySmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        fontFamily: fontFamily,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 26,
        fontFamily: fontFamily,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        fontFamily: fontFamily,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        fontFamily: fontFamily,
        color: primary,
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        fontFamily: fontFamily,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 12,
        fontFamily: fontFamily,
        color: primary,
      ),
      labelSmall: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 10,
        fontFamily: fontFamily,
        color: primary,
      ),
    );
  }
}

extension TextThemeEx on BuildContext {
  /// Uses the theme font (Arabic or Latin family per locale).
  String get _fontFamily =>
      Theme.of(this).textTheme.bodyMedium?.fontFamily ??
      AppFonts.available.first.latinFamily;

  TextStyle get headLineS24W600 =>
      Theme.of(this).textTheme.headlineLarge!.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: _fontFamily,
      );

  TextStyle get labelSmallS16W400 =>
      Theme.of(this).textTheme.headlineLarge!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontFamily: _fontFamily,
      );

  TextStyle get labelSmallS12W400 =>
      Theme.of(this).textTheme.headlineLarge!.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: _fontFamily,
      );

  TextStyle get baseTextStyle =>
      Theme.of(this).textTheme.bodyMedium!.copyWith(fontFamily: _fontFamily);

  TextStyle get headLineMed => Theme.of(
    this,
  ).textTheme.headlineMedium!.copyWith(fontFamily: _fontFamily);

  TextStyle get liteGrayHeadLineText =>
      Theme.of(this).textTheme.headlineLarge!.copyWith(fontFamily: _fontFamily);

  TextStyle get appBarStyle =>
      Theme.of(this).textTheme.labelLarge!.copyWith(fontFamily: _fontFamily);

  TextStyle get bodyNutralColorsBure =>
      Theme.of(this).textTheme.bodyMedium!.copyWith(fontFamily: _fontFamily);

  TextStyle get bodyPrimarys700 =>
      Theme.of(this).textTheme.labelSmall!.copyWith(fontFamily: _fontFamily);
}

extension ThemeEx on BuildContext {
  Color get iconColor => Theme.of(this).iconTheme.color!;
  Color get cardColor => Theme.of(this).cardColor;
  Color get dividerColor => Theme.of(this).dividerColor;
  Color get scaffoldBackgroundColor => Theme.of(this).scaffoldBackgroundColor;
}
