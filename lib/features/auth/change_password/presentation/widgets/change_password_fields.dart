import 'package:app_template/core/foundation/utils/validators.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The current password, the new one, and its confirmation.
///
/// All three follow the page's direction: a password is Latin text, and bidi
/// already lays it out left-to-right inside an RTL field (F10).
class ChangePasswordFields extends StatelessWidget {
  const ChangePasswordFields({
    super.key,
    required this.currentController,
    required this.newController,
    required this.confirmController,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController currentController;
  final TextEditingController newController;
  final TextEditingController confirmController;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: currentController,
          labelText: LocaleKeys.currentPassword.tr(),
          isFieldObscure: true,
          textInputAction: TextInputAction.next,
          showRequired: true,
          onChanged: onChanged,
          validator: (value) => (value == null || value.isEmpty)
              ? LocaleKeys.fieldRequired.tr()
              : null,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: newController,
          labelText: LocaleKeys.newPassword.tr(),
          isFieldObscure: true,
          textInputAction: TextInputAction.next,
          showRequired: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocaleKeys.fieldRequired.tr();
            }
            if (!CustomRegex.passwordRegex.hasMatch(value)) {
              return LocaleKeys.passwordWeak.tr();
            }
            // Caught here rather than by the server, because the server's
            // rejection would arrive as a generic 422 and read like the
            // request failed.
            if (value == currentController.text) {
              return LocaleKeys.passwordMustDiffer.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: confirmController,
          labelText: LocaleKeys.confirmPassword.tr(),
          isFieldObscure: true,
          textInputAction: TextInputAction.done,
          showRequired: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: (value) => value != newController.text
              ? LocaleKeys.passwordMismatch.tr()
              : null,
        ),
      ],
    );
  }
}
