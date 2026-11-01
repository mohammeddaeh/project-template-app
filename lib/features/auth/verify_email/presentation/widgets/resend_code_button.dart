import 'package:app_template/resources/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "Send a new code", with the cooldown counted down on the button itself.
///
/// Disabled during the cooldown rather than hidden: a button that vanishes
/// reads as a bug, while one that says how long is left answers the question
/// the user is actually asking.
class ResendCodeButton extends StatelessWidget {
  const ResendCodeButton({
    super.key,
    required this.secondsLeft,
    required this.isLoading,
    required this.onResend,
  });

  final int secondsLeft;
  final bool isLoading;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: secondsLeft > 0 || isLoading ? null : onResend,
        child: Text(
          secondsLeft > 0
              ? LocaleKeys.verifyEmailResendIn.tr(args: ['$secondsLeft'])
              : LocaleKeys.verifyEmailResend.tr(),
        ),
      ),
    );
  }
}
