import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/Features/auth/login/presentation/cubits/login_cubit.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/shared/refresh/refresh_cubit.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/shared/widgets/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _refreshCubit = RefreshCubit();

  late final LoginCubit _loginCubit;

  @override
  void initState() {
    super.initState();
    _loginCubit = getIt<LoginCubit>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loginCubit.close();
    _refreshCubit.close();
    super.dispose();
  }

  bool get _isFormValid =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  void _submit() {
    if (_loginCubit.state is LoginLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.unfocus();
    _loginCubit.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _onStateChanged(BuildContext context, LoginState state) {
    state.maybeWhen(
      // A successful sign-in does not always mean "go into the app".
      //
      // `pendingApproval` and `rejected` are successes at the credential level
      // and dead ends at the account level: the password was right and there is
      // nothing inside to show them. Routing them to the main shell lands them
      // on an app whose every screen refuses them, with no explanation.
      //
      // This template ships no approval flow, so everyone goes to the shell.
      // If your project has one, add a status screen and switch here:
      //
      //   switch (entity.user.status) {
      //     AuthUserStatus.pendingApproval ||
      //     AuthUserStatus.rejected => const RegistrationStatusRoute(),
      //     _ => const MainShellRoute(),
      //   }
      //
      // `pendingVerification` IS wired, because the backend ships it: such an
      // account signs in successfully and belongs on the code screen — the one
      // destination it can act on. Refusing the session instead would leave
      // someone holding an account they can neither use nor repair.
      success: (entity) => context.router.replaceAll([
        if (entity.user.status == AuthUserStatus.pendingVerification)
          VerifyEmailRoute(email: entity.user.email)
        else
          const MainShellRoute(),
      ]),
      error: (message) => context.feedback.error(message),
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.colors.bgPage,
      body: SafeArea(
        child: BlocConsumer<LoginCubit, LoginState>(
          bloc: _loginCubit,
          listener: _onStateChanged,
          builder: (context, state) {
            final isLoading = state is LoginLoading;
            return KeyboardDismissWidget(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        LocaleKeys.welcomeBack.tr(),
                        style: context.textTheme.headlineMedium?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LocaleKeys.loginToYourAccount.tr(),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 40),
                      CustomTextField(
                        controller: _emailController,
                        labelText: LocaleKeys.eMail.tr(),
                        hint: LocaleKeys.typeEmail.tr(),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        ltr: true,
                        showRequired: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: _refreshCubit.refresh,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return LocaleKeys.invalidEmailAddress.tr();
                          }
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$')
                              .hasMatch(value.trim())) {
                            return LocaleKeys.invalidEmailAddress.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _passwordController,
                        labelText: LocaleKeys.password.tr(),
                        isFieldObscure: true,
                        textInputAction: TextInputAction.done,
                        ltr: true,
                        showRequired: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: _refreshCubit.refresh,
                        onFieldSubmitted: _submit,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return LocaleKeys.passwordValidationError.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: PrimaryButton(
                          text: LocaleKeys.forgotPassword.tr(),
                          isTextOnly: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 4,
                          ),
                          onTap: () => context.router.push(
                            const ForgotPasswordRoute(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      BlocBuilder<RefreshCubit, RefreshState>(
                        bloc: _refreshCubit,
                        builder: (context, _) => SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: LocaleKeys.login.tr(),
                            isLoading: isLoading,
                            isEnabled: _isFormValid,
                            onTap: _submit,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // The sign-up link is intentionally absent: this template
                      // ships no `register/` slice, and a button that goes
                      // nowhere is worse than no button.
                      //
                      // To add one, copy the structure of `login/` (it is the
                      // reference slice — DTO, model, datasource, repository,
                      // use case, cubit, screen), then restore this row with
                      //   onTap: () => context.router.push(const RegisterRoute())
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            LocaleKeys.dontHaveAccount.tr(),
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colors.textMuted,
                            ),
                          ),
                        ],
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
