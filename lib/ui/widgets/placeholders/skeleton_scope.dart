import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/theme_extensions.dart';

/// **الهيكلُ يُبنى من الواجهة نفسِها، لا نسخةً ثانيةً منها.**
///
/// ✅ **(2026-09-01)** — كان لكلّ شاشةٍ «هيكلٌ» مرسومٌ باليد: أشرطةٌ رمادية
/// بمقاساتٍ مكتوبةٍ عدداً، تحاكي شكلَ الجسد وتعيش بملفٍّ آخر. وهي **تكذب
/// بالتعريف**: الجسدُ يتبدّل ولا يتبدّل معه الهيكل، فتُقرأ شاشةُ الانتظار
/// كأنها شاشةٌ ثالثة لا كأنها الشاشةُ نفسُها قبل أن تصل بياناتُها.
///
/// فصار الهيكلُ **شجرةَ الودجات الحقيقية** — نفسُ `AppCard` ونفسُ `AppListTile`
/// ونفسُ الحشوات — تُلفّ بـ[Skeletonized]، فيرسم كلُّ حقلٍ ديناميكيّ نفسَه
/// عظماً ([Bone]) بمقاس النصّ الحقيقيّ الذي سيحلّ محلَّه. ومقاسُ العظم
/// **يُقاس ولا يُقدَّر**: الطفلُ يُبنى ويُخطَّط شفّافاً، والعظمُ يُملأ فوقه —
/// فلا تقفز الصفحة لمّا يصل الجواب، ولا يتقادم الهيكلُ لمّا يتبدّل الجسد.
///
/// ```dart
/// // بالشاشة: نفسُ الجسد، بعلَمٍ واحد.
/// Skeletonized(enabled: state.isLoading, child: AccountBody(...))
/// ```
///
/// **وموجةُ الوميض واحدةٌ للشجرة كلِّها** — مؤقّتٌ واحد بالجذر، وكلُّ عظمٍ
/// يقرأ موضعَه **بإحداثيات الجذر** فيرسم القطعةَ التي تخصّه من الموجة. ولو
/// ملك كلُّ عظمٍ وميضَه لبدأت المؤقّتات بلحظاتٍ مختلفة، فتُقرأ الشاشةُ
/// أشرطةً كلٌّ يومض وحده.
///
/// **والسطحُ لا يومض** — البطاقةُ وظلُّها وفواصلُها تُرسم كما هي، والوميضُ
/// على العظام وحدها: تدرّجٌ يمرّ على السطح يجعل البطاقةَ نفسَها وامضة.
class Skeletonized extends StatelessWidget {
  const Skeletonized({
    required this.enabled,
    required this.child,
    this.period = const Duration(milliseconds: 1600),
    super.key,
  });

  final bool enabled;
  final Widget child;

  /// زمنُ مرورِ الموجة مرّةً على عرض الشاشة.
  final Duration period;

  @override
  Widget build(BuildContext context) {
    // ولا مؤقّتَ أصلاً حين لا انتظار: [Bone] خارج النطاق تمريرةٌ صافية،
    // فالجسدُ يُبنى كما لو لم تكن هذه الودجة بالشجرة.
    if (!enabled) return child;

    // **والقارئُ الصوتيّ لا يقرأ بياناتٍ لم تصل** — الأسماءُ النائبة موجودة
    // بالشجرة (هي ما يعطي العظمَ مقاسَه)، ومخفيّةٌ بصرياً لا دلالياً.
    return _SkeletonSweep(
      period: period,
      child: ExcludeSemantics(child: child),
    );
  }
}

/// جذرُ الموجة — يملك المؤقّت، ويُعلن نفسَه لأبنائه.
class _SkeletonSweep extends StatefulWidget {
  const _SkeletonSweep({required this.period, required this.child});

  final Duration period;
  final Widget child;

  @override
  State<_SkeletonSweep> createState() => _SkeletonSweepState();
}

class _SkeletonSweepState extends State<_SkeletonSweep>
    with SingleTickerProviderStateMixin {
  // غيرُ محدود ويدور من `-0.5` إلى `1.5`: الموجةُ تدخل من خارج الحافة وتخرج
  // من خارج الأخرى، فلا تُرى وهي تُولد بمنتصف الشاشة.
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
  )..repeat(min: -0.5, max: 1.5, period: widget.period);

  Listenable get sweep => _controller;

  double get slide => _controller.value;

  RenderBox? get _box => context.findRenderObject() as RenderBox?;

  bool get isSized => _box?.hasSize ?? false;

  Size get size => _box!.size;

  /// موضعُ عظمٍ بإحداثيات الجذر — به يُقصّ من الموجة ما يخصّه.
  Offset offsetOf(RenderBox descendant) =>
      descendant.localToGlobal(Offset.zero, ancestor: _box);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SkeletonScope(state: this, child: widget.child);
}

/// ناقلُ الحالة إلى العظام — `dependOnInheritedWidgetOfExactType` وحده.
class _SkeletonScope extends InheritedWidget {
  const _SkeletonScope({required this.state, required super.child});

  final _SkeletonSweepState state;

  static _SkeletonSweepState? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonScope>()?.state;

  @override
  bool updateShouldNotify(_SkeletonScope oldWidget) => state != oldWidget.state;
}

/// **عظمٌ بمقاس ما سيحلّ محلَّه** — يلفّ الودجة الحقيقية، فيأخذ مقاسَها.
///
/// خارج [Skeletonized] **تمريرةٌ صافية**: يردّ [child] كما هو بلا طبقةٍ ولا
/// كلفة. وداخلها يُخطَّط [child] شفّافاً (فيعطي المقاس الحقيقيّ بالخطّ الحقيقيّ
/// وبقيود الأب الحقيقية)، ويُملأ فوقه مستطيلٌ يمرّ به الوميض.
///
/// ```dart
/// Bone.circle(child: AvatarWidget(name: user.name, radius: 19))
/// Bone.text(child: Text(unit.number, style: ...))
/// Bone(radius: 20, child: StatusChip(...))
/// ```
///
/// ⚠️ **ويُلفّ ما ينتظر الشبكة وحدَه.** لافتةٌ ثابتة («المحافظة»، «المظهر»)
/// معروفةٌ قبل الطلب وبعده، وسترُها خلف عظمٍ يُخفي عن المستخدم ما نعرفه —
/// فتُقرأ الشاشةُ مقفلةً لا محمَّلة.
class Bone extends StatelessWidget {
  const Bone({
    required this.child,
    this.radius = 6,
    this.shape = BoxShape.rectangle,
    this.heightFactor = 1,
    super.key,
  });

  /// عظمُ نصّ — أضيقُ من سطر النصّ قليلاً بالارتفاع: صندوقُ السطر يشمل
  /// فراغَ الأعلى والأسفل (`height`)، وملؤه كاملاً يُخرج شريطاً أثخنَ مما
  /// سيحلّ محلَّه.
  const Bone.text({required this.child, super.key})
    : radius = 4,
      shape = BoxShape.rectangle,
      heightFactor = 0.74;

  const Bone.circle({required this.child, super.key})
    : radius = 0,
      shape = BoxShape.circle,
      heightFactor = 1;

  final Widget child;
  final double radius;
  final BoxShape shape;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final state = _SkeletonScope.of(context);
    if (state == null) return child;
    return _BoneFill(
      state: state,
      radius: radius,
      shape: shape,
      heightFactor: heightFactor,
      child: child,
    );
  }
}

class _BoneFill extends StatefulWidget {
  const _BoneFill({
    required this.state,
    required this.radius,
    required this.shape,
    required this.heightFactor,
    required this.child,
  });

  final _SkeletonSweepState state;
  final double radius;
  final BoxShape shape;
  final double heightFactor;
  final Widget child;

  @override
  State<_BoneFill> createState() => _BoneFillState();
}

class _BoneFillState extends State<_BoneFill> {
  @override
  void initState() {
    super.initState();
    widget.state.sweep.addListener(_onSweep);
  }

  @override
  void didUpdateWidget(_BoneFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.sweep.removeListener(_onSweep);
      widget.state.sweep.addListener(_onSweep);
    }
  }

  @override
  void dispose() {
    widget.state.sweep.removeListener(_onSweep);
    super.dispose();
  }

  void _onSweep() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = widget.state;

    Widget fill = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.borderSubtle,
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.circle
            ? null
            : BorderRadius.circular(widget.radius),
      ),
    );

    // أوّلُ إطارٍ يُبنى قبل أن يُخطَّط شيء، فلا موضعَ يُقرأ — يُرسم العظمُ
    // بلونه الصافي، ويلحقه الوميضُ بالإطار التالي (المؤقّت يُعيد البناء).
    final box = context.findRenderObject() as RenderBox?;
    if (state.isSized && (box?.hasSize ?? false)) {
      final offset = state.offsetOf(box!);
      final scope = state.size;
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      final gradient = LinearGradient(
        colors: [colors.borderSubtle, colors.bgCard, colors.borderSubtle],
        stops: const [0.35, 0.5, 0.65],
        transform: _SlidingGradient(isRtl ? -state.slide : state.slide),
      );
      fill = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (_) => gradient.createShader(
          Rect.fromLTWH(-offset.dx, -offset.dy, scope.width, scope.height),
        ),
        child: fill,
      );
    }

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        // الطفلُ الحقيقيّ هو **المقاس** — يُخطَّط ولا يُرى ولا يُلمس.
        IgnorePointer(child: Opacity(opacity: 0, child: widget.child)),
        Positioned.fill(
          child: widget.heightFactor == 1
              ? fill
              : FractionallySizedBox(
                  heightFactor: widget.heightFactor,
                  child: fill,
                ),
        ),
      ],
    );
  }
}

class _SlidingGradient extends GradientTransform {
  const _SlidingGradient(this.slide);

  final double slide;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}
