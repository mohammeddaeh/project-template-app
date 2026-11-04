import 'package:flutter/widgets.dart';

import 'package:app_template/ui/responsive/responsive.dart';

/// فراغاتٌ جاهزة بمقاس التصميم — محمولةٌ إلى الشاشة كـ[ResponsiveGap].
class Spacing {
  Spacing._();

  static const Widget horizontal4 = ResponsiveGap.horizontal(4);
  static const Widget horizontal8 = ResponsiveGap.horizontal(8);
  static const Widget horizontal16 = ResponsiveGap.horizontal(16);
  static const Widget horizontal24 = ResponsiveGap.horizontal(24);

  static const Widget vertical4 = ResponsiveGap(4);
  static const Widget vertical8 = ResponsiveGap(8);
  static const Widget vertical12 = ResponsiveGap(12);
  static const Widget vertical16 = ResponsiveGap(16);
  static const Widget vertical24 = ResponsiveGap(24);
}
