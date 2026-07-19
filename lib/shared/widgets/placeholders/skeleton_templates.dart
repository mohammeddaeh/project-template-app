import 'package:flutter/material.dart';
import 'package:app_template/shared/widgets/placeholders/shimmer_loading_widget.dart';

// Internal box — colored rectangle / circle with no shimmer of its own.
// Shimmer is supplied by the parent template's ShimmerLoadingWidget.
class _Box extends StatelessWidget {
  const _Box({
    this.width,
    required this.height,
    this.circle = false,
  });

  final double? width;
  final double height;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(circle ? height / 2 : 6),
        ),
      );
}

/// Horizontal row: leading avatar circle + two text lines.
///
/// ```dart
/// // مثال:
/// ListView.builder(
///   itemCount: 8,
///   itemBuilder: (_, __) => const SkeletonListTile(),
/// )
/// ```
///
/// Parameters:
/// - [showAvatar] — يُظهر دائرة الـ avatar على اليسار (افتراضي: true)
/// - [lines] — عدد خطوط النص (1-3، افتراضي: 2)
/// - [padding] — padding خارجي (افتراضي: horizontal 16, vertical 10)
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({
    super.key,
    this.showAvatar = true,
    this.lines = 2,
    this.padding,
  }) : assert(lines >= 1 && lines <= 3, 'lines must be 1–3');

  final bool showAvatar;
  final int lines;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoadingWidget(
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showAvatar) ...[
              const _Box(width: 44, height: 44, circle: true),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Box(width: double.infinity, height: 13),
                  if (lines >= 2) ...[
                    const SizedBox(height: 6),
                    const _Box(width: 140, height: 11),
                  ],
                  if (lines >= 3) ...[
                    const SizedBox(height: 6),
                    const _Box(width: 100, height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card with optional image header + title + subtitle lines.
///
/// ```dart
/// const SkeletonCard()
/// const SkeletonCard(showImage: false, lines: 2)
/// ```
///
/// Parameters:
/// - [showImage] — يُظهر مستطيل الصورة في الأعلى (افتراضي: true)
/// - [imageHeight] — ارتفاع منطقة الصورة (افتراضي: 140)
/// - [lines] — عدد خطوط النص أسفل الصورة (1-3، افتراضي: 3)
/// - [padding] — padding خارجي حول البطاقة
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.showImage = true,
    this.imageHeight = 140,
    this.lines = 3,
    this.padding,
  }) : assert(lines >= 1 && lines <= 3, 'lines must be 1–3');

  final bool showImage;
  final double imageHeight;
  final int lines;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;
    return ShimmerLoadingWidget(
      child: Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showImage)
                  Container(
                    width: double.infinity,
                    height: imageHeight,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Box(width: double.infinity, height: 14),
                      if (lines >= 2) ...[
                        const SizedBox(height: 8),
                        const _Box(width: 200, height: 12),
                      ],
                      if (lines >= 3) ...[
                        const SizedBox(height: 6),
                        const _Box(width: 150, height: 12),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Square grid cell: image area + two text lines below.
///
/// ```dart
/// GridView.builder(
///   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
///     crossAxisCount: 2, childAspectRatio: 0.85),
///   itemBuilder: (_, __) => const SkeletonGridItem(),
/// )
/// ```
///
/// Parameters:
/// - [aspectRatio] — نسبة عرض/ارتفاع منطقة الصورة المربعة (افتراضي: 0.85)
/// - [padding] — padding داخل كل خلية
class SkeletonGridItem extends StatelessWidget {
  const SkeletonGridItem({
    super.key,
    this.aspectRatio = 0.85,
    this.padding,
  });

  final double aspectRatio;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ShimmerLoadingWidget(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const _Box(width: double.infinity, height: 12),
            const SizedBox(height: 5),
            const _Box(width: 80, height: 11),
          ],
        ),
      ),
    );
  }
}

/// Centered avatar circle + stacked name/detail lines (profile header).
///
/// ```dart
/// const SkeletonProfile()
/// SkeletonProfile(avatarRadius: 48, lines: 2)
/// ```
///
/// Parameters:
/// - [avatarRadius] — نصف قطر دائرة الصورة (افتراضي: 40 → قطر 80px)
/// - [lines] — عدد خطوط النص أسفل الدائرة (1-3، افتراضي: 3)
/// - [padding] — padding خارجي (افتراضي: vertical 24, horizontal 48)
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({
    super.key,
    this.avatarRadius = 40,
    this.lines = 3,
    this.padding,
  }) : assert(lines >= 1 && lines <= 3, 'lines must be 1–3');

  final double avatarRadius;
  final int lines;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final diameter = avatarRadius * 2;
    return ShimmerLoadingWidget(
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: _Box(width: diameter, height: diameter, circle: true),
            ),
            const SizedBox(height: 16),
            const Center(child: _Box(width: 180, height: 14)),
            if (lines >= 2) ...[
              const SizedBox(height: 8),
              const Center(child: _Box(width: 120, height: 12)),
            ],
            if (lines >= 3) ...[
              const SizedBox(height: 6),
              const Center(child: _Box(width: 90, height: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal row of N equal stat blocks (value line + label line).
///
/// ```dart
/// const SkeletonStatRow()         // 3 stats
/// const SkeletonStatRow(count: 4) // 4 stats
/// ```
///
/// Parameters:
/// - [count] — عدد الإحصائيات جنباً لجنب (افتراضي: 3)
/// - [padding] — padding خارجي (افتراضي: horizontal 16, vertical 12)
class SkeletonStatRow extends StatelessWidget {
  const SkeletonStatRow({
    super.key,
    this.count = 3,
    this.padding,
  }) : assert(count >= 2 && count <= 6, 'count must be 2–6');

  final int count;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoadingWidget(
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            for (int i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  children: [
                    _Box(width: double.infinity, height: 20),
                    SizedBox(height: 6),
                    _Box(width: double.infinity, height: 12),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
