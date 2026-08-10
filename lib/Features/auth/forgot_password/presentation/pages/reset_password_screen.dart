import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/Features/auth/forgot_password/presentation/cubits/forgot_password_cubit.dart';
import 'package:app_template/core/foundation/utils/validators.dart';
import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/shared/refresh/refresh_cubit.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/shared/widgets/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step two: enter the code and choose a new password.
///
/// ## Why a typed code and not a deep link
///
/// A link is nicer when it works, and it needs deep linking configured, a
/// verified domain, and a fallback for the mail client that strips it. A code
/// the user types works on every device and every mail client on day one, and a
/// deep link can be added later to prefill this field rather than replace it.
///
/// ## Why the cubit arrives as an argument
///
/// It carries the email from the previous screen. Passing the address through
/// the route instead would mean trusting a value anyone can edit, and asking
/// for it a second time would make the user prove they remember what they just
/// typed.
@RoutePage()
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.cubit});

  final ForgotPasswordCubit cubit;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _refreshCubit = RefreshCubit();

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _refreshCubit.close();
    // Owned here because this is where the journey ends — the screen that
    // created it deliberately left it open so this one could read the email.
    widget.cubit.close();
    super.dispose();
  }

  bool get _isValid =>
      _codeController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmController.text.isNotEmpty;

  void _submit() {
    if (widget.cubit.state is ForgotPasswordLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.unfocus();
    widget.cubit.resetPassword(
      token: _codeController.text.trim(),
      newPassword: _passwordController.text,
    );
  }

  void _onStateChanged(BuildContext context, ForgotPasswordState state) {
    state.maybeWhen(
      // `replaceAll`, not `pop`: the password just changed, so every screen
      // behind this one belongs to a journey that is over. Popping would leave
      // the forgot-password form on the stack for the user to walk back into.
      success: () {
        context.feedback.success(LocaleKeys.passwordChangedSuccess.tr());
        context.router.replaceAll([const LoginRoute()]);
      },
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
      appBar: AppBar(title: Text(LocaleKeys.resetPassword.tr())),
      body: SafeArea(
        child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
          bloc: widget.cubit,
          listener: _onStateChanged,
          builder: (context, state) {
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
                      // Names the address the code went to. Without it, a user
                      // who typed their address wrong has no way to notice
                      // except by waiting for an email that will never come.
                      Text(
                        LocaleKeys.resetCodeSentTo.tr(
                          namedArgs: {'email': widget.cubit.email ?? ''},
                        ),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        controller: _codeController,
                        labelText: LocaleKeys.resetCode.tr(),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        ltr: true,
                        showRequired: true,
                        onChanged: _refreshCubit.refresh,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? LocaleKeys.fieldRequired.tr()
                            : null,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _passwordController,
                        labelText: LocaleKeys.newPassword.tr(),
                        isFieldObscure: true,
                        textInputAction: TextInputAction.next,
                        ltr: true,
                        showRequired: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: _refreshCubit.refresh,
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _confirmController,
                        labelText: LocaleKeys.confirmPassword.tr(),
                        isFieldObscure: true,
                        textInputAction: TextInputAction.done,
                        ltr: true,
                        showRequired: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: _refreshCubit.refresh,
                        onFieldSubmitted: _submit,
                        validator: (value) => value != _passwordController.text
                            ? LocaleKeys.passwordMismatch.tr()
                            : null,
                      ),
                      const SizedBox(height: 32),
                      BlocBuilder<RefreshCubit, RefreshState>(
                        bloc: _refreshCubit,
                        builder: (context, _) => SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: LocaleKeys.resetPassword.tr(),
                            isLoading: state is ForgotPasswordLoading,
                            isEnabled: _isValid,
                            onTap: _submit,
                          ),
                        ),
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return LocaleKeys.fieldRequired.tr();
    if (!CustomRegex.passwordRegex.hasMatch(value)) {
      return LocaleKeys.passwordWeak.tr();
    }
    return null;
  }
}
