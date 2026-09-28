import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/features/auth/login/presentation/cubits/login_cubit.dart';
import 'package:app_template/features/auth/login/presentation/login_outcome.dart';
import 'package:app_template/features/auth/login/presentation/widgets/account_login_header.dart';
import 'package:app_template/features/auth/shared/entities/remembered_account.dart';
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

/// Signing in as an account this device already remembers — password only
/// (`AppFeatures.rememberedAccounts`).
///
/// A pushed route rather than a step inside `LoginScreen`, so the system Back
/// gesture means "I picked the wrong person" without any bespoke handling, and
/// the account being signed into is the only thing on screen.
///
/// The whole account travels in the constructor, not just an id: the picker
/// already holds the entity, and re-reading it here would let this screen show
/// a name for an account the previous screen has since removed.
///
/// **No save prompt here.** The account is saved by definition — reaching this
/// screen requires a card. [handleLoginSuccess] refreshes it instead.
@RoutePage()
class AccountLoginScreen extends StatefulWidget {
  const AccountLoginScreen({super.key, required this.account});

  final RememberedAccount account;

  @override
  State<AccountLoginScreen> createState() => _AccountLoginScreenState();
}

class _AccountLoginScreenState extends State<AccountLoginScreen> {
  final _formKey = GlobalKey<FormState>();
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
    _passwordController.dispose();
    _loginCubit.close();
    _refreshCubit.close();
    super.dispose();
  }

  void _submit() {
    if (_loginCubit.state is LoginLoading) return;
    if (!_formKey.validateAndReveal()) return;
    context.unfocus();
    _loginCubit.login(
      // From the saved card, never from a field — there is nothing here for the
      // user to mistype, which is the entire point of the screen.
      email: widget.account.email,
      password: _passwordController.text,
    );
  }

  void _onStateChanged(BuildContext context, LoginState state) {
    state.maybeWhen(
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
      appBar: AppBar(backgroundColor: context.colors.bgPage),
      body: SafeArea(
        child: BlocConsumer<LoginCubit, LoginState>(
          bloc: _loginCubit,
          listener: _onStateChanged,
          builder: (context, state) => KeyboardDismissWidget(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                32 + context.bottomContentInset,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AccountLoginHeader(account: widget.account),
                    const SizedBox(height: 32),
                    _PasswordField(
                      controller: _passwordController,
                      onChanged: _refreshCubit.refresh,
                      onSubmitted: _submit,
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<RefreshCubit, RefreshState>(
                      bloc: _refreshCubit,
                      builder: (context, _) => _AccountLoginActions(
                        isLoading: state is LoginLoading,
                        canSubmit: _passwordController.text.isNotEmpty,
                        onSubmit: _submit,
                      ),
                    ),
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: LocaleKeys.password.tr(),
      isFieldObscure: true,
      textInputAction: TextInputAction.done,
      showRequired: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: (value) => value == null || value.isEmpty
          ? LocaleKeys.passwordValidationError.tr()
          : null,
    );
  }
}

/// Forgot password · continue · "not this account" (Back, in words).
class _AccountLoginActions extends StatelessWidget {
  const _AccountLoginActions({
    required this.isLoading,
    required this.canSubmit,
    required this.onSubmit,
  });

  final bool isLoading;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: PrimaryButton(
            text: LocaleKeys.forgotPassword.tr(),
            isTextOnly: true,
            onTap: () => context.router.push(const ForgotPasswordRoute()),
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: LocaleKeys.continueLabel.tr(),
          isLoading: isLoading,
          isEnabled: canSubmit,
          onTap: onSubmit,
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: LocaleKeys.notThisAccount.tr(),
          isTextOnly: true,
          onTap: () => context.router.maybePop(),
        ),
      ],
    );
  }
}
