import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/features/auth/change_password/presentation/cubits/change_password_cubit.dart';
import 'package:app_template/features/auth/change_password/presentation/widgets/change_password_fields.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/ui/extensions/extensions.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/state/refresh/refresh_cubit.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/widgets/widgets.dart';
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
    if (!_formKey.validateAndReveal()) return;
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
          builder: (context, state) => KeyboardDismissWidget(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChangePasswordFields(
                      currentController: _currentController,
                      newController: _newController,
                      confirmController: _confirmController,
                      onChanged: _refreshCubit.refresh,
                      onSubmitted: _submit,
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
          ),
        ),
      ),
    );
  }
}
