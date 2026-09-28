import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "No account yet? Create one" under the sign-in form.
///
/// `push`, not `replace`: coming back from registration must return to a
/// sign-in screen that still has the address typed in it.
class SignUpPrompt extends StatelessWidget {
  const SignUpPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          LocaleKeys.dontHaveAccount.tr(),
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
        PrimaryButton(
          text: LocaleKeys.createAccount.tr(),
          isTextOnly: true,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: () => context.router.push(const RegisterRoute()),
        ),
      ],
    );
  }
}
