import 'package:flutter/material.dart';

/// ظلال presets — [AppColors.shadowColor] موجودٌ أصلاً بالثيم (يختلف بين
/// الوضعين الفاتح والداكن) لكن بلا مستهلك: كل مكوّن بالثيم الحالي
/// `elevation: 0` (`CardThemeData`, `elevatedButtonTheme`, `AppCard`)، فالتطبيق
/// مسطّحٌ كلياً بأثر افتراضات `useMaterial3: false` لا بقرارٍ واعٍ.
///
/// يأخذ اللون بدل قراءته داخلياً لأنه يختلف بالوضعين — نفس نمط
/// `AppElevation.sm(context.colors.shadowColor)` بموضع الاستدعاء.
abstract final class AppElevation {
  AppElevation._();

  static const List<BoxShadow> none = [];

  /// بطاقة قائمة عادية — تفصلها عن الخلفية بلا لفت نظر.
  static List<BoxShadow> sm(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// عنصرٌ عائم — رأسٌ ملوّن، بطاقةٌ مُبرَزة عن محيطها.
  static List<BoxShadow> md(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.10),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// ورقة سفلية، بطاقة hero — أعلى طبقة بالشاشة.
  static List<BoxShadow> lg(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.14),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
