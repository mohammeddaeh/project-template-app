import 'package:flutter/animation.dart';

/// مدّة وcurve الحركة — صفر توكن لها قبل هذا الملف؛ كل micro-interaction
/// كانت تُبنى بقيمة مكتوبة يدوياً بلا قرار موحَّد خلفها.
abstract final class AppMotion {
  AppMotion._();

  /// ضغطة زر، تبديل chip — تفاعلٌ فوريّ يحتاج ردّاً أسرع من إدراكه كتأخير.
  static const Duration fast = Duration(milliseconds: 150);

  /// انتقال داخل نفس الشاشة — فتح/طيّ قسم، ظهور حالة جديدة.
  static const Duration base = Duration(milliseconds: 250);

  /// كشف عنصرٍ كبير — ورقة سفلية، لافتة تملأ عرض الشاشة.
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve fastCurve = Curves.easeOut;
  static const Curve baseCurve = Curves.easeInOutCubic;
  static const Curve slowCurve = Curves.easeOutCubic;
}
