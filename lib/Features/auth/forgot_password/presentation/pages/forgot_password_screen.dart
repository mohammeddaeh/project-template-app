import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/Features/auth/forgot_password/presentation/cubits/forgot_password_cubit.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/shared/refresh/refresh_cubit.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/shared/widgets/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step one: ask for a reset code.
///
/// ## The confirmation deliberately does not confirm anything
///
/// On success this says "if that address is registered, we sent a code" — not
/// "we sent a code to you". The difference is the whole security property of
/// this screen: a message that only appears for real accounts turns the form
/// into a membership checker anyone can run.
///
/// It also means the button must never be disabled or the wording changed to
/// react to whether the address exists. There is nothing to react to; the app
/// does not know, on purpose.
@RoutePage()
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _refreshCubit = RefreshCubit();

  late final ForgotPasswordCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ForgotPasswordCubit>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _refreshCubit.close();
    // NOT closed here: the cubit is handed to the reset screen, which needs the
    // email it is holding. It is closed there instead — see ResetPasswordScreen.
    super.dispose();
  }

  bool get _isValid => _emailController.text.trim().isNotEmpty;

  void _submit() {
    if (_cubit.state is ForgotPasswordLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.unfocus();
    _cubit.requestReset(_emailController.text.trim());
  }

  void _onStateChanged(BuildContext context, ForgotPasswordState state) {
    state.maybeWhen(
      codeSent: () => context.router.push(ResetPasswordRoute(cubit: _cubit)),
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
      appBar: AppBar(title: Text(LocaleKeys.forgotPassword.tr())),
      body: SafeArea(
        child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
          bloc: _cubit,
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
                      Text(
                        LocaleKeys.forgotPasswordHint.tr(),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        controller: _emailController,
                        labelText: LocaleKeys.eMail.tr(),
                        hint: LocaleKeys.typeEmail.tr(),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        ltr: true,
                        showRequired: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: _refreshCubit.refresh,
                        onFieldSubmitted: _submit,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return LocaleKeys.invalidEmailAddress.tr();
                          }
                          if (!RegExp(
                            r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$',
                          ).hasMatch(value.trim())) {
                            return LocaleKeys.invalidEmailAddress.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      BlocBuilder<RefreshCubit, RefreshState>(
                        bloc: _refreshCubit,
                        builder: (context, _) => SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: LocaleKeys.sendResetCode.tr(),
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
}
