import 'package:flutter/material.dart';

import 'package:app_template/ui/responsive/orientation_policy.dart';
import 'package:app_template/ui/responsive/screen_metrics.dart';

/// يحسب [ScreenMetrics] **مرّةً واحدة فوق كل الشاشات**، ويقيّد تكبير الخط.
///
/// يُركَّب بـ`builder:` الخاص بـ`MaterialApp.router` — أي فوق كل مسار مُوجَّه
/// وكل حوارٍ وكل ورقةٍ سفلية. وهذا موضعه الوحيد: نسخةٌ ثانية بشاشةٍ ما تعني
/// مقياسَين مختلفَين بنفس التطبيق.
///
/// ## ولماذا تقييد تكبير الخط هنا
///
/// إعدادُ «حجم الخط» بالنظام يصل حتى **٢٫٠** على أندرويد و**٣٫١** على iOS مع
/// تسهيلات الرؤية. وعند ١٫٨ ينكسر كلُّ شريطٍ فيه نصّ: `RenderFlex overflow`
/// بالتصحيح، وشريطٌ مخطَّط بالإصدار — وهو أشيعُ عطلٍ يُبلَّغ عنه من الميدان
/// ولا يظهر أبداً على جهاز المطوّر.
///
/// [MediaQuery.withClampedTextScaling] يحصره بسقف ١٫٣: يبقى للمستخدم تكبيرٌ
/// محسوس (+٣٠٪) ويبقى التخطيط قائماً. **ولا يُلغى التكبير بجعله ١٫٠** — ذلك
/// يكسر تسهيلات الرؤية كاملةً لمن يحتاجها.
///
/// ## ولا أرضيةَ (`minScaleFactor`) — كانت ٠٫٩ فأسقطت منتقي التاريخ
///
/// كان القيد `[٠٫٩ – ١٫٣]`، فيرفع خطَّ من صغّر خطّ نظامه إلى ٠٫٩. ثم يأتي
/// `_DatePickerHeader` بـMaterial فيحسب سقفه من المقياس **الحالي**:
/// `min(currentScale, 1.05)` = ٠٫٩، ويطلب `clamp(maxScaleFactor: 0.9)` فوق
/// قيدنا. فيصير الحدّان متساويين (٠٫٩ و٠٫٩)، و`_ClampedTextScaler` يؤكّد
/// `maxScale > minScale` **بشدّة** — فينهار فتحُ التاريخ بجهازٍ خطُّه مصغَّر:
///
/// ```text
/// 'package:flutter/src/painting/text_scaler.dart': Failed assertion:
/// line 118 pos 80: 'maxScale > minScale': is not true.
/// ```
///
/// والعطل **لا يظهر على جهاز المطوّر** (مقياسه ١٫٠)، ولا تكشفه مراجعة: أي
/// ودجة تشتقّ سقفها من المقياس الحالي تصطدم بأي أرضيةٍ نضعها. ولا تملك
/// Material أرضيةً أصلاً — فمن صغّر خطّ نظامه اختار ذلك، ورفعُه ليس قرارنا.
/// السلوك مثبَّت بـ`test/text_scale_clamp_test.dart`.
///
/// ```dart
/// MaterialApp.router(
///   builder: (context, child) => ResponsiveScope(child: child!),
/// )
/// ```
class ResponsiveScope extends StatelessWidget {
  const ResponsiveScope({required this.child, super.key});

  final Widget child;

  /// سقف تكبير الخط — بلا أرضية. راجع شرح الصنف.
  static const double maxTextScale = 1.3;

  /// مقاييسُ الشاشة الحالية.
  ///
  /// تسقط إلى حسابٍ من `MediaQuery` مباشرةً إن لم يكن فوقها نطاق — كي تعمل
  /// الودجة داخل اختبارٍ أو معاينةٍ لا `MaterialApp` فيها، بدل أن ترمي.
  static ScreenMetrics of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_ScreenMetricsScope>();
    if (scope != null) return scope.metrics;
    return ScreenMetrics.fromSize(MediaQuery.sizeOf(context));
  }

  @override
  Widget build(BuildContext context) {
    // `sizeOf` لا `MediaQuery.of`: يعيد البناء عند تغيّر المقاس وحده — لا مع
    // كل ظهورٍ للكيبورد (`viewInsets`)، وهو ما كان سيعيد بناء التطبيق كلّه
    // بكل ضغطةِ حقل.
    final metrics = ScreenMetrics.fromSize(MediaQuery.sizeOf(context));
    // **تصحيحُ سياسة الاتجاه بأول تخطيطٍ حقيقيّ.** `main()` تقرّر من
    // `PlatformDispatcher`، وقد تعود بمقاسٍ صفريّ قبل أول إطار فتسقط إلى
    // «اقفل عمودياً». وهنا المقاس مؤكَّد. والنداء يُهمَل إن لم يتغيّر القرار،
    // فلا يصل النظامَ شيءٌ بإعادة البناء.
    OrientationPolicy.applyFor(allowsLandscape: metrics.isTablet);
    return _ScreenMetricsScope(
      metrics: metrics,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: maxTextScale,
        child: child,
      ),
    );
  }
}

class _ScreenMetricsScope extends InheritedWidget {
  const _ScreenMetricsScope({required this.metrics, required super.child});

  final ScreenMetrics metrics;

  @override
  bool updateShouldNotify(_ScreenMetricsScope oldWidget) =>
      oldWidget.metrics != metrics;
}
