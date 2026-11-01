import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// الفاصل بين أقسام شاشة الإعدادات.
class SettingsSectionDivider extends StatelessWidget {
  const SettingsSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.colors.dividerSubtle,
    );
  }
}
