import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "Forgot password?" under the password field, aligned to the end.
class ForgotPasswordLink extends StatelessWidget {
  const ForgotPasswordLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: PrimaryButton(
        text: LocaleKeys.forgotPassword.tr(),
        isTextOnly: true,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        onTap: () => context.router.push(const ForgotPasswordRoute()),
      ),
    );
  }
}
