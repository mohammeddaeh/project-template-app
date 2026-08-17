import 'dart:async';

import 'package:flutter/material.dart';

/// How a row arrives.
enum ListItemAppear {
  /// Rows appear fully formed. For dense lists where motion would be noise.
  none,

  /// Opacity only.
  fade,

  /// Opacity plus a short rise. The default — the direction of travel reads as
  /// "this came from the page below", which is where the next page comes from.
  fadeSlide,

  /// Opacity plus a slight scale-up. For card grids, where a vertical slide
  /// fights the grid's own geometry.
  fadeScale,
}

/// Plays a row's entrance exactly once.
///
/// ## The two failure modes this is built around
///
/// **Re-animating on scroll-back.** A `SliverList` disposes rows that leave the
/// viewport and rebuilds them on return. An entrance animation that lives in the
/// row would therefore replay every time the reader scrolls up — a list that
/// twitches whenever it is read. The owner of the list decides what is new (see
/// [enabled]); this widget only plays what it is told to play.
///
/// **Stagger that grows without bound.** Delaying row *n* by *n × step* means
/// row 40 waits nearly two seconds — the reader scrolls into a column of blank
/// space that fills in behind them. [staggerIndex] is clamped by the caller so
/// the cascade is a property of a *page*, not of the whole list.
///
/// Honours `MediaQuery.disableAnimations`, so the OS-level "reduce motion"
/// setting turns every list in the app static without a per-screen flag.
class ListItemAppearWdg extends StatefulWidget {
  const ListItemAppearWdg({
    super.key,
    required this.child,
    this.animation = ListItemAppear.fadeSlide,
    this.staggerIndex = 0,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 300),
    this.stagger = const Duration(milliseconds: 35),
  });

  final Widget child;
  final ListItemAppear animation;

  /// Position of this row within its own arriving batch — not its index in the
  /// list. Clamp it before passing it in.
  final int staggerIndex;

  /// `false` renders the child directly, no controller, no frame cost. Pass
  /// `false` for rows the reader has already seen.
  final bool enabled;

  final Duration duration;
  final Duration stagger;

  @override
  State<ListItemAppearWdg> createState() => _ListItemAppearWdgState();
}

class _ListItemAppearWdgState extends State<ListItemAppearWdg>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  Timer? _delay;

  bool get _animates =>
      widget.enabled && widget.animation != ListItemAppear.none;

  @override
  void initState() {
    super.initState();
    if (!_animates) return;

    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    final delay = widget.stagger * widget.staggerIndex;
    if (delay == Duration.zero) {
      _ctrl!.forward();
    } else {
      _delay = Timer(delay, () {
        if (mounted) _ctrl?.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    // Checked here rather than in initState: MediaQuery is not available that
    // early, and the controller costs nothing once it is never read.
    if (ctrl == null || MediaQuery.maybeDisableAnimationsOf(context) == true) {
      return widget.child;
    }

    final curved = CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: switch (widget.animation) {
            ListItemAppear.fade => child,
            ListItemAppear.fadeSlide => Transform.translate(
              offset: Offset(0, 16 * (1 - t)),
              child: child,
            ),
            ListItemAppear.fadeScale => Transform.scale(
              scale: 0.96 + 0.04 * t,
              child: child,
            ),
            ListItemAppear.none => child,
          },
        );
      },
      child: widget.child,
    );
  }
}
