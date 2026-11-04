import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// The email and password fields of the sign-in form.
///
/// Both follow the page's direction: an address or a password is Latin text,
/// and bidi already lays it out left-to-right inside an RTL field (F10).
class LoginFields extends StatelessWidget {
  const LoginFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          textInputAction: TextInputAction.done,
          showRequired: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocaleKeys.passwordValidationError.tr();
            }
            return null;
          },
        ),
      ],
    );
  }
}
