import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/shared/widgets/placeholders/shimmer_loading_widget.dart';

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
/// استخدم كـ [PaginationBuilderWdg.loadingItemWidget].
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

  void _startDots() {
    if (widget.style != PageLoadingStyle.dotsWave &&
        widget.style != PageLoadingStyle.pulseDots) {
      return;
    }
    for (int i = 0; i < _dotCtrl.length; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) { _dotCtrl[i].repeat(reverse: true); }
      });
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
    _entryCtrl.dispose();
    for (final c in _dotCtrl) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn),
      child: _buildStyle(context),
    );
  }

  Widget _buildStyle(BuildContext context) => switch (widget.style) {
    PageLoadingStyle.spinner     => _buildSpinner(context),
    PageLoadingStyle.linearBar   => _buildLinearBar(context),
    PageLoadingStyle.shimmerBar  => _buildShimmerBar(context),
    PageLoadingStyle.dotsWave    => _buildDotsWave(context),
    PageLoadingStyle.textSpinner => _buildTextSpinner(context),
    PageLoadingStyle.pulseDots   => _buildPulseDots(context),
  };

  // ── Spinner ─────────────────────────────────────────────────────────────────

  Widget _buildSpinner(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: context.colorScheme.primary,
        ),
      ),
    ),
  );

  // ── Linear Bar ──────────────────────────────────────────────────────────────

  Widget _buildLinearBar(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: LinearProgressIndicator(
        minHeight: 3,
        borderRadius: BorderRadius.circular(8),
        color: scheme.primary,
        backgroundColor: scheme.primaryContainer,
      ),
    );
  }

  // ── Shimmer Bar ─────────────────────────────────────────────────────────────

  Widget _buildShimmerBar(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: ShimmerLoadingWidget(
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  );

  // ── Dots Wave ───────────────────────────────────────────────────────────────

  Widget _buildDotsWave(BuildContext context) {
    final color = context.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (i) => AnimatedBuilder(
            animation: _dotCtrl[i],
            builder: (ctx, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, -9 * _dotCtrl[i].value),
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

  // ── Text + Spinner ──────────────────────────────────────────────────────────

  Widget _buildTextSpinner(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.loadingText ?? 'Loading more…',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pulse Dots ──────────────────────────────────────────────────────────────

  Widget _buildPulseDots(BuildContext context) {
    final color = context.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (i) => AnimatedBuilder(
            animation: _dotCtrl[i],
            builder: (ctx, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Opacity(
                opacity: 0.2 + 0.8 * _dotCtrl[i].value,
                child: Transform.scale(
                  scale: 0.65 + 0.35 * _dotCtrl[i].value,
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
