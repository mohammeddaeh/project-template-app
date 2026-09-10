import 'package:flutter/widgets.dart';

import 'package:app_template/ui/responsive/responsive_scope.dart';
import 'package:app_template/ui/responsive/screen_metrics.dart';

/// المدخل القصير إلى [ScreenMetrics] من أي `build`.
///
/// ```dart
/// final s = context.screen;
/// SizedBox(height: s.space(24));
/// Padding(padding: EdgeInsets.symmetric(horizontal: s.gutter));
/// ```
///
/// **وهذه لا تُغني عن `context.sw`/`context.sh`** بل تحلّ محلّهما بالتخطيط:
/// النسبة المئوية من الشاشة رقمٌ لا يعرف الكيبورد ولا اتجاه الجهاز، أمّا
/// [ScreenMetrics.space] فمقاسُ التصميم نفسه محمولاً إلى شاشةٍ أخرى.
extension ResponsiveContextX on BuildContext {
  ScreenMetrics get screen => ResponsiveScope.of(this);

  /// جهازٌ لوحيّ — بأي اتجاه.
  bool get isTablet => screen.isTablet;

  /// الهامش الأفقي القياسي للصفحة.
  double get gutter => screen.gutter;

  /// مسافةٌ من التصميم محمولةً إلى هذه الشاشة.
  double rSpace(double base) => screen.space(base);

  /// مقاسٌ من التصميم محمولاً إلى هذه الشاشة.
  double rSize(double base) => screen.size(base);
}
