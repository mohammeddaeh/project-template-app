import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/ui/theme/app_colors.dart';
import 'package:app_template/ui/theme/app_theme_presets.dart';

/// **بوابةُ التباين (F07)** — كلُّ زوج (نصّ · خلفية) يمرّ بها.
///
/// وهذا ما لا يمسكه شيءٌ آخر: لونٌ رديء **يُصرَّف ويُرسم**، و`dart analyze` نظيف،
/// ولا اختبارَ تخطيطٍ يشكو. ولا يكتشفه إلا من يقرأ الشاشة — أو هذا الملف.
double _relativeLuminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  /// ٤٫٥:١ للنصّ العاديّ — WCAG 2.1 AA.
  const bodyText = 4.5;

  // كلُّ بالتٍ بالوضعين — ملفٌّ يُضاف إلى `palettes/` يمرّ من هنا تلقائياً.
  final themes = <String, AppColors>{
    for (final preset in AppThemePresets.all) ...{
      '${preset.id}/light': preset.light,
      '${preset.id}/dark': preset.dark,
    },
  };

  themes.forEach((name, c) {
    group(name, () {
      test('a disabled label is readable on its own ground', () {
        // **العطلُ الذي وُلد منه هذا الاختبار**: كان الزرُّ المعطَّل يُرسم
        // `primary.withValues(alpha: 0.4)` فوق أبيض — والأبيضُ عليه **١٫٩١:١**.
        // والشفافيةُ تبدو حالةً معطَّلة لمن يكتبها وعطلَ رسمٍ لمن يقرأها.
        expect(
          contrast(c.textDisabled, c.bgDisabled),
          greaterThanOrEqualTo(bodyText),
          reason: 'textDisabled on bgDisabled',
        );
      });

      test('primary text is readable on the page and on cards', () {
        expect(
          contrast(c.textPrimary, c.bgPage),
          greaterThanOrEqualTo(bodyText),
        );
        expect(
          contrast(c.textPrimary, c.bgCard),
          greaterThanOrEqualTo(bodyText),
        );
      });

      test('every status foreground is readable on its own background', () {
        final pairs = {
          'success': [c.statusSuccessFg, c.statusSuccessBg],
          'warning': [c.statusWarningFg, c.statusWarningBg],
          'error': [c.statusErrorFg, c.statusErrorBg],
          'info': [c.statusInfoFg, c.statusInfoBg],
          'neutral': [c.statusNeutralFg, c.statusNeutralBg],
        };

        pairs.forEach((label, p) {
          expect(
            contrast(p[0], p[1]),
            greaterThanOrEqualTo(bodyText),
            reason: '$label foreground on $label background',
          );
        });
      });

      test('primary reads as text, and its label reads on it', () {
        expect(
          contrast(c.primary, c.bgPage),
          greaterThanOrEqualTo(bodyText),
          reason: 'primary on bgPage',
        );
        expect(
          contrast(c.primary, c.bgCard),
          greaterThanOrEqualTo(bodyText),
          reason: 'primary on bgCard',
        );
        expect(
          contrast(c.textOnAccent, c.primary),
          greaterThanOrEqualTo(bodyText),
          reason: 'textOnAccent on primary',
        );
      });

      test('an idle tab reads on every surface a bar draws', () {
        // Bottom bar, tab bar: the labels a user scans to find a tab. Muted
        // grey reads as a design choice and measures well under 4.5:1.
        final grounds = {
          'bgCard': c.bgCard,
          'bgElevated': c.bgElevated,
          for (final under in [Colors.black, Colors.white])
            'bgTranslucent over $under': Color.alphaBlend(
              c.bgTranslucent,
              under,
            ),
        };
        grounds.forEach((label, ground) {
          expect(
            contrast(c.textSecondary, ground),
            greaterThanOrEqualTo(bodyText),
            reason: 'textSecondary on $label',
          );
        });
      });

      test('text stays readable on the translucent surface over anything', () {
        // What shows through is unknown — a photo, a dark card, a white one —
        // so it is checked against both extremes. Between them, the composite
        // only gets closer to the surface itself.
        for (final under in [Colors.black, Colors.white]) {
          final ground = Color.alphaBlend(c.bgTranslucent, under);
          expect(
            contrast(c.textPrimary, ground),
            greaterThanOrEqualTo(bodyText),
            reason: 'textPrimary on bgTranslucent over $under',
          );
        }
      });

      test('a label on a tonal container is readable', () {
        // Tonal buttons, the selected tab, chips: on* over *Container.
        expect(
          contrast(c.onPrimaryContainer, c.primaryContainer),
          greaterThanOrEqualTo(bodyText),
          reason: 'onPrimaryContainer on primaryContainer',
        );
        expect(
          contrast(c.onSecondaryContainer, c.secondaryContainer),
          greaterThanOrEqualTo(bodyText),
          reason: 'onSecondaryContainer on secondaryContainer',
        );
      });
    });
  });

  test('no bar draws its idle tabs in textMuted', () {
    // The pair above holds only if the bars use it: one textMuted left in a
    // style brings the unreadable label back with every test still green.
    for (final path in [
      'lib/ui/widgets/navigation/app_bottom_bar.dart',
      'lib/ui/widgets/navigation/app_tab_bar.dart',
    ]) {
      expect(
        File(path).readAsStringSync().contains('textMuted'),
        isFalse,
        reason: path,
      );
    }
  });
}
