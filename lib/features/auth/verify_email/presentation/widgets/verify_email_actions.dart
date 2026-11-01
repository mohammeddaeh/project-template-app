import 'package:app_template/features/auth/logout/presentation/widgets/logout_section.dart';
import 'package:app_template/features/auth/verify_email/presentation/widgets/resend_code_button.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/state/refresh/refresh_cubit.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The three ways out of the screen: verify · request a new code · sign out.
///
/// [canSubmit] is a getter, read each time [refreshCubit] ticks — a plain
/// `bool` would freeze the value the page had when it last built.
class VerifyEmailActions extends StatelessWidget {
  const VerifyEmailActions({
    super.key,
    required this.refreshCubit,
    required this.isLoading,
    required this.canSubmit,
    required this.onSubmit,
    required this.secondsLeft,
    required this.onResend,
  });

  final RefreshCubit refreshCubit;
  final bool isLoading;
  final ValueGetter<bool> canSubmit;
  final VoidCallback onSubmit;
  final int secondsLeft;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<RefreshCubit, RefreshState>(
          bloc: refreshCubit,
          builder: (context, _) => SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: LocaleKeys.verifyEmailCta.tr(),
              isLoading: isLoading,
              isEnabled: canSubmit(),
              onTap: onSubmit,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ResendCodeButton(
          secondsLeft: secondsLeft,
          isLoading: isLoading,
          onResend: onResend,
        ),
        const SizedBox(height: 32),
        // The way out for someone who registered with the wrong address.
        // Without it this screen is a trap: the code can only arrive somewhere
        // they cannot read.
        const LogoutSection(),
      ],
    );
  }
}
