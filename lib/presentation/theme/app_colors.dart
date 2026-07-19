import 'package:flutter/material.dart';

import 'package:app_template/presentation/theme/app_palette.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,

    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.surfaceTint,
    required this.shadowColor,
    required this.bgPage,
    required this.bgCard,
    required this.bgElevated,
    required this.bgElevated2,
    required this.bgNeutral,
    required this.bgInverse,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnPrimary,
    required this.textOnAccent,
    required this.borderSubtle,
    required this.borderFocus,
    required this.dividerSubtle,
    required this.stateError,
    required this.logo,
    // Toast
    required this.primaryToastError,
    required this.secondaryToastError,
    // Avatar
    required this.avatarBg,
    required this.avatarFg,
    // Status chips / badges
    required this.statusSuccessBg,
    required this.statusSuccessFg,
    required this.statusWarningBg,
    required this.statusWarningFg,
    required this.statusErrorBg,
    required this.statusErrorFg,
    required this.statusInfoBg,
    required this.statusInfoFg,
    required this.statusNeutralBg,
    required this.statusNeutralFg,
    // Icons
    required this.iconAction,
    required this.iconSubtle,
  });

  // ColorScheme
  final Color primary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;

  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color surfaceTint;
  final Color shadowColor;

  // Semantic
  final Color bgPage;
  final Color bgCard;
  final Color bgElevated;
  final Color bgElevated2;
  final Color bgNeutral;
  final Color bgInverse;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnPrimary;
  final Color textOnAccent;
  final Color borderSubtle;
  final Color borderFocus;
  final Color dividerSubtle;
  final Color stateError;
  final Color logo;
  // Toast
  final Color primaryToastError;
  final Color secondaryToastError;
  // Avatar
  final Color avatarBg;
  final Color avatarFg;
  // Status chips / badges
  final Color statusSuccessBg;
  final Color statusSuccessFg;
  final Color statusWarningBg;
  final Color statusWarningFg;
  final Color statusErrorBg;
  final Color statusErrorFg;
  final Color statusInfoBg;
  final Color statusInfoFg;
  final Color statusNeutralBg;
  final Color statusNeutralFg;
  // Icons
  final Color iconAction;
  final Color iconSubtle;

  factory AppColors.light() {
    return AppColors(
      primary: AppPalette.primaryMain,
      primaryContainer: AppPalette.secondary24,
      onPrimaryContainer: AppPalette.gray900,
      secondary: AppPalette.secondaryMain,
      onSecondary: AppPalette.white,
      secondaryContainer: AppPalette.primary24,
      onSecondaryContainer: AppPalette.gray900,
      tertiary: AppPalette.primary40,
      onTertiary: AppPalette.gray900,
      tertiaryContainer: AppPalette.primary16,
      onTertiaryContainer: AppPalette.gray900,

      error: AppPalette.errorMain,
      onError: AppPalette.white,
      errorContainer: AppPalette.error24,
      onErrorContainer: AppPalette.gray900,
      outlineVariant: AppPalette.gray400,
      shadow: AppPalette.black,
      scrim: AppPalette.black,
      surfaceTint: AppPalette.secondaryMain,
      shadowColor: AppPalette.black.withValues(alpha: 0.2),
      bgPage: AppPalette.gray100,
      bgCard: AppPalette.white,
      bgElevated: AppPalette.gray50,
      bgElevated2: AppPalette.gray200,
      bgNeutral: AppPalette.gray100,
      bgInverse: AppPalette.gray900,
      textPrimary: AppPalette.gray900,
      textSecondary: AppPalette.gray700,
      textMuted: AppPalette.gray500,
      textOnPrimary: AppPalette.white,
      textOnAccent: AppPalette.white,
      borderSubtle: AppPalette.gray200,
      borderFocus: AppPalette.primaryMain,
      dividerSubtle: AppPalette.gray200,
      stateError: AppPalette.errorMain,
      logo: AppPalette.primaryMain,
      // Toast
      primaryToastError: AppPalette.white,
      secondaryToastError: AppPalette.errorMain,
      // Avatar
      avatarBg: AppPalette.gray300,
      avatarFg: AppPalette.gray600,
      // Status chips / badges
      statusSuccessBg: AppPalette.success16,
      statusSuccessFg: AppPalette.successDark,
      statusWarningBg: AppPalette.warning16,
      statusWarningFg: AppPalette.warningDark,
      statusErrorBg: AppPalette.error16,
      statusErrorFg: AppPalette.errorDark,
      statusInfoBg: AppPalette.info16,
      statusInfoFg: AppPalette.infoDark,
      statusNeutralBg: AppPalette.gray200,
      statusNeutralFg: AppPalette.gray700,
      // Icons
      iconAction: AppPalette.gray700,
      iconSubtle: AppPalette.gray400,
    );
  }

  factory AppColors.dark() {
    return AppColors(
      primary: AppPalette.secondaryLight,
      primaryContainer: AppPalette.secondary32,
      onPrimaryContainer: AppPalette.gray50,
      secondary: AppPalette.primaryLighter,
      onSecondary: AppPalette.gray900,
      secondaryContainer: AppPalette.primary32,
      onSecondaryContainer: AppPalette.gray50,
      tertiary: AppPalette.secondary40,
      onTertiary: AppPalette.gray900,
      tertiaryContainer: AppPalette.secondary24,
      onTertiaryContainer: AppPalette.gray50,

      error: AppPalette.errorLight,
      onError: AppPalette.gray900,
      errorContainer: AppPalette.error32,
      onErrorContainer: AppPalette.gray50,
      outlineVariant: AppPalette.gray500,
      shadow: AppPalette.black,
      scrim: AppPalette.black,
      surfaceTint: AppPalette.secondaryLight,
      shadowColor: AppPalette.white.withValues(alpha: 0.2),
      bgPage: AppPalette.gray900,
      bgCard: AppPalette.gray800,
      bgElevated: AppPalette.gray800,
      bgElevated2: AppPalette.gray72,
      bgNeutral: AppPalette.gray800,
      bgInverse: AppPalette.gray50,
      textPrimary: AppPalette.gray50,
      textSecondary: AppPalette.gray200,
      textMuted: AppPalette.gray400,
      textOnPrimary: AppPalette.gray900,
      textOnAccent: AppPalette.gray900,
      borderSubtle: AppPalette.gray700,
      borderFocus: AppPalette.primaryLight,
      dividerSubtle: AppPalette.gray700,
      stateError: AppPalette.errorLight,
      logo: AppPalette.white,
      // Toast
      primaryToastError: AppPalette.primaryMain,
      secondaryToastError: AppPalette.errorLight,
      // Avatar
      avatarBg: AppPalette.gray700,
      avatarFg: AppPalette.gray300,
      // Status chips / badges
      statusSuccessBg: AppPalette.success32,
      statusSuccessFg: AppPalette.successLighter,
      statusWarningBg: AppPalette.warning32,
      statusWarningFg: AppPalette.warningLighter,
      statusErrorBg: AppPalette.error32,
      statusErrorFg: AppPalette.errorLighter,
      statusInfoBg: AppPalette.info32,
      statusInfoFg: AppPalette.infoLighter,
      statusNeutralBg: AppPalette.gray700,
      statusNeutralFg: AppPalette.gray200,
      // Icons
      iconAction: AppPalette.gray300,
      iconSubtle: AppPalette.gray500,
    );
  }

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? outlineVariant,
    Color? shadow,
    Color? scrim,
    Color? surfaceTint,
    Color? shadowColor,
    Color? bgPage,
    Color? bgCard,
    Color? bgElevated,
    Color? bgElevated2,
    Color? bgNeutral,
    Color? bgInverse,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textOnPrimary,
    Color? textOnAccent,
    Color? borderSubtle,
    Color? borderFocus,
    Color? dividerSubtle,
    Color? stateError,
    Color? logo,
    // Toast
    Color? primaryToastError,
    Color? secondaryToastError,
    // Avatar
    Color? avatarBg,
    Color? avatarFg,
    // Status
    Color? statusSuccessBg,
    Color? statusSuccessFg,
    Color? statusWarningBg,
    Color? statusWarningFg,
    Color? statusErrorBg,
    Color? statusErrorFg,
    Color? statusInfoBg,
    Color? statusInfoFg,
    Color? statusNeutralBg,
    Color? statusNeutralFg,
    // Icons
    Color? iconAction,
    Color? iconSubtle,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      shadowColor: shadowColor ?? this.shadowColor,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      onTertiary: onTertiary ?? this.onTertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      stateError: stateError ?? this.stateError,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      bgPage: bgPage ?? this.bgPage,
      bgCard: bgCard ?? this.bgCard,
      bgElevated: bgElevated ?? this.bgElevated,
      bgElevated2: bgElevated2 ?? this.bgElevated2,
      bgNeutral: bgNeutral ?? this.bgNeutral,
      bgInverse: bgInverse ?? this.bgInverse,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderFocus: borderFocus ?? this.borderFocus,
      dividerSubtle: dividerSubtle ?? this.dividerSubtle,
      logo: logo ?? this.logo,
      primaryToastError: primaryToastError ?? this.primaryToastError,
      secondaryToastError: secondaryToastError ?? this.secondaryToastError,
      avatarBg: avatarBg ?? this.avatarBg,
      avatarFg: avatarFg ?? this.avatarFg,
      statusSuccessBg: statusSuccessBg ?? this.statusSuccessBg,
      statusSuccessFg: statusSuccessFg ?? this.statusSuccessFg,
      statusWarningBg: statusWarningBg ?? this.statusWarningBg,
      statusWarningFg: statusWarningFg ?? this.statusWarningFg,
      statusErrorBg: statusErrorBg ?? this.statusErrorBg,
      statusErrorFg: statusErrorFg ?? this.statusErrorFg,
      statusInfoBg: statusInfoBg ?? this.statusInfoBg,
      statusInfoFg: statusInfoFg ?? this.statusInfoFg,
      statusNeutralBg: statusNeutralBg ?? this.statusNeutralBg,
      statusNeutralFg: statusNeutralFg ?? this.statusNeutralFg,
      iconAction: iconAction ?? this.iconAction,
      iconSubtle: iconSubtle ?? this.iconSubtle,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      onPrimaryContainer: Color.lerp(
        onPrimaryContainer,
        other.onPrimaryContainer,
        t,
      )!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      secondaryContainer: Color.lerp(
        secondaryContainer,
        other.secondaryContainer,
        t,
      )!,
      onSecondaryContainer: Color.lerp(
        onSecondaryContainer,
        other.onSecondaryContainer,
        t,
      )!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      onTertiary: Color.lerp(onTertiary, other.onTertiary, t)!,
      tertiaryContainer: Color.lerp(tertiaryContainer, other.tertiaryContainer, t)!,
      onTertiaryContainer: Color.lerp(onTertiaryContainer, other.onTertiaryContainer, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(
        onErrorContainer,
        other.onErrorContainer,
        t,
      )!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      bgPage: Color.lerp(bgPage, other.bgPage, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      bgElevated2: Color.lerp(bgElevated2, other.bgElevated2, t)!,
      bgNeutral: Color.lerp(bgNeutral, other.bgNeutral, t)!,
      bgInverse: Color.lerp(bgInverse, other.bgInverse, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      dividerSubtle: Color.lerp(dividerSubtle, other.dividerSubtle, t)!,
      stateError: Color.lerp(stateError, other.stateError, t)!,
      logo: Color.lerp(logo, other.logo, t)!,
      // Toast
      primaryToastError: Color.lerp(primaryToastError, other.primaryToastError, t)!,
      secondaryToastError: Color.lerp(secondaryToastError, other.secondaryToastError, t)!,
      // Avatar
      avatarBg: Color.lerp(avatarBg, other.avatarBg, t)!,
      avatarFg: Color.lerp(avatarFg, other.avatarFg, t)!,
      // Status
      statusSuccessBg: Color.lerp(statusSuccessBg, other.statusSuccessBg, t)!,
      statusSuccessFg: Color.lerp(statusSuccessFg, other.statusSuccessFg, t)!,
      statusWarningBg: Color.lerp(statusWarningBg, other.statusWarningBg, t)!,
      statusWarningFg: Color.lerp(statusWarningFg, other.statusWarningFg, t)!,
      statusErrorBg: Color.lerp(statusErrorBg, other.statusErrorBg, t)!,
      statusErrorFg: Color.lerp(statusErrorFg, other.statusErrorFg, t)!,
      statusInfoBg: Color.lerp(statusInfoBg, other.statusInfoBg, t)!,
      statusInfoFg: Color.lerp(statusInfoFg, other.statusInfoFg, t)!,
      statusNeutralBg: Color.lerp(statusNeutralBg, other.statusNeutralBg, t)!,
      statusNeutralFg: Color.lerp(statusNeutralFg, other.statusNeutralFg, t)!,
      // Icons
      iconAction: Color.lerp(iconAction, other.iconAction, t)!,
      iconSubtle: Color.lerp(iconSubtle, other.iconSubtle, t)!,
    );
  }
}
