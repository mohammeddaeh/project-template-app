import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// Name, email, password, and its confirmation.
///
/// The email and password fields follow the page's direction: Latin text that
/// bidi already lays out left-to-right inside an RTL field (F10).
///
/// The password validator checks length only — see `RegisterScreen`'s doc for
/// why the composition rules are the server's and not restated here.
class RegisterFields extends StatelessWidget {
  const RegisterFields({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
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
          controller: nameController,
          labelText: LocaleKeys.fullNameOptional.tr(),
          hint: LocaleKeys.typeFullName.tr(),
          textInputAction: TextInputAction.next,
          // No validator, and none is missing: the column is nullable
          // server-side. A required-here/optional-there mismatch is the client
          // inventing a rule.
        ),
        const ResponsiveGap(20),
        CustomTextField(
          controller: emailController,
          labelText: LocaleKeys.eMail.tr(),
          hint: LocaleKeys.typeEmail.tr(),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          showRequired: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
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
        const ResponsiveGap(20),
        CustomTextField(
          controller: passwordController,
          labelText: LocaleKeys.password.tr(),
          isFieldObscure: true,
          textInputAction: TextInputAction.next,
          showRequired: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocaleKeys.passwordValidationError.tr();
            }
            if (value.length < 8) {
              return LocaleKeys.passwordValidationError.tr();
            }
            return null;
          },
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
          // Checked here and nowhere else: the server never sees this field,
          // because a confirmation box is a guard against a typo on this
          // device, not a fact about the account.
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocaleKeys.passwordValidationError.tr();
            }
            if (value != passwordController.text) {
              return LocaleKeys.passwordsDoNotMatch.tr();
            }
            return null;
          },
        ),
      ],
    );
  }
}
