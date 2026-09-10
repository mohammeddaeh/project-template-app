import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'package:app_template/ui/responsive/screen_metrics.dart';

/// **الهاتف عموديٌّ وحده، واللوح بالاتجاهين.**
///
/// ## لماذا لا يكفي قفلُ الجميع عمودياً
///
/// كان `main.dart` يقفل `portraitUp | portraitDown` للجميع. وأثرُه على اللوح
/// **ليس** أن التطبيق يبقى عمودياً: أندرويد يحبس النشاطَ المقفول داخل نافذةٍ
/// بنسبة هاتف وسطَ الشاشة، ويملأ ما حولها بالأسود — فلوحٌ بعرض ٢٥٦٠ يعرض
/// التطبيق بعرض ٩٤٠ بشريطَين أسودَين. **وهذا لا يُصلحه أيُّ تخطيطٍ بالداخل**:
/// النافذة نفسها هي المقصوصة.
///
/// ## ولماذا يبقى الهاتف مقفولاً
///
/// شاشةُ هاتفٍ مستلقية ارتفاعُها ~٣٦٠ بكسل، ومع كيبوردٍ مفتوح يبقى ~١٥٠:
/// استمارةٌ بعدّة حقول لا تُملأ هناك بحال. والاستلقاءُ على الهاتف كسبٌ ضئيل
/// مقابل مراجعةِ كلِّ شاشةٍ بارتفاعٍ نصف — الفتحُ للّوح وحده هو ما تفعله
/// تطبيقات جوجل نفسها.
///
/// ⚠️ **وهذا افتراضُ القالب لا قانون**: تطبيقٌ محتواه أفقيّ بطبعه (مشغّلُ فيديو,
/// معرضُ صور, لوحُ قيادة) يبدّل [_portraitOnly] إلى [_unrestricted] — **بموضعٍ
/// واحد هنا**، لا بـ`setPreferredOrientations` بشاشة.
///
/// ## القرار مرّتان — وكلتاهما ضرورية
///
/// | متى | لماذا |
/// |---|---|
/// | [applyAtStartup] بـ`main()` | قبل أول إطار، فلا يظهر اللوح محبوساً ثم يتّسع |
/// | [applyFor] من `ResponsiveScope` | `physicalSize` **قد تكون صفراً** قبل أول إطارٍ على بعض الأجهزة، وحينها تسقط البداية إلى «اقفل» احتياطاً. وهذا التصحيح يقع بأول تخطيطٍ حقيقيّ بـ`MediaQuery` |
abstract final class OrientationPolicy {
  const OrientationPolicy._();

  static const List<DeviceOrientation> _portraitOnly = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];

  /// قائمةٌ فارغة = بلا قيد. أوضحُ من تعداد الأربعة، ونفسُ الأثر.
  static const List<DeviceOrientation> _unrestricted = <DeviceOrientation>[];

  /// آخرُ ما طُبِّق — كي لا يُنادى النظام بكل إعادة بناء بنفس القرار.
  static bool? _lastAllowsLandscape;

  /// أفضلُ تخمينٍ ممكن قبل أول إطار. يُنادى من `main()`.
  static Future<void> applyAtStartup() {
    final view = ui.PlatformDispatcher.instance.implicitView;
    final ratio = view?.devicePixelRatio ?? 0;
    final physical = view?.physicalSize ?? Size.zero;
    // المقاس صفرٌ قبل أول إطارٍ أحياناً — والقسمة عليه تعطي `NaN`. فالسقوط
    // إلى «اقفل» احتياطاً: الهواتف أغلبيةٌ ساحقة، و`ResponsiveScope` يصحّح
    // اللوح بأول تخطيط.
    final logicalShortest = (ratio > 0 && !physical.isEmpty)
        ? (physical / ratio).shortestSide
        : 0.0;
    return applyFor(
      allowsLandscape: logicalShortest >= ScreenMetrics.tabletShortestSide,
    );
  }

  /// يطبّق السياسة، ويتجاهل النداء إن كان القرار هو نفسه آخر مرّة.
  static Future<void> applyFor({required bool allowsLandscape}) {
    if (_lastAllowsLandscape == allowsLandscape) return Future.value();
    _lastAllowsLandscape = allowsLandscape;
    return SystemChrome.setPreferredOrientations(
      allowsLandscape ? _unrestricted : _portraitOnly,
    );
  }
}
