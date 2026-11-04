import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/app_colors.dart';
import 'package:app_template/ui/theme/app_palette.g.dart';
import 'package:app_template/ui/theme/app_theme_presets.g.dart';

/// ثيمٌ يختاره المستخدم — بالتٌ واحدة، ومنها الوضعان الفاتح والداكن.
///
/// **محورٌ مستقلٌّ عن الوضع**: الوضع (فاتح · داكن · النظام) يختار أيَّ نسختَي
/// الثيم تُرسم، والثيمُ يختار البالت. والربطُ من البالت إلى الأدوار
/// (`AppColors.light`/`dark`) واحدٌ لكل الثيمات، والشكل والحركة (`AppRadius` ·
/// `AppMotion`) ثابتان.
@immutable
class AppThemePreset {
  AppThemePreset({
    required this.id,
    required this.nameKey,
    required this.palette,
  }) : light = AppColors.light(palette),
       dark = AppColors.dark(palette);

  /// اسمُ ملف البالت، ويُحفظ بالتخزين — **لا يُغيَّر بعد الشحن**: معرّفٌ محفوظٌ
  /// لا يطابق ثيماً يعود بصاحبه إلى [AppThemePresets.fallback].
  final String id;

  /// مفتاح ترجمة الاسم المعروض.
  final String nameKey;

  final AppPalette palette;
  final AppColors light;
  final AppColors dark;

  AppColors colorsFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  bool operator ==(Object other) => other is AppThemePreset && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// الثيمات المتاحة — **ثيمٌ لكل ملف بـ`palettes/`**، مولَّدةً بـ
/// `dart run scripts/gen_code.dart`. لإضافة ثيم:
///   1. انسخ `palettes/standard.json` إلى `palettes/<id>.json` وبدّل الدرجات والاسم
///   2. `dart run scripts/gen_code.dart`
///   3. `flutter test test/color_contrast_test.dart` — يمرّ على كل ثيمٍ بـ[all]
///
/// **ومنتقي الثيم بالإعدادات لا يظهر ما دام [all] ثيماً واحداً.**
abstract final class AppThemePresets {
  /// `standard` أوّلاً دائماً — يضمنه المولِّد.
  static final List<AppThemePreset> all = generatedThemePresets;

  static AppThemePreset get fallback => all.first;

  static AppThemePreset byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => fallback);
}
