import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// The title and the line under it, at the top of the registration form.
class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.registerTitle.tr(),
          style: context.textTheme.headlineMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const ResponsiveGap(8),
        Text(
          LocaleKeys.registerSubtitle.tr(),
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
      ],
    );
  }
}
