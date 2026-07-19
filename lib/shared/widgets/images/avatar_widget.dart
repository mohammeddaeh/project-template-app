import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.initial,
    this.radius = 24,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? imageUrl;
  final String? initial;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    final bg = backgroundColor ?? scheme.primaryContainer;
    final fg = foregroundColor ?? scheme.onPrimaryContainer;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: bg,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        (initial ?? '?').isNotEmpty
            ? (initial ?? '?').toUpperCase().substring(0, 1)
            : '?',
        style: textTheme.titleLarge?.copyWith(color: fg),
      ),
    );
  }
}
