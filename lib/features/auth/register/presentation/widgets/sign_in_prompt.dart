import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "Already have an account? Sign in" under the registration form.
///
/// `maybePop`: registration is pushed from the sign-in screen, so going back
/// is going to sign in — with whatever was typed there still in place.
class SignInPrompt extends StatelessWidget {
  const SignInPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          LocaleKeys.alreadyHaveAccount.tr(),
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
        PrimaryButton(
          text: LocaleKeys.signIn.tr(),
          isTextOnly: true,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: () => context.router.maybePop(),
        ),
      ],
    );
  }
}
