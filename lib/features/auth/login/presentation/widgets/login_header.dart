import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// "Welcome back" and the line under it, at the top of the sign-in form.
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.welcomeBack.tr(),
          style: context.textTheme.headlineMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const ResponsiveGap(8),
        Text(
          LocaleKeys.loginToYourAccount.tr(),
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
      ],
    );
  }
}
