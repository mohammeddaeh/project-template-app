import 'package:flutter/material.dart';

/// نموذج تبويب واحد في شريط التنقل السفلي.
///
/// - [labelKey]        مفتاح الترجمة (LocaleKeys.xxx)
/// - [badgeCount]      null = بدون badge ، صفر = نقطة فقط ، أكبر = رقم
/// - [isVisible]       إخفاء التبويب حسب الـ role دون إزالته من القائمة
/// - [scrollController] تمريره لشاشة التبويب يُتيح scroll-to-top عند الضغط مرتين
class NavItem {
  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
    required this.screenBuilder,
    this.badgeCount,
    this.isVisible = true,
    this.scrollController,
  });

  final IconData icon;
  final IconData activeIcon;

  /// مفتاح LocaleKeys — يُحوَّل لنص داخل الـ widget بـ .tr()
  final String labelKey;

  final Widget Function() screenBuilder;

  /// null → لا badge  |  0 → نقطة فقط  |  n > 0 → رقم
  final int? badgeCount;

  /// false → التبويب مخفي (لا يظهر في الشريط)
  final bool isVisible;

  /// اختياري — يُمرَّر للشاشة لتفعيل scroll-to-top عند الضغط مرتين
  final ScrollController? scrollController;
}
