import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/ui/theme/app_colors.dart';

/// **بوابةُ التباين (F07)** — كلُّ زوج (نصّ · خلفية) يمرّ بها.
///
/// وهذا ما لا يمسكه شيءٌ آخر: لونٌ رديء **يُصرَّف ويُرسم**، و`dart analyze` نظيف،
/// ولا اختبارَ تخطيطٍ يشكو. ولا يكتشفه إلا من يقرأ الشاشة — أو هذا الملف.
double _relativeLuminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;

  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
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

  final themes = {'light': AppColors.light(), 'dark': AppColors.dark()};

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
        expect(contrast(c.textPrimary, c.bgPage), greaterThanOrEqualTo(bodyText));
        expect(contrast(c.textPrimary, c.bgCard), greaterThanOrEqualTo(bodyText));
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
    });
  });
}
