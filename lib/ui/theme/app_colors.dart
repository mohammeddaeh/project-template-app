import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/app_palette.g.dart';

/// كم يُرى من [AppColors.bgTranslucent] — وما بقي (١٠٪) للمحتوى تحته.
///
/// ٠٫٩ لا أقلّ: فوق أسوأ خلفيةٍ (أسود تحت الفاتح، أبيض تحت الداكن) يبقى
/// النصُّ عليه بتباين ٤٫٥:١ — `test/color_contrast_test.dart` يفحصه لكل بالت.
const _translucency = 0.9;

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
    required this.bgTranslucent,
    required this.bgNeutral,
    required this.bgInverse,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnPrimary,
    required this.textOnAccent,
    required this.bgDisabled,
    required this.textDisabled,
    required this.bgBrand,
    required this.feedbackSuccess,
    required this.feedbackError,
    required this.feedbackWarning,
    required this.feedbackInfo,
    required this.onBrand,
    required this.onBrandAccent,
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

  /// [bgCard] نافذاً قليلاً — لسطحٍ يمرّ المحتوى تحته (الشريط السفلي فوق
  /// القائمة). لونٌ بلا تمويه: يبقى ثابتاً فيُفحص تباينُه، ولا يكلّف إطاراً.
  final Color bgTranslucent;
  final Color bgNeutral;
  final Color bgInverse;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnPrimary;
  final Color textOnAccent;

  /// أرضيةُ عنصرٍ حاضرٍ **غيرِ متاح**.
  ///
  /// **سطحٌ حقيقيّ، لا اللونُ المتاحُ بشفافية.** تخفيفُ `primary` إلى ٤٠٪ فوق
  /// أبيضَ ينتج `#A8BFD6`، والأبيضُ عليه يقيس **١٫٩١:١** — لافتةُ زرٍّ معطَّل
  /// **غيرُ مقروءة**، بلوحة القالب نفسِها، وبأوّل شاشة.
  ///
  /// والشفافيةُ تبدو **حالةً معطَّلة** لمن يكتبها و**عطلَ رسمٍ** لمن يقرأها —
  /// ولا يمسكها `dart analyze` ولا اختبار: كلاهما لونٌ صالح.
  final Color bgDisabled;

  /// لافتةٌ فوق [bgDisabled] — **٦٫٥٩:١** بالوضعين. خافتةٌ وتُقرأ.
  final Color textDisabled;

  /// المحتوى فوق **سطح العلامة** — الشاشة المطلية بلون الهوية (دخول · سبلاش ·
  /// ترويسة ملوّنة). و`primary` **لا ينوب عنه**: ذاك ينقلب مع الوضع، وسطحُ
  /// العلامة لا ينقلب — فيصير النصُّ فوقه غيرَ مقروء بأحد الوضعين.
  ///
  final Color onBrand;

  /// **سطح العلامة** نفسُه — لا ينقلب مع الوضع، ويطابق `splash_background`
  /// بأندرويد و`color` بـ`flutter_native_splash.yaml`، فلا وميضَ بين الإقلاع
  /// وأوّل شاشةٍ مطليّة بالهوية (الترحيب).
  final Color bgBrand;

  /// لمسةُ رسالة التنبيه (`context.feedback.*`) — شريطُها وأيقونتها. لا تنقلب مع
  /// الوضع: الرسالة تطفو فوق أي سطح، ولونُها معناها.
  final Color feedbackSuccess;
  final Color feedbackError;
  final Color feedbackWarning;
  final Color feedbackInfo;

  /// اللمسةُ المميِّزة فوق سطح العلامة — تقدُّمٌ, أو قيمةٌ تُبرَز.
  final Color onBrandAccent;
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

  /// الربطُ نفسُه لكل بالت — بالتٌ جديدة بـ`palettes/` تمرّ من هنا كما هي.
  factory AppColors.light(AppPalette p) {
    return AppColors(
      primary: p.primaryMain,
      primaryContainer: p.secondary24,
      onPrimaryContainer: p.gray900,
      secondary: p.secondaryMain,
      onSecondary: p.white,
      secondaryContainer: p.primary24,
      onSecondaryContainer: p.gray900,
      tertiary: p.primary40,
      onTertiary: p.gray900,
      tertiaryContainer: p.primary16,
      onTertiaryContainer: p.gray900,

      error: p.errorMain,
      onError: p.white,
      errorContainer: p.error24,
      onErrorContainer: p.gray900,
      outlineVariant: p.gray400,
      shadow: p.black,
      scrim: p.black,
      surfaceTint: p.secondaryMain,
      shadowColor: p.black.withValues(alpha: 0.2),
      bgPage: p.gray100,
      bgCard: p.white,
      bgElevated: p.gray50,
      bgElevated2: p.gray200,
      bgTranslucent: p.white.withValues(alpha: _translucency),
      bgNeutral: p.gray100,
      bgInverse: p.gray900,
      textPrimary: p.gray900,
      textSecondary: p.gray700,
      textMuted: p.gray500,
      textOnPrimary: p.white,
      textOnAccent: p.white,
      bgDisabled: p.gray300,
      textDisabled: p.gray700, // 6.59:1 over bgDisabled
      bgBrand: p.brandSurface,
      feedbackSuccess: p.successMain,
      feedbackError: p.errorMain,
      feedbackWarning: p.warningMain,
      feedbackInfo: p.infoMain,
      onBrand: p.white,
      onBrandAccent: p.secondaryMain,
      borderSubtle: p.gray200,
      borderFocus: p.primaryMain,
      dividerSubtle: p.gray200,
      stateError: p.errorMain,
      logo: p.primaryMain,
      // Toast
      primaryToastError: p.white,
      secondaryToastError: p.errorMain,
      // Avatar
      avatarBg: p.gray300,
      avatarFg: p.gray600,
      // Status chips / badges
      statusSuccessBg: p.success16,
      statusSuccessFg: p.successDarker, // 6.79:1 over success16
      statusWarningBg: p.warning16,
      statusWarningFg: p.warningDarker, // 6.34:1 over warning16
      statusErrorBg: p.error16,
      statusErrorFg: p.errorDark,
      statusInfoBg: p.info16,
      statusInfoFg: p.infoDark,
      statusNeutralBg: p.gray200,
      statusNeutralFg: p.gray700,
      // Icons
      iconAction: p.gray700,
      iconSubtle: p.gray400,
    );
  }

  factory AppColors.dark(AppPalette p) {
    return AppColors(
      primary: p.secondaryLight,
      primaryContainer: p.secondary32,
      onPrimaryContainer: p.gray900,
      secondary: p.primaryLighter,
      onSecondary: p.gray900,
      secondaryContainer: p.primary32,
      onSecondaryContainer: p.gray900,
      tertiary: p.secondary40,
      onTertiary: p.gray900,
      tertiaryContainer: p.secondary24,
      onTertiaryContainer: p.gray50,

      error: p.errorLight,
      onError: p.gray900,
      errorContainer: p.error32,
      onErrorContainer: p.gray50,
      outlineVariant: p.gray500,
      shadow: p.black,
      scrim: p.black,
      surfaceTint: p.secondaryLight,
      shadowColor: p.white.withValues(alpha: 0.2),
      bgPage: p.gray900,
      bgCard: p.gray800,
      bgElevated: p.gray800,
      bgElevated2: p.gray72,
      bgTranslucent: p.gray800.withValues(alpha: _translucency),
      bgNeutral: p.gray800,
      bgInverse: p.gray50,
      textPrimary: p.gray50,
      textSecondary: p.gray200,
      textMuted: p.gray400,
      textOnPrimary: p.gray900,
      textOnAccent: p.gray900,
      bgDisabled: p.gray700,
      textDisabled: p.gray300, // 6.59:1 over bgDisabled
      bgBrand: p.brandSurface,
      feedbackSuccess: p.successMain,
      feedbackError: p.errorMain,
      feedbackWarning: p.warningMain,
      feedbackInfo: p.infoMain,
      onBrand: p.white,
      onBrandAccent: p.secondaryMain,
      borderSubtle: p.gray700,
      borderFocus: p.primaryLight,
      dividerSubtle: p.gray700,
      stateError: p.errorLight,
      logo: p.white,
      // Toast
      primaryToastError: p.primaryMain,
      secondaryToastError: p.errorLight,
      // Avatar
      avatarBg: p.gray700,
      avatarFg: p.gray300,
      // Status chips / badges
      statusSuccessBg: p.success32,
      statusSuccessFg: p.successDarker, // 6.11:1 over success32
      statusWarningBg: p.warning32,
      statusWarningFg: p.warningDarker, // 4.87:1 over warning32
      statusErrorBg: p.error32,
      statusErrorFg: p.errorDarker, // 6.13:1 over error32
      statusInfoBg: p.info32,
      statusInfoFg: p.infoDarker, // 7.82:1 over info32
      statusNeutralBg: p.gray700,
      statusNeutralFg: p.gray200,
      // Icons
      iconAction: p.gray300,
      iconSubtle: p.gray500,
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
    Color? bgTranslucent,
    Color? bgNeutral,
    Color? bgInverse,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textOnPrimary,
    Color? textOnAccent,
    Color? bgDisabled,
    Color? textDisabled,
    Color? bgBrand,
    Color? feedbackSuccess,
    Color? feedbackError,
    Color? feedbackWarning,
    Color? feedbackInfo,
    Color? onBrand,
    Color? onBrandAccent,
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
      bgTranslucent: bgTranslucent ?? this.bgTranslucent,
      bgNeutral: bgNeutral ?? this.bgNeutral,
      bgInverse: bgInverse ?? this.bgInverse,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      bgDisabled: bgDisabled ?? this.bgDisabled,
      textDisabled: textDisabled ?? this.textDisabled,
      bgBrand: bgBrand ?? this.bgBrand,
      feedbackSuccess: feedbackSuccess ?? this.feedbackSuccess,
      feedbackError: feedbackError ?? this.feedbackError,
      feedbackWarning: feedbackWarning ?? this.feedbackWarning,
      feedbackInfo: feedbackInfo ?? this.feedbackInfo,
      onBrand: onBrand ?? this.onBrand,
      onBrandAccent: onBrandAccent ?? this.onBrandAccent,
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
      tertiaryContainer: Color.lerp(
        tertiaryContainer,
        other.tertiaryContainer,
        t,
      )!,
      onTertiaryContainer: Color.lerp(
        onTertiaryContainer,
        other.onTertiaryContainer,
        t,
      )!,
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
      bgTranslucent: Color.lerp(bgTranslucent, other.bgTranslucent, t)!,
      bgNeutral: Color.lerp(bgNeutral, other.bgNeutral, t)!,
      bgInverse: Color.lerp(bgInverse, other.bgInverse, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      bgDisabled: Color.lerp(bgDisabled, other.bgDisabled, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      bgBrand: Color.lerp(bgBrand, other.bgBrand, t)!,
      feedbackSuccess: Color.lerp(feedbackSuccess, other.feedbackSuccess, t)!,
      feedbackError: Color.lerp(feedbackError, other.feedbackError, t)!,
      feedbackWarning: Color.lerp(feedbackWarning, other.feedbackWarning, t)!,
      feedbackInfo: Color.lerp(feedbackInfo, other.feedbackInfo, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      onBrandAccent: Color.lerp(onBrandAccent, other.onBrandAccent, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      dividerSubtle: Color.lerp(dividerSubtle, other.dividerSubtle, t)!,
      stateError: Color.lerp(stateError, other.stateError, t)!,
      logo: Color.lerp(logo, other.logo, t)!,
      // Toast
      primaryToastError: Color.lerp(
        primaryToastError,
        other.primaryToastError,
        t,
      )!,
      secondaryToastError: Color.lerp(
        secondaryToastError,
        other.secondaryToastError,
        t,
      )!,
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
