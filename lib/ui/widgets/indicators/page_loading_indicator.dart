import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_template/ui/widgets/indicators/app_progress.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/placeholders/shimmer_loading_widget.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// أنماط مؤشر تحميل الصفحة التالية في القائمة.
enum PageLoadingStyle {
  spinner,
  linearBar,
  shimmerBar,
  dotsWave,
  textSpinner,
  pulseDots,
}

/// مؤشر يظهر في أسفل القائمة عند تحميل الصفحة التالية.
/// يدعم 6 أنماط احترافية مع animation ظهور/اختفاء مدمجة.
/// استخدم كـ [PaginationBuilder.loadingItemWidget].
class PageLoadingIndicator extends StatefulWidget {
  const PageLoadingIndicator({
    super.key,
    this.style = PageLoadingStyle.spinner,
    this.loadingText,
  });

  final PageLoadingStyle style;

  /// النص المعروض في نمط [PageLoadingStyle.textSpinner].
  /// إذا لم يُمرَّر يُعرض "Loading more…"
  final String? loadingText;

  @override
  State<PageLoadingIndicator> createState() => _PageLoadingIndicatorState();
}

class _PageLoadingIndicatorState extends State<PageLoadingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final List<AnimationController> _dotCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();

    _dotCtrl = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      ),
    );
    _startDots();
  }

  /// The staggered starts — cancelled with the widget, so none fires after it
  /// is gone (a pending `Future.delayed` cannot be cancelled).
  final _dotStarts = <Timer>[];

  void _startDots() {
    for (final t in _dotStarts) {
      t.cancel();
    }
    _dotStarts.clear();
    if (widget.style != PageLoadingStyle.dotsWave &&
        widget.style != PageLoadingStyle.pulseDots) {
      return;
    }
    for (int i = 0; i < _dotCtrl.length; i++) {
      _dotStarts.add(
        Timer(
          Duration(milliseconds: i * 160),
          () => _dotCtrl[i].repeat(reverse: true),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(PageLoadingIndicator old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style) {
      for (final c in _dotCtrl) {
        c.stop();
        c.value = 0;
      }
      _startDots();
    }
  }

  @override
  void dispose() {
    for (final t in _dotStarts) {
      t.cancel();
    }
    _entryCtrl.dispose();
    for (final c in _dotCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn),
      child: switch (widget.style) {
        PageLoadingStyle.spinner => const _Spinner(),
        PageLoadingStyle.linearBar => const _LinearBar(),
        PageLoadingStyle.shimmerBar => const _ShimmerBar(),
        PageLoadingStyle.dotsWave => _DotsWave(controllers: _dotCtrl),
        PageLoadingStyle.textSpinner => _TextSpinner(
          loadingText: widget.loadingText,
        ),
        PageLoadingStyle.pulseDots => _PulseDots(controllers: _dotCtrl),
      },
    );
  }
}

// ── Spinner ───────────────────────────────────────────────────────────────────

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => AppProgress.circular(
    dimension: 28,
    centered: true,
    padding: EdgeInsets.symmetric(vertical: context.screen.space(16)),
  );
}

// ── Linear Bar ────────────────────────────────────────────────────────────────

class _LinearBar extends StatelessWidget {
  const _LinearBar();

  @override
  Widget build(BuildContext context) => AppProgress.linear(
    height: 3,
    padding: EdgeInsets.symmetric(vertical: context.screen.space(10)),
  );
}

// ── Shimmer Bar ───────────────────────────────────────────────────────────────

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.screen.space(8)),
    child: ShimmerLoadingWidget(
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          // قناعٌ لا لون: الـshimmer يرسم ألوانه فوق الشكل المعتم أياً كان لونه.
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  );
}

// ── Dots Wave ─────────────────────────────────────────────────────────────────

class _DotsWave extends StatelessWidget {
  const _DotsWave({required this.controllers});

  /// متحكّمات النقاط الثلاث — يملكها [_PageLoadingIndicatorState].
  final List<AnimationController> controllers;

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.screen.space(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (i) => AnimatedBuilder(
            animation: controllers[i],
            builder: (ctx, _) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.screen.space(4),
              ),
              child: Transform.translate(
                offset: Offset(0, -9 * controllers[i].value),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Text + Spinner ────────────────────────────────────────────────────────────

class _TextSpinner extends StatelessWidget {
  const _TextSpinner({this.loadingText});

  final String? loadingText;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.screen.space(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppProgress.circular(size: AppProgressSize.sm),
          SizedBox(width: context.screen.space(10)),
          Text(
            loadingText ?? 'Loading more…',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulse Dots ────────────────────────────────────────────────────────────────

class _PulseDots extends StatelessWidget {
  const _PulseDots({required this.controllers});

  /// متحكّمات النقاط الثلاث — يملكها [_PageLoadingIndicatorState].
  final List<AnimationController> controllers;

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.screen.space(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (i) => AnimatedBuilder(
            animation: controllers[i],
            builder: (ctx, _) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.screen.space(5),
              ),
              child: Opacity(
                opacity: 0.2 + 0.8 * controllers[i].value,
                child: Transform.scale(
                  scale: 0.65 + 0.35 * controllers[i].value,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
