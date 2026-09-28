import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_template/features/auth/login/presentation/cubits/login_cubit.dart';
import 'package:app_template/features/auth/login/presentation/login_outcome.dart';
import 'package:app_template/features/auth/login/presentation/widgets/remembered_accounts_section.dart';
import 'package:app_template/features/auth/login/presentation/widgets/sign_up_prompt.dart';
import 'package:app_template/features/auth/shared/remembered_accounts_repository.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/ui/extensions/extensions.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/state/refresh/refresh_cubit.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/widgets/widgets.dart';
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
  late final RememberedAccountsRepository _remembered;

  @override
  void initState() {
    super.initState();
    _loginCubit = getIt<LoginCubit>();
    _remembered = getIt<RememberedAccountsRepository>();
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
    if (!_formKey.validateAndReveal()) return;
    context.unfocus();
    _loginCubit.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _onStateChanged(BuildContext context, LoginState state) {
    state.maybeWhen(
      // Where each account status lands — and the save prompt — live in
      // `handleLoginSuccess`, shared with `AccountLoginScreen`. See there.
      success: (entity) => unawaited(
        handleLoginSuccess(context, entity, remembered: _remembered),
      ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
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
                      const RememberedAccountsSection(),
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
                          if (!RegExp(
                            r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$',
                          ).hasMatch(value.trim())) {
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
                          onTap: () =>
                              context.router.push(const ForgotPasswordRoute()),
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
                      const SignUpPrompt(),
                      if (kDebugMode)
                        Center(
                          child: PrimaryButton(
                            text: LocaleKeys.skipLoginDebug.tr(),
                            isTextOnly: true,
                            onTap: () => context.router.replaceAll([
                              const MainShellRoute(),
                            ]),
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
