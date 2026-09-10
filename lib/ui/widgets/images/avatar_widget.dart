import 'package:flutter/material.dart';
import 'package:app_template/ui/widgets/placeholders/skeleton_scope.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

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

    // داخل [Skeletonized] يرسم نفسَه قرصاً **بنفس القطر** — والأحرفُ الأولى
    // بيانةٌ من الشبكة كغيرها. وخارجها [Bone] تمريرةٌ صافية.
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Bone.circle(
        child: CircleAvatar(
        radius: radius,
          backgroundImage: NetworkImage(imageUrl!),
          backgroundColor: bg,
        ),
      );
    }

    return Bone.circle(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Text(
          (initial ?? '?').isNotEmpty
              ? (initial ?? '?').toUpperCase().substring(0, 1)
              : '?',
          style: textTheme.titleLarge?.copyWith(color: fg),
        ),
      ),
    );
  }
}
