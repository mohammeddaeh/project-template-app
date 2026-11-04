import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/features/auth/shared/presentation/auth_form_body.dart';
import 'package:app_template/features/auth/forgot_password/presentation/cubits/forgot_password_cubit.dart';
import 'package:app_template/features/auth/forgot_password/presentation/widgets/reset_code_sent_notice.dart';
import 'package:app_template/features/auth/forgot_password/presentation/widgets/reset_password_fields.dart';
import 'package:app_template/ui/extensions/extensions.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/state/refresh/refresh_cubit.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/ui/responsive/responsive.dart';

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
    if (!_formKey.validateAndReveal()) return;
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
          builder: (context, state) => AuthFormBody(
            padding: EdgeInsets.symmetric(
              horizontal: context.screen.space(24),
              vertical: context.screen.space(24),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResetCodeSentNotice(email: widget.cubit.email ?? ''),
                  const ResponsiveGap(32),
                  ResetPasswordFields(
                    codeController: _codeController,
                    passwordController: _passwordController,
                    confirmController: _confirmController,
                    onChanged: _refreshCubit.refresh,
                    onSubmitted: _submit,
                  ),
                  const ResponsiveGap(32),
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
        ),
      ),
    );
  }
}
