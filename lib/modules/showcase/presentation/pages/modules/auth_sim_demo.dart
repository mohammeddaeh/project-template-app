import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/sim_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/app_feedback_service.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The sign-in flow of `features/auth/` rebuilt on the device: the same fields
/// and validation, a fake check, and the signed-in account card. Then the
/// three [AuthMode]s that decide where sign-in appears at all.
class AuthSimDemo extends StatefulWidget {
  const AuthSimDemo({super.key});

  @override
  State<AuthSimDemo> createState() => _AuthSimDemoState();
}

class _AuthSimDemoState extends State<AuthSimDemo> {
  static const _password = '123456';

  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _signedIn;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    // Stands in for the round trip to /api/v1/auth/login.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_pass.text == _password) {
      setState(() {
        _loading = false;
        _signedIn = _email.text.trim();
      });
      return;
    }
    final message = LocaleKeys.showcaseAuthSimInvalid.tr();
    setState(() {
      _loading = false;
      _error = message;
    });
    // The real screen reports a refused sign-in as a toast.
    if (getIt.isRegistered<AppFeedbackService>()) {
      context.feedback.error(message);
    }
  }

  void _signOut() => setState(() {
    _signedIn = null;
    _pass.clear();
  });

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty || !RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) {
      return LocaleKeys.invalidEmailAddress.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final motion = AppMotion.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SimNotice(),
        DemoBlock(
          code: 'LoginScreen · LoginCubit.login(email, password)',
          child: AnimatedSwitcher(
            duration: motion.base,
            child: _signedIn == null ? _buildForm() : _buildAccount(),
          ),
        ),
        DemoBlock(
          code: 'AppFeatures.authMode = AuthMode.…',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final mode in AuthMode.values)
                AppListTile(
                  titleText: mode.name,
                  subtitleText: switch (mode) {
                    AuthMode.none => LocaleKeys.showcaseAuthSimModeNone.tr(),
                    AuthMode.required =>
                      LocaleKeys.showcaseAuthSimModeRequired.tr(),
                    AuthMode.optional =>
                      LocaleKeys.showcaseAuthSimModeOptional.tr(),
                  },
                  leadingIcon: switch (mode) {
                    AuthMode.none => Icons.lock_open_outlined,
                    AuthMode.required => Icons.lock_outline,
                    AuthMode.optional => Icons.person_outline,
                  },
                  trailing: mode == AppFeatures.authMode
                      ? const StatusChip(labelText: '✓', tone: StatusTone.info)
                      : null,
                  showDivider: mode != AuthMode.values.last,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm() => Form(
    key: _form,
    child: Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKeys.showcaseAuthSimHint.tr(),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
        12.heightBox,
        CustomTextField(
          controller: _email,
          labelText: LocaleKeys.eMail.tr(),
          hint: LocaleKeys.typeEmail.tr(),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          showRequired: true,
          validator: _validateEmail,
        ),
        16.heightBox,
        CustomTextField(
          controller: _pass,
          labelText: LocaleKeys.password.tr(),
          isFieldObscure: true,
          textInputAction: TextInputAction.done,
          showRequired: true,
          onFieldSubmitted: _submit,
          validator: (v) =>
              (v == null || v.isEmpty) ? LocaleKeys.fieldRequired.tr() : null,
        ),
        if (_error != null) ...[
          12.heightBox,
          Text(
            _error!,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.feedbackError,
            ),
          ),
        ],
        16.heightBox,
        PrimaryButton(
          text: LocaleKeys.login.tr(),
          isLoading: _loading,
          onTap: _submit,
        ),
      ],
    ),
  );

  Widget _buildAccount() {
    final email = _signedIn!;
    final name = email.split('@').first;
    return Column(
      key: const ValueKey('account'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AvatarWidget(initial: name.isEmpty ? '?' : name[0].toUpperCase()),
            12.widthBox,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: context.textTheme.titleMedium),
                  Text(
                    email,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(
              labelText: LocaleKeys.showcaseAuthSimSignedIn.tr(),
              tone: StatusTone.success,
            ),
          ],
        ),
        16.heightBox,
        AppButton(
          text: LocaleKeys.logOut.tr(),
          variant: AppButtonVariant.outlined,
          leadingIcon: Icons.logout,
          onTap: _signOut,
        ),
      ],
    );
  }
}
