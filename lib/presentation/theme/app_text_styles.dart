import 'package:flutter/material.dart';
import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

// ── Usage ─────────────────────────────────────────────────────────────────────
//
//   Text('Hello', style: context.ts.headlineLg)
//   Text('Muted', style: context.ts.bodySm.muted(context))
//   Text('Custom', style: context.ts.titleMd.copyWith(color: Colors.red))
//
// ─────────────────────────────────────────────────────────────────────────────

extension AppTextStylesX on BuildContext {
  AppTextStyles get ts => AppTextStyles._(this);
}

/// Semantic typography system.
///
/// Access via `context.ts` — all styles automatically use the correct
/// font family (NotoSansArabic for Arabic locale, NotoSans otherwise)
/// and inherit theme-appropriate default colors.
class AppTextStyles {
  const AppTextStyles._(this._ctx);

  final BuildContext _ctx;

  // ── Font family ─────────────────────────────────────────────────────────────

  String get _font =>
      Theme.of(_ctx).textTheme.bodyMedium?.fontFamily ??
      AppFonts.byKey(AppFonts.defaultKey).latinFamily;

  TextTheme get _tt => Theme.of(_ctx).textTheme;

  // ── Display — hero text, marketing, large numbers ──────────────────────────

  /// 57px / w400 — splash hero, marketing screens
  TextStyle get displayLg => _tt.displayLarge!.copyWith(fontFamily: _font);

  /// 45px / w400 — section heroes
  TextStyle get displayMd => _tt.displayMedium!.copyWith(fontFamily: _font);

  /// 36px / w400 — card heroes, stat numbers
  TextStyle get displaySm => _tt.displaySmall!.copyWith(fontFamily: _font);

  // ── Headline — screen titles, dialog headers ───────────────────────────────

  /// 32px / w600 — screen titles
  TextStyle get headlineLg => _tt.headlineLarge!.copyWith(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
  );

  /// 28px / w600 — section headers
  TextStyle get headlineMd => _tt.headlineMedium!.copyWith(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
  );

  /// 24px / w600 — card titles, dialog titles
  TextStyle get headlineSm => _tt.headlineSmall!.copyWith(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
  );

  // ── Title — list headers, app bars, prominent labels ──────────────────────

  /// 22px / w500 — AppBar, prominent section title
  TextStyle get titleLg =>
      _tt.titleLarge!.copyWith(fontFamily: _font, fontWeight: FontWeight.w500);

  /// 16px / w500 — list tile headers, card subtitles
  TextStyle get titleMd =>
      _tt.titleMedium!.copyWith(fontFamily: _font, fontWeight: FontWeight.w500);

  /// 14px / w500 — dense list titles, form labels
  TextStyle get titleSm =>
      _tt.titleSmall!.copyWith(fontFamily: _font, fontWeight: FontWeight.w500);

  // ── Body — paragraphs, descriptions, content ──────────────────────────────

  /// 16px / w400 — primary reading content
  TextStyle get bodyLg => _tt.bodyLarge!.copyWith(fontFamily: _font);

  /// 14px / w400 — default body, list tile subtitles
  TextStyle get bodyMd => _tt.bodyMedium!.copyWith(fontFamily: _font);

  /// 12px / w400 — secondary descriptions, timestamps
  TextStyle get bodySm => _tt.bodySmall!.copyWith(fontFamily: _font);

  // ── Label — buttons, chips, badges, tags ──────────────────────────────────

  /// 14px / w500 — buttons, prominent labels
  TextStyle get labelLg =>
      _tt.labelLarge!.copyWith(fontFamily: _font, fontWeight: FontWeight.w500);

  /// 12px / w500 — chip text, input hints, tab labels
  TextStyle get labelMd =>
      _tt.labelMedium!.copyWith(fontFamily: _font, fontWeight: FontWeight.w500);

  /// 10px / w500 — badges, micro labels, timestamps in tight spaces
  TextStyle get labelSm =>
      _tt.labelSmall!.copyWith(fontFamily: _font, fontWeight: FontWeight.w500);

  // ── App-specific presets ──────────────────────────────────────────────────

  /// AppBar title — 18px / w600
  TextStyle get appBar => _tt.titleLarge!.copyWith(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  /// Buttons — 14px / w600
  TextStyle get button => _tt.labelLarge!.copyWith(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  /// Input field text — 14px / w400
  TextStyle get inputText =>
      _tt.bodyMedium!.copyWith(fontFamily: _font, fontSize: 14);

  /// Input hint — 14px / w400
  TextStyle get inputHint => _tt.bodyMedium!.copyWith(
    fontFamily: _font,
    fontSize: 14,
    color: _ctx.colors.textMuted,
  );

  /// Input label — 12px / w500
  TextStyle get inputLabel => _tt.labelMedium!.copyWith(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Caption / helper text — 11px / w400
  TextStyle get caption => _tt.bodySmall!.copyWith(
    fontFamily: _font,
    fontSize: 11,
    color: _ctx.colors.textMuted,
  );
}

// ── Color helpers — call on any TextStyle ─────────────────────────────────────
//
//   context.ts.bodyMd.secondary(context)   →  textSecondary color
//   context.ts.bodySm.muted(context)       →  textMuted color
//   context.ts.titleMd.primary(context)    →  primary brand color
//   context.ts.labelLg.error(context)      →  error color
//
// For the default (textPrimary) — just omit color entirely:
//   context.ts.headlineSm                  →  theme default = textPrimary
//
extension TextStyleSemanticColor on TextStyle {
  TextStyle secondary(BuildContext ctx) =>
      copyWith(color: ctx.colors.textSecondary);
  TextStyle muted(BuildContext ctx) => copyWith(color: ctx.colors.textMuted);
  TextStyle primary(BuildContext ctx) => copyWith(color: ctx.colors.primary);
  TextStyle error(BuildContext ctx) => copyWith(color: ctx.colors.error);
}

// ── Backward-compatible aliases on BuildContext ───────────────────────────────

extension LegacyTextStylesCompat on BuildContext {
  /// @deprecated — use `context.ts.headlineSm`
  TextStyle get headLineS24W600 => ts.headlineSm;

  /// @deprecated — use `context.ts.bodyMd`
  TextStyle get baseTextStyle => ts.bodyMd;

  /// @deprecated — use `context.ts.headlineMd`
  TextStyle get headLineMed => ts.headlineMd;

  /// @deprecated — use `context.ts.appBar`
  TextStyle get appBarStyle => ts.appBar;

  /// @deprecated — use `context.ts.bodySm`
  TextStyle get bodyNutralColorsBure => ts.bodySm;

  /// @deprecated — use `context.ts.labelSm`
  TextStyle get bodyPrimarys700 => ts.labelSm;

  /// @deprecated — use `context.ts.labelLg`
  TextStyle get labelSmallS16W400 => ts.labelLg;

  /// @deprecated — use `context.ts.labelMd`
  TextStyle get labelSmallS12W400 => ts.labelMd;
}
