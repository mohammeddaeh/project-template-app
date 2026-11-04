import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/features/auth/shared/presentation/auth_form_body.dart';
import 'package:app_template/features/auth/register/presentation/cubits/register_cubit.dart';
import 'package:app_template/features/auth/register/presentation/widgets/register_fields.dart';
import 'package:app_template/features/auth/register/presentation/widgets/register_header.dart';
import 'package:app_template/features/auth/register/presentation/widgets/register_submit_button.dart';
import 'package:app_template/features/auth/register/presentation/widgets/sign_in_prompt.dart';
import 'package:app_template/features/auth/shared/entities/auth_user.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/ui/extensions/extensions.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/state/refresh/refresh_cubit.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// Creating an account — the step this template shipped without.
///
/// `ApiUrls.register` and a complete server endpoint both existed since the
/// backend was written, and no client code called either. A project built on
/// the template could sign in, reset a password and list its devices, but could
/// not produce the account any of that operates on except through Swagger.
///
/// ## Where it goes on success
///
/// Registration returns **no token**, so this cannot land in the app. With
/// verification required the account still needs a session to reach the code
/// screen, and only sign-in issues one — so both paths end at [LoginRoute],
/// with the address pre-filled and the reason stated. Routing to the code
/// screen directly would put an unauthenticated user in front of a form whose
/// every submission answers 401.
///
/// ## Password rules live on the server
///
/// The field validator checks length only, matching `PASSWORD_MIN_LENGTH`'s
/// floor. The composition rules (`passwordSchema` in `core/auth`) are the
/// server's, and restating them here is how the two drift — the client would
/// start refusing passwords the server accepts, or worse, the reverse. A
/// rejected password comes back as a 422 with the server's own wording.
@RoutePage()
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _refreshCubit = RefreshCubit();

  late final RegisterCubit _registerCubit;

  @override
  void initState() {
    super.initState();
    _registerCubit = getIt<RegisterCubit>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _registerCubit.close();
    _refreshCubit.close();
    super.dispose();
  }

  bool get _isFormValid =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmController.text.isNotEmpty;

  void _submit() {
    if (_registerCubit.state is RegisterLoading) return;
    if (!_formKey.validateAndReveal()) return;
    context.unfocus();
    _registerCubit.submit(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text,
    );
  }

  void _onStateChanged(BuildContext context, RegisterState state) {
    state.maybeWhen(
      success: (account) {
        // The message names what happens next, and the two cases differ: with
        // verification off the account is usable immediately, with it on
        // nothing proceeds until the code is entered. `emailVerified` is the
        // server's answer to which deployment this is — deriving it from a
        // client-side flag would be this app guessing at a server setting.
        context.feedback.success(
          account.status == AuthUserStatus.pendingVerification
              ? LocaleKeys.registerSuccess.tr()
              : LocaleKeys.loginToYourAccount.tr(),
        );
        // `replaceAll`, not `pop`: whatever was behind this screen is the
        // signed-out stack, and a back gesture returning to a filled-in
        // registration form after the account exists invites a second attempt
        // that can only fail with 409.
        context.router.replaceAll([const LoginRoute()]);
      },
      error: (message) => context.feedback.error(message),
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.colors.bgPage,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: BlocConsumer<RegisterCubit, RegisterState>(
          bloc: _registerCubit,
          listener: _onStateChanged,
          builder: (context, state) => AuthFormBody(
            padding: EdgeInsets.symmetric(
              horizontal: context.screen.space(24),
              vertical: context.screen.space(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RegisterHeader(),
                  const ResponsiveGap(32),
                  RegisterFields(
                    nameController: _nameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmController: _confirmController,
                    onChanged: _refreshCubit.refresh,
                    onSubmitted: _submit,
                  ),
                  const ResponsiveGap(32),
                  RegisterSubmitButton(
                    refreshCubit: _refreshCubit,
                    isLoading: state is RegisterLoading,
                    canSubmit: () => _isFormValid,
                    onSubmit: _submit,
                  ),
                  const ResponsiveGap(16),
                  const SignInPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
