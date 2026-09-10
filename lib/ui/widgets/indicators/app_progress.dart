import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/theme_extensions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
///  AppProgress — مؤشّر التقدّم **الوحيد** بالتطبيق
/// ═══════════════════════════════════════════════════════════════════════════
///
/// ## لماذا واحد
///
/// قبل هذا الملف كان بالمستودع أكثر من **٢٤ موضعاً** يبني مؤشّره بيده، وكلٌّ
/// اختار لوناً وسُمكاً ومقاساً مختلفاً: `strokeWidth` بقيم `2` و`2.5` و`4`،
/// وأربعة ألوان جذعٍ مختلفة (`borderSubtle` · `statusNeutralBg` ·
/// `dividerSubtle` · `primaryContainer`)، وشريطٌ بالمزامنة أخضر وآخر بالتصدير
/// `primary` وثالثٌ بالسجلّات ذهبيّ متدرّج. ولا شيء من ذلك يكسر البناء — لذا لا
/// `dart analyze` ولا الفاحص البنيويّ يراه، ويظهر التفاوت بالشاشة وحدها.
///
/// المصدر الواحد هنا هو [_ProgressPalette] أدناه: **كل** لونٍ يمرّ به، ولا
/// موضعَ بالتطبيق يكتب لون مؤشّرٍ نصّاً بعد اليوم.
///
/// ## الشكلان
///
/// ```dart
/// // دائريّ — غير محدّد (تحميل)
/// const AppProgress.circular()
/// const AppProgress.circular(size: AppProgressSize.xs)   // داخل زر أو شارة
///
/// // دائريّ — محدّد، ونسبةٌ بقلبه
/// AppProgress.circular(
///   value: completion,
///   tone: AppProgressTone.onBrand,   // فوق ترويسةٍ خضراء
///   dimension: 54,
///   center: GlyphCenter(child: Text(percentText)),
/// )
///
/// // خطّيّ — محدّد، بتدرّج التصميم الذهبيّ وسطرِ عدٍّ تحته
/// AppProgress.linear(
///   value: progress,
///   tone: AppProgressTone.accent,
///   label: LocaleKeys.buildingUnitsEntered.tr(),
/// )
/// ```
///
/// ## «متكيّف» — بأيّ معنى
///
/// 1. **يتكيّف مع الحالة**: `value == null` ⇒ دوّارٌ غير محدّد، و`value != null`
///    ⇒ مؤشّرٌ محدّد. لا وسيطَ ثالثاً ولا widget آخر.
/// 2. **يتكيّف مع الثيم**: كل نغمة تُحلّ من `context.colors` وقت البناء — فالفاتح
///    والداكن يتبدّلان بلا سطرٍ إضافيّ بموضع الاستدعاء.
/// 3. **يتكيّف مع الاتجاه**: الشريط المحدّد يمتلئ من جهة **البداية** — يميناً
///    بالعربية ويساراً بالإنجليزية.
/// 4. **يتكيّف مع القيمة**: تغيّر [value] يُحرَّك بدل أن يقفز ([animate]).
///
/// ## والتعديل وقت الاستعمال
///
/// كل قرارٍ يتّخذه هذا الويدجت له وسيطٌ يتجاوزه: [color] · [trackColor] ·
/// [gradient] · [strokeWidth] · [dimension] · [height] · [radius] · [padding] ·
/// [animate] · [animationDuration]. والافتراضات وحدها هي المُوحَّدة — لا القيود.
class AppProgress extends StatelessWidget {
  /// دائرة — للتحميل، أو لنسبةٍ حول رقم.
  const AppProgress.circular({
    super.key,
    this.value,
    this.tone = AppProgressTone.brand,
    this.size = AppProgressSize.md,
    this.color,
    this.trackColor,
    this.strokeWidth,
    this.dimension,
    this.center,
    this.padding,
    this.centered = false,
    this.adaptive = false,
    this.animate = true,
    this.animationDuration = _kAnimation,
    this.semanticsLabel,
  }) : _shape = _ProgressShape.circular,
       gradient = null,
       height = null,
       radius = null,
       label = null,
       labelStyle = null,
       labelGap = 0;

  /// شريط — لتقدّمٍ له مقدار، أو لخيطِ تحميلٍ رفيع أعلى القائمة.
  const AppProgress.linear({
    super.key,
    this.value,
    this.tone = AppProgressTone.brand,
    this.size = AppProgressSize.md,
    this.color,
    this.trackColor,
    this.gradient,
    this.height,
    this.radius,
    this.label,
    this.labelStyle,
    this.labelGap = 13,
    this.padding,
    this.centered = false,
    this.animate = true,
    this.animationDuration = _kAnimation,
    this.semanticsLabel,
  }) : _shape = _ProgressShape.linear,
       strokeWidth = null,
       dimension = null,
       center = null,
       adaptive = false;

  static const Duration _kAnimation = Duration(milliseconds: 300);

  final _ProgressShape _shape;

  /// `null` ⇒ غير محدّد (دوران مستمرّ). وإلّا `0.0`–`1.0`، وتُقصّ دفاعياً: عدّادٌ
  /// يتجاوز مجموعه كان سيرسم شريطاً خارج حدوده.
  final double? value;

  /// النغمة الدلاليّة — المدخل الوحيد للّون بالاستعمال العاديّ.
  final AppProgressTone tone;

  /// المقاس الرمزيّ. [dimension]/[strokeWidth]/[height] تتجاوزه عند الحاجة.
  final AppProgressSize size;

  /// تجاوزٌ صريح للون المؤشّر — يتخطّى [tone].
  final Color? color;

  /// تجاوزٌ صريح للون الجذع (الجزء غير المكتمل).
  final Color? trackColor;

  /// تدرّجٌ للشريط المحدّد — يتخطّى [color]. `tone: accent` يوفّره تلقائياً.
  final Gradient? gradient;

  /// سُمك الدائرة. الافتراضي من [size].
  final double? strokeWidth;

  /// قُطر الدائرة. الافتراضي من [size].
  final double? dimension;

  /// ارتفاع الشريط. الافتراضي من [size].
  final double? height;

  /// نصف قطر أطراف الشريط. الافتراضي: نصف الارتفاع (كبسولة).
  final double? radius;

  /// ما يُرسم بقلب الدائرة — نسبةٌ أو أيقونة.
  ///
  /// نصّاً رقميّاً لُفّه بـ`GlyphCenter`: صندوق سطر الخط العربي علويُّ الثقل،
  /// فالرقم بلا نازلةٍ يعلو قلبَ الحلقة. التفصيل في
  /// `ui/widgets/misc/glyph_center.dart`. أيقونةً لا يلزم شيء.
  final Widget? center;

  /// سطرٌ تحت الشريط. **نصٌّ جاهز لا مفتاح**: صياغته تختلف بكل شاشة («عنصر» ·
  /// «سجل» · «ميغابايت») وتحمل أرقاماً تُحقن، فبناؤه هنا كان سيعني وسيطاً لكل
  /// صيغة.
  final String? label;
  final TextStyle? labelStyle;
  final double labelGap;

  /// حَشوٌ حول المؤشّر — يغني عن لفّه بـ`Padding` بموضع الاستدعاء.
  final EdgeInsetsGeometry? padding;

  /// يلفّه بـ`Center`. للشاشة الفارغة أثناء أوّل تحميل.
  final bool centered;

  /// دوّار المنصّة (Cupertino على iOS). **مطفأ افتراضاً وعن قصد**: التوحيد هو
  /// الغرض، ودوّار Cupertino لا يحمل [value] ولا يقبل [strokeWidth].
  final bool adaptive;

  /// تحريك انتقال [value] بدل قفزه. يُهمَل مع المؤشّر غير المحدّد.
  final bool animate;
  final Duration animationDuration;

  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final palette = _ProgressPalette.of(context, tone);
    final fg = color ?? palette.color;
    final track = trackColor ?? palette.track;
    final v = value?.clamp(0.0, 1.0);

    Widget out = switch (_shape) {
      _ProgressShape.circular => _CircularProgress(
        value: v,
        color: fg,
        trackColor: track,
        dimension: dimension ?? size.dimension,
        strokeWidth: strokeWidth ?? size.strokeWidth,
        center: center,
        adaptive: adaptive,
        animate: animate,
        animationDuration: animationDuration,
        semanticsLabel: semanticsLabel,
      ),
      _ProgressShape.linear => _LinearProgress(
        value: v,
        color: fg,
        trackColor: track,
        gradient:
            gradient ??
            (tone == AppProgressTone.accent ? palette.gradient : null),
        height: height ?? size.height,
        radius: radius ?? (height ?? size.height) / 2,
        label: label,
        labelStyle: labelStyle,
        labelGap: labelGap,
        animate: animate,
        animationDuration: animationDuration,
        semanticsLabel: semanticsLabel,
      ),
    };

    if (padding != null) out = Padding(padding: padding!, child: out);
    if (centered) out = Center(child: out);
    return out;
  }
}

enum _ProgressShape { circular, linear }

// ═══════════════════════════════════════════════════════════════════════════
//  دائرة
// ═══════════════════════════════════════════════════════════════════════════

class _CircularProgress extends StatelessWidget {
  const _CircularProgress({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.dimension,
    required this.strokeWidth,
    required this.center,
    required this.adaptive,
    required this.animate,
    required this.animationDuration,
    required this.semanticsLabel,
  });

  final double? value;
  final Color color;
  final Color trackColor;
  final double dimension;
  final double strokeWidth;
  final Widget? center;
  final bool adaptive;
  final bool animate;
  final Duration animationDuration;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final ring = _AnimatedValue(
      value: value,
      animate: animate,
      duration: animationDuration,
      builder: (v) => _Ring(
        value: v,
        color: color,
        trackColor: trackColor,
        strokeWidth: strokeWidth,
        adaptive: adaptive,
        semanticsLabel: semanticsLabel,
      ),
    );

    return SizedBox.square(
      dimension: dimension,
      child: center == null
          ? ring
          : Stack(alignment: Alignment.center, children: [ring, center!]),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.adaptive,
    required this.semanticsLabel,
  });

  final double? value;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final bool adaptive;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    // الجذع يُرسم للمحدّد وحده — حلقةٌ كاملة خلف دوّارٍ غير محدّد تُقرأ «توقّف
    // عند هذا الحدّ» لا «يعمل».
    final track = value == null ? null : trackColor;

    if (adaptive) {
      return CircularProgressIndicator.adaptive(
        value: value,
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        backgroundColor: track,
        semanticsLabel: semanticsLabel,
      );
    }
    return CircularProgressIndicator(
      value: value,
      strokeWidth: strokeWidth,
      color: color,
      backgroundColor: track,
      semanticsLabel: semanticsLabel,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  شريط
// ═══════════════════════════════════════════════════════════════════════════

class _LinearProgress extends StatelessWidget {
  const _LinearProgress({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.gradient,
    required this.height,
    required this.radius,
    required this.label,
    required this.labelStyle,
    required this.labelGap,
    required this.animate,
    required this.animationDuration,
    required this.semanticsLabel,
  });

  final double? value;
  final Color color;
  final Color trackColor;
  final Gradient? gradient;
  final double height;
  final double radius;
  final String? label;
  final TextStyle? labelStyle;
  final double labelGap;
  final bool animate;
  final Duration animationDuration;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final bar = _AnimatedValue(
      value: value,
      animate: animate,
      duration: animationDuration,
      builder: (v) => _Bar(
        value: v,
        color: color,
        trackColor: trackColor,
        gradient: gradient,
        height: height,
        radius: radius,
        semanticsLabel: semanticsLabel,
      ),
    );

    if (label == null) return bar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        bar,
        SizedBox(height: labelGap),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                labelStyle ??
                context.textTheme.labelMedium?.copyWith(
                  color: context.colors.textMuted,
                ),
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.gradient,
    required this.height,
    required this.radius,
    required this.semanticsLabel,
  });

  final double? value;
  final Color color;
  final Color trackColor;
  final Gradient? gradient;
  final double height;
  final double radius;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final v = value;

    // التدرّج لا يمرّ عبر `LinearProgressIndicator` — لا وسيطَ له. فالمحدّد
    // بتدرّجٍ يُبنى يدوياً؛ وما عداه يبقى على ويدجت المادّة بمنطق حركته غير
    // المحدّدة.
    if (gradient == null || v == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: LinearProgressIndicator(
          value: v,
          minHeight: height,
          color: color,
          backgroundColor: trackColor,
          semanticsLabel: semanticsLabel,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: Stack(
          // `StackFit.expand` — وبدونه لا يُرسم شيء: الترتيب الافتراضي `loose`
          // يجعل `FractionallySizedBox` يتحجّم بحجم ابنه، و`DecoratedBox` بلا
          // ابنٍ حجمُه **صفر**.
          fit: StackFit.expand,
          children: [
            ColoredBox(color: trackColor),
            // ⚠️ **بلا `Align` هنا.** `Align` يُرخي القيود لابنه، فيُعيد
            // `FractionallySizedBox` إلى ارتفاع صفر رغم `StackFit.expand`.
            // و`FractionallySizedBox` يملك `alignment` بنفسه، فلا حاجة له.
            FractionallySizedBox(
              // البداية = **اليمين** بواجهة عربية، كما يرسمه التصميم.
              alignment: AlignmentDirectional.centerStart,
              widthFactor: v,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  التحريك
// ═══════════════════════════════════════════════════════════════════════════

/// يمرّر القيمة لـ[builder] بعد تنعيمها. وغير المحدّد لا يُحرَّك:
/// `TweenAnimationBuilder` يحتاج نهايةً، ولا نهاية له.
class _AnimatedValue extends StatelessWidget {
  const _AnimatedValue({
    required this.value,
    required this.animate,
    required this.duration,
    required this.builder,
  });

  final double? value;
  final bool animate;
  final Duration duration;
  final Widget Function(double? value) builder;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v == null || !animate) return builder(v);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: v),
      duration: duration,
      curve: Curves.easeOut,
      builder: (_, animated, _) => builder(animated),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  المقاسات
// ═══════════════════════════════════════════════════════════════════════════

/// المقاسات المعتمدة. الأرقام هنا هي **كل** أرقام المؤشّرات بالتطبيق — من زادَ
/// عليها رقماً رابعاً فليضفه صفّاً هنا لا وسيطاً بموضع الاستدعاء.
enum AppProgressSize {
  /// داخل شارة أو حقل — `14×14`.
  xs(dimension: 14, strokeWidth: 2, height: 3),

  /// داخل زر أو صفّ — `20×20`.
  sm(dimension: 20, strokeWidth: 2, height: 5),

  /// الافتراضيّ — ذيل قائمة، بطاقة، شريط تقدّم — `28×28`.
  md(dimension: 28, strokeWidth: 2.5, height: 7),

  /// شاشة فارغة أو حوار — `44×44`.
  lg(dimension: 44, strokeWidth: 3.5, height: 10);

  const AppProgressSize({
    required this.dimension,
    required this.strokeWidth,
    required this.height,
  });

  /// قُطر الدائرة.
  final double dimension;

  /// سُمك حلقة الدائرة.
  final double strokeWidth;

  /// ارتفاع الشريط.
  final double height;
}

// ═══════════════════════════════════════════════════════════════════════════
//  النغمات — المصدر الواحد للّون
// ═══════════════════════════════════════════════════════════════════════════

/// نغمة المؤشّر — **دلاليّة لا لونيّة**: موضع الاستدعاء يقول «هذا نجاح» لا
/// «هذا أخضر»، فيتبدّل اللون مع الثيم بلا مسّ الشاشة.
enum AppProgressTone {
  /// الافتراضيّ — لون العلامة الأساسيّ. لكل تحميلٍ محايد.
  brand,

  /// التدرّج الذهبيّ الذي يرسمه التصميم لأشرطة الإنجاز (سجلّات · مقاسم).
  accent,

  /// عمليّةٌ تمضي إلى إتمام — الرفع بمركز المزامنة.
  success,

  /// عمليّةٌ معلّقة أو منتظرة.
  warning,

  /// عمليّةٌ متعثّرة تُعيد المحاولة.
  danger,

  /// رماديّ — حيث ينافس المؤشّر محتوىً أهمّ منه.
  neutral,

  /// فوق سطحٍ مطليّ بلون العلامة (ترويسة خضراء · خلفية داكنة)، حيث `primary`
  /// يذوب بالخلفية.
  onBrand,
}

/// حلّ النغمة إلى ألوان الثيم. **لا موضعَ آخر بالتطبيق يفعل هذا.**
class _ProgressPalette {
  const _ProgressPalette({
    required this.color,
    required this.track,
    required this.gradient,
  });

  factory _ProgressPalette.of(BuildContext context, AppProgressTone tone) {
    final c = context.colors;
    final goldRun = LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: [c.secondary, c.tertiary],
    );

    return switch (tone) {
      AppProgressTone.brand => _ProgressPalette(
        color: c.primary,
        track: c.borderSubtle,
        gradient: goldRun,
      ),
      AppProgressTone.accent => _ProgressPalette(
        color: c.secondary,
        track: c.bgElevated2,
        gradient: goldRun,
      ),
      AppProgressTone.success => _ProgressPalette(
        color: c.statusSuccessFg,
        track: c.statusNeutralBg,
        gradient: goldRun,
      ),
      AppProgressTone.warning => _ProgressPalette(
        color: c.statusWarningFg,
        track: c.statusWarningBg,
        gradient: goldRun,
      ),
      AppProgressTone.danger => _ProgressPalette(
        color: c.statusErrorFg,
        track: c.statusErrorBg,
        gradient: goldRun,
      ),
      AppProgressTone.neutral => _ProgressPalette(
        color: c.textMuted,
        track: c.dividerSubtle,
        gradient: goldRun,
      ),
      AppProgressTone.onBrand => _ProgressPalette(
        color: c.onBrandAccent,
        track: c.onBrand.withValues(alpha: .2),
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [c.onBrandAccent, c.onBrand],
        ),
      ),
    };
  }

  final Color color;
  final Color track;
  final Gradient gradient;
}
