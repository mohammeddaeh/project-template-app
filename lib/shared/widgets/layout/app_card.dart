import 'package:flutter/material.dart';

/// The two shapes a card can take.
enum AppCardVariant {
  /// A full `Material Card`: background, optional shadow, rounded corners.
  /// For list items that read as separate islands.
  card,

  /// Fully transparent — no background, no shadow, no border. Just spacing
  /// around [AppCard.child].
  ///
  /// For content that **draws its own surface** (a header with a tinted band,
  /// a section that paints its own container) and would otherwise sit inside a
  /// second, visible card — two nested surfaces where the design has one.
  container,
}

/// A card with two selectable shapes — see [AppCardVariant].
///
/// [variant] defaults to [AppCardVariant.card], so every existing call site
/// keeps rendering exactly as before.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.elevation,
    this.clipBehavior = Clip.antiAlias,
    this.variant = AppCardVariant.card,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final double? elevation;
  final Clip clipBehavior;
  final AppCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final resolvedMargin =
        margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    if (variant == AppCardVariant.container) {
      return Padding(
        padding: resolvedMargin,
        child: Padding(padding: padding, child: child),
      );
    }

    return Card(
      margin: resolvedMargin,
      elevation: elevation ?? 0,
      clipBehavior: clipBehavior,
      child: Padding(padding: padding, child: child),
    );
  }
}
