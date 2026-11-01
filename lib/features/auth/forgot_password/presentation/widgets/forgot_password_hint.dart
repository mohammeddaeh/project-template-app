import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The line above the email field explaining what the form does.
class ForgotPasswordHint extends StatelessWidget {
  const ForgotPasswordHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKeys.forgotPasswordHint.tr(),
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colors.textMuted,
      ),
    );
  }
}
