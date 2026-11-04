import 'package:app_template/core/foundation/utils/validators.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// The reset code, the new password, and its confirmation.
///
/// All three follow the page's direction: a code or a password is Latin text,
/// and bidi already lays it out left-to-right inside an RTL field (F10).
class ResetPasswordFields extends StatelessWidget {
  const ResetPasswordFields({
    super.key,
    required this.codeController,
    required this.passwordController,
    required this.confirmController,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController codeController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: codeController,
          labelText: LocaleKeys.resetCode.tr(),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          showRequired: true,
          onChanged: onChanged,
          validator: (value) => (value == null || value.trim().isEmpty)
              ? LocaleKeys.fieldRequired.tr()
              : null,
        ),
        const ResponsiveGap(20),
        CustomTextField(
          controller: passwordController,
          labelText: LocaleKeys.newPassword.tr(),
          isFieldObscure: true,
          textInputAction: TextInputAction.next,
          showRequired: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
          validator: _validatePassword,
        ),
        const ResponsiveGap(20),
        CustomTextField(
          controller: confirmController,
          labelText: LocaleKeys.confirmPassword.tr(),
          isFieldObscure: true,
          textInputAction: TextInputAction.done,
          showRequired: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: (value) => value != passwordController.text
              ? LocaleKeys.passwordMismatch.tr()
              : null,
        ),
      ],
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return LocaleKeys.fieldRequired.tr();
    if (!CustomRegex.passwordRegex.hasMatch(value)) {
      return LocaleKeys.passwordWeak.tr();
    }
    return null;
  }
}
