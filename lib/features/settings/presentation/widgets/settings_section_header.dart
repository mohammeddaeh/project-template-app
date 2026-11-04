import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// عنوان قسمٍ بشاشة الإعدادات.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.screen.space(16),
        context.screen.space(20),
        context.screen.space(16),
        context.screen.space(4),
      ),
      child: Text(
        title,
        style: context.textTheme.labelMedium?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
