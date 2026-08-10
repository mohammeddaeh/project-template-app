import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/Features/auth/change_password/presentation/cubits/change_password_cubit.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/foundation/utils/validators.dart';
import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/shared/refresh/refresh_cubit.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Changing your own password while signed in.
///
/// Distinct from the forgot-password journey in one way that matters: the user
/// is already authenticated, so the current password is asked for as **proof of
/// identity**, not as a lookup key. See [ChangePasswordDto.currentPassword].
///
/// On success it pops rather than signing the user out. Whether other sessions
/// should be revoked is a server-side decision — if your backend invalidates
/// them, the other devices will hit a 401 and route themselves to login through
/// `AuthEventBus`, with nothing needed here.
@RoutePage()
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _refreshCubit = RefreshCubit();

  late final ChangePasswordCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ChangePasswordCubit>();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _refreshCubit.close();
    _cubit.close();
    super.dispose();
  }

  bool get _isValid =>
      _currentController.text.isNotEmpty &&
      _newController.text.isNotEmpty &&
      _confirmController.text.isNotEmpty;

  void _submit() {
    if (_cubit.state is ChangePasswordLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.unfocus();
    _cubit.submit(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
  }

  void _onStateChanged(BuildContext context, ChangePasswordState state) {
    state.maybeWhen(
      success: () {
        context.feedback.success(LocaleKeys.passwordChangedSuccess.tr());
        context.router.maybePop();
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
      appBar: AppBar(title: Text(LocaleKeys.changePassword.tr())),
      body: SafeArea(
        child: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
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
                      CustomTextField(
                        controller: _currentController,
                        labelText: LocaleKeys.currentPassword.tr(),
                        isFieldObscure: true,
                        textInputAction: TextInputAction.next,
                        ltr: true,
                        showRequired: true,
                        onChanged: _refreshCubit.refresh,
                        validator: (value) =>
                            (value == null || value.isEmpty)
                            ? LocaleKeys.fieldRequired.tr()
                            : null,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _newController,
                        labelText: LocaleKeys.newPassword.tr(),
                        isFieldObscure: true,
                        textInputAction: TextInputAction.next,
                        ltr: true,
                        showRequired: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: _refreshCubit.refresh,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return LocaleKeys.fieldRequired.tr();
                          }
                          if (!CustomRegex.passwordRegex.hasMatch(value)) {
                            return LocaleKeys.passwordWeak.tr();
                          }
                          // Caught here rather than by the server, because the
                          // server's rejection would arrive as a generic 422
                          // and read like the request failed.
                          if (value == _currentController.text) {
                            return LocaleKeys.passwordMustDiffer.tr();
                          }
                          return null;
                        },
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
                        validator: (value) => value != _newController.text
                            ? LocaleKeys.passwordMismatch.tr()
                            : null,
                      ),
                      const SizedBox(height: 32),
                      BlocBuilder<RefreshCubit, RefreshState>(
                        bloc: _refreshCubit,
                        builder: (context, _) => SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: LocaleKeys.changePassword.tr(),
                            isLoading: state is ChangePasswordLoading,
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
