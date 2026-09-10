import 'package:flutter/material.dart';

class ImagePlaceholderWidget extends StatelessWidget {
  const ImagePlaceholderWidget({
    super.key,
    this.icon = Icons.image_outlined,
    this.size = 64,
  });

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: size * 0.5, color: scheme.outline),
    );
  }
}
