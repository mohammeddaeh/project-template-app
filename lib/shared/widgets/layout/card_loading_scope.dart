import 'package:flutter/material.dart';

/// ينشر حالة "قيد التحميل" لأسفل شجرة الـwidgets — يسمح للعناصر الداخلية
/// (مثل [ShimmerText]/[AvatarWidget]) برسم نفسها كشيمر تلقائياً دون أن يمرر
/// كل عنصر حالة loading يدوياً بنفسه. يُفعَّل عبر [AppCard.isLoading] —
/// لا يُستخدم مباشرة عادةً.
class CardLoadingScope extends InheritedWidget {
  const CardLoadingScope({
    super.key,
    required this.isLoading,
    required super.child,
  });

  final bool isLoading;

  /// `false` إذا لم يوجد أي [CardLoadingScope] أعلى الشجرة (الوضع الطبيعي
  /// خارج أي بطاقة تحميل).
  static bool of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CardLoadingScope>();
    return scope?.isLoading ?? false;
  }

  @override
  bool updateShouldNotify(CardLoadingScope oldWidget) =>
      isLoading != oldWidget.isLoading;
}
