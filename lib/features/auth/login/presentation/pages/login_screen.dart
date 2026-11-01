import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_template/features/auth/login/presentation/cubits/login_cubit.dart';
import 'package:app_template/features/auth/login/presentation/login_outcome.dart';
import 'package:app_template/features/auth/login/presentation/widgets/debug_skip_login_button.dart';
import 'package:app_template/features/auth/login/presentation/widgets/forgot_password_link.dart';
import 'package:app_template/features/auth/login/presentation/widgets/login_fields.dart';
import 'package:app_template/features/auth/login/presentation/widgets/login_header.dart';
import 'package:app_template/features/auth/login/presentation/widgets/login_submit_button.dart';
import 'package:app_template/features/auth/login/presentation/widgets/remembered_accounts_section.dart';
import 'package:app_template/features/auth/login/presentation/widgets/sign_up_prompt.dart';
import 'package:app_template/features/auth/shared/remembered_accounts_repository.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/ui/extensions/extensions.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/state/refresh/refresh_cubit.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
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
          builder: (context, state) => KeyboardDismissWidget(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    const LoginHeader(),
                    const RememberedAccountsSection(),
                    const SizedBox(height: 40),
                    LoginFields(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      onChanged: _refreshCubit.refresh,
                      onSubmitted: _submit,
                    ),
                    const SizedBox(height: 8),
                    const ForgotPasswordLink(),
                    const SizedBox(height: 32),
                    LoginSubmitButton(
                      refreshCubit: _refreshCubit,
                      isLoading: state is LoginLoading,
                      canSubmit: () => _isFormValid,
                      onSubmit: _submit,
                    ),
                    const SizedBox(height: 24),
                    const SignUpPrompt(),
                    if (kDebugMode) const DebugSkipLoginButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
