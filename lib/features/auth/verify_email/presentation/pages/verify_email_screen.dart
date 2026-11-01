import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/features/auth/verify_email/presentation/cubits/verify_email_cubit.dart';
import 'package:app_template/features/auth/verify_email/presentation/widgets/verify_email_actions.dart';
import 'package:app_template/features/auth/verify_email/presentation/widgets/verify_email_code_field.dart';
import 'package:app_template/features/auth/verify_email/presentation/widgets/verify_email_intro.dart';
import 'package:app_template/features/auth/verify_email/presentation/widgets/verify_email_why_card.dart';
import 'package:app_template/ui/extensions/extensions.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/state/refresh/refresh_cubit.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Where a `pending_verification` account proves it owns its email address.
///
/// ## Why this screen exists behind a real session
///
/// An unverified account signs in successfully — deliberately. The code screen
/// lives inside the app, so refusing the session would leave someone holding an
/// account they can neither use nor repair (the common case being a reinstall,
/// after the original registration response is long gone). The session unlocks
/// nothing else: such an account holds no role assignment, so its permission
/// set is empty and every protected endpoint refuses it anyway.
///
/// ## Why it is not a dead end
///
/// Three ways out, because a screen that can only be satisfied one way traps
/// anyone that way fails: enter the code · request a new one (the previous is
/// then void) · sign out. The last matters more than it looks — someone who
/// registered with the wrong address has no other escape, and without it their
/// only recourse is deleting the app.
@RoutePage()
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  /// Shown so a user who mistyped their address can notice. Display only — the
  /// server identifies the account from the session, never from this.
  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _refreshCubit = RefreshCubit();

  late final VerifyEmailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<VerifyEmailCubit>();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _refreshCubit.close();
    _cubit.close();
    super.dispose();
  }

  bool get _isValid => _codeController.text.trim().isNotEmpty;

  void _submit() {
    if (_cubit.state is VerifyEmailLoading) return;
    if (!_formKey.validateAndReveal()) return;
    context.unfocus();
    _cubit.verify(_codeController.text.trim());
  }

  void _onStateChanged(BuildContext context, VerifyEmailState state) {
    state.maybeWhen(
      verified: (user) {
        context.feedback.success(LocaleKeys.verifyEmailSuccess.tr());
        // Routes on the status the SERVER just returned, not on the transition
        // this screen assumes verification causes. `replaceAll` because the
        // journey is over — leaving this screen on the stack would let the user
        // walk back into a step they have completed.
        // `backend_template` advances a verified account straight to `active`,
        // so the destination is simply Home.
        //
        // **If your project adds an approval step**, branch on `user.status`
        // here — `pendingApproval` and `rejected` belong on a status screen,
        // not inside the app. Prefer an exhaustive `switch` over a default, so
        // the compiler names this spot the day you add a state:
        //
        // ```dart
        // context.router.replaceAll([
        //   switch (user.status) {
        //     AuthUserStatus.pendingApproval ||
        //     AuthUserStatus.rejected => const RegistrationStatusRoute(),
        //     _ => const HomeRoute(),
        //   },
        // ]);
        // ```
        context.router.replaceAll([const HomeRoute()]);
      },
      codeResent: () =>
          context.feedback.success(LocaleKeys.verifyEmailResent.tr()),
      error: (message) => context.feedback.error(message),
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return Scaffold(
      backgroundColor: context.colors.bgPage,
      appBar: AppBar(title: Text(LocaleKeys.verifyEmailTitle.tr())),
      body: SafeArea(
        child: BlocConsumer<VerifyEmailCubit, VerifyEmailState>(
          bloc: _cubit,
          listener: _onStateChanged,
          builder: (context, state) {
            final isLoading = state is VerifyEmailLoading;
            return KeyboardDismissWidget(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VerifyEmailIntro(email: widget.email),
                      const SizedBox(height: 24),
                      const VerifyEmailWhyCard(),
                      const SizedBox(height: 24),
                      VerifyEmailCodeField(
                        controller: _codeController,
                        onChanged: _refreshCubit.refresh,
                        onSubmitted: _submit,
                      ),
                      const SizedBox(height: 28),
                      VerifyEmailActions(
                        refreshCubit: _refreshCubit,
                        isLoading: isLoading,
                        canSubmit: () => _isValid,
                        onSubmit: _submit,
                        secondsLeft: _cubit.secondsUntilResend,
                        onResend: _cubit.resend,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
