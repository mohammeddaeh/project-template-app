import 'package:flutter/material.dart';

import 'package:app_template/ui/responsive/responsive_extensions.dart';
import 'package:app_template/ui/responsive/screen_metrics.dart';

/// عرضُ المحتوى المسموح — النموذج أضيق من القائمة، والملء بلا حدّ.
enum ContentWidth {
  /// عمودُ حقولٍ وأزرار — ٤٨٠ بكسل على اللوح.
  form,

  /// قائمةٌ أو نصٌّ يُقرأ — ٨٤٠ بكسل على اللوح.
  content,

  /// بلا حدّ: خرائط · معارض صور · أي سطحٍ يستفيد من كل بكسل.
  full,
}

/// يحصر المحتوى بعرضٍ مقروء ويوسّطه، ويضع هامش الصفحة.
///
/// **هذه هي الودجة التي تجعل شاشةً مبنيّةً لهاتفٍ تعمل على لوح.** بلا حدٍّ
/// للعرض يتمدّد النموذجُ إلى ١٢٠٠ بكسل: اللافتةُ في أقصى اليمين وقيمتُها في
/// أقصى اليسار، والزرُّ شريطٌ يعبر الشاشة. وليس هذا «تصميماً للّوح» بل تكبيرَ
/// هاتفٍ بالعرض وحده.
///
/// وعلى الهاتف لا تفعل شيئاً سوى الهامش: [ContentWidth.form] و
/// [ContentWidth.content] كلاهما بلا حدٍّ دون ٦٠٠ بكسل، فلا تُغيّر شاشةً
/// قائمة.
///
/// ```dart
/// body: ResponsiveContentBox(
///   width: ContentWidth.content,
///   child: ListView(...),
/// )
/// ```
class ResponsiveContentBox extends StatelessWidget {
  const ResponsiveContentBox({
    required this.child,
    this.width = ContentWidth.content,
    this.horizontalPadding = true,
    this.padding,
    super.key,
  });

  final Widget child;
  final ContentWidth width;

  /// يضع [ScreenMetrics.gutter] يميناً ويساراً. أطفئه لسطحٍ يمتدّ إلى الحافة
  /// (قائمةٌ تفصل صفوفَها خطوطٌ عابرة، مثلاً) ويضع أبناؤه حشوتهم بأنفسهم.
  final bool horizontalPadding;

  /// حشوةٌ صريحة تحلّ محلّ [horizontalPadding] كاملاً.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final maxWidth = switch (width) {
      ContentWidth.form => screen.formMaxWidth,
      ContentWidth.content => screen.contentMaxWidth,
      ContentWidth.full => double.infinity,
    };
    final resolvedPadding =
        padding ??
        (horizontalPadding
            ? EdgeInsets.symmetric(horizontal: screen.gutter)
            : EdgeInsets.zero);

    return Align(
      // `alignment: topCenter` لا `center`: التوسيط الرأسي هنا يجعل قائمةً
      // قصيرة تطفو بمنتصف الشاشة بدل أن تبدأ من أعلاها.
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}

/// يبني حسب [ScreenMetrics] — للحالات التي يختلف فيها **التركيب** لا المقاس.
///
/// استعمله حين يصير العمودُ عمودَين، أو تنتقل لوحةٌ من ورقةٍ سفلية إلى جانبٍ
/// ثابت. أمّا تغييرُ رقمٍ فحسب فـ[ScreenMetrics.pick] أخصرُ وأوضح.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, ScreenMetrics screen) builder;

  @override
  Widget build(BuildContext context) => builder(context, context.screen);
}

/// فراغٌ بمقاس التصميم، محمولاً إلى الشاشة الحالية — رأسيٌّ افتراضاً، و
/// [ResponsiveGap.horizontal] داخل صفّ.
///
/// `const SizedBox(height: 24)` يبقى ٢٤ على شاشةٍ بارتفاع ٥٦٨ وعلى لوحٍ
/// بارتفاع ١١٩٤ — أضيقُ ممّا يجب هناك، وأوسعُ ممّا تحتمله الشاشة القصيرة.
class ResponsiveGap extends StatelessWidget {
  const ResponsiveGap(this.base, {super.key}) : _horizontal = false;

  /// فراغٌ أفقيّ بين عنصرَين بصفّ — `const`، بخلاف `SizedBox(width: s.space(8))`.
  const ResponsiveGap.horizontal(this.base, {super.key}) : _horizontal = true;

  /// المسافة كما هي بالتصميم عند عرض ٣٩٠.
  final double base;

  final bool _horizontal;

  @override
  Widget build(BuildContext context) {
    final gap = context.screen.space(base);
    return _horizontal ? SizedBox(width: gap) : SizedBox(height: gap);
  }
}
