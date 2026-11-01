import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The address a reset code is requested for.
///
/// Follows the page's direction: an address is Latin text, and bidi already
/// lays it out left-to-right inside an RTL field (F10).
class ForgotPasswordEmailField extends StatelessWidget {
  const ForgotPasswordEmailField({
    super.key,
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
      labelText: LocaleKeys.eMail.tr(),
      hint: LocaleKeys.typeEmail.tr(),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      showRequired: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return LocaleKeys.invalidEmailAddress.tr();
        }
        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value.trim())) {
          return LocaleKeys.invalidEmailAddress.tr();
        }
        return null;
      },
    );
  }
}
