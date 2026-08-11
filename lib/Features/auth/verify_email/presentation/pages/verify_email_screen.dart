import 'dart:ui' as ui;

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/Features/auth/logout/presentation/widgets/logout_section.dart';
import 'package:app_template/Features/auth/verify_email/presentation/cubits/verify_email_cubit.dart';
import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/shared/refresh/refresh_cubit.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/shared/widgets/widgets.dart';

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
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
      codeResent: () => context.feedback.success(
        LocaleKeys.verifyEmailResent.tr(),
      ),
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
            final secondsLeft = _cubit.secondsUntilResend;

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
                      Text(
                        LocaleKeys.verifyEmailSubtitle.tr(),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // LTR and selectable: an address is never Arabic text, and
                      // a user comparing it against what they typed needs to be
                      // able to read every character of it.
                      Directionality(
                        // `ui.` prefixed: easy_localization re-exports intl,
                        // which has its own TextDirection and shadows Flutter's.
                        textDirection: ui.TextDirection.ltr,
                        child: SelectableText(
                          widget.email,
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _WhyCard(),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _codeController,
                        labelText: LocaleKeys.verifyEmailHint.tr(),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        ltr: true,
                        showRequired: true,
                        // No forced upper-casing: the server normalises case
                        // and trims whitespace before hashing, so a lower-case
                        // paste out of a mail client is the right code entered
                        // correctly. Rejecting it on presentation would be
                        // refusing a correct answer on a technicality.
                        onChanged: _refreshCubit.refresh,
                        onFieldSubmitted: _submit,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? LocaleKeys.verifyEmailCodeRequired.tr()
                                : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        LocaleKeys.verifyEmailCheckSpam.tr(),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 28),
                      BlocBuilder<RefreshCubit, RefreshState>(
                        bloc: _refreshCubit,
                        builder: (context, _) => SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: LocaleKeys.verifyEmailCta.tr(),
                            isLoading: isLoading,
                            isEnabled: _isValid,
                            onTap: _submit,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          // Disabled during the cooldown rather than hidden: a
                          // button that vanishes reads as a bug, while one that
                          // says how long is left answers the question the user
                          // is actually asking.
                          onPressed: secondsLeft > 0 || isLoading
                              ? null
                              : _cubit.resend,
                          child: Text(
                            secondsLeft > 0
                                ? LocaleKeys.verifyEmailResendIn.tr(
                                    args: ['$secondsLeft'],
                                  )
                                : LocaleKeys.verifyEmailResend.tr(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // The way out for someone who registered with the wrong
                      // address. Without it this screen is a trap: the code can
                      // only arrive somewhere they cannot read.
                      const LogoutSection(),
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

/// Explains why the app is asking, in one short card.
///
/// Present because the step is otherwise unexplained friction — the user just
/// finished a form and is being asked to do more before anything happens. One
/// sentence naming what it buys ("nobody can register with an address they do
/// not own") converts an obstacle into a reason.
class _WhyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.statusInfoBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: colors.statusInfoFg),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.verifyEmailWhyTitle.tr(),
                style: context.textTheme.labelLarge?.copyWith(
                  color: colors.statusInfoFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.verifyEmailWhyBody.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
