import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The verification code field, and the "check your spam folder" line under it.
///
/// Follows the page's direction: a code is Latin text, and bidi already lays it
/// out left-to-right inside an RTL field (F10).
class VerifyEmailCodeField extends StatelessWidget {
  const VerifyEmailCodeField({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: controller,
          labelText: LocaleKeys.verifyEmailHint.tr(),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          showRequired: true,
          // No forced upper-casing: the server normalises case and trims
          // whitespace before hashing, so a lower-case paste out of a mail
          // client is the right code entered correctly. Rejecting it on
          // presentation would be refusing a correct answer on a technicality.
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: (value) => (value == null || value.trim().isEmpty)
              ? LocaleKeys.verifyEmailCodeRequired.tr()
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          LocaleKeys.verifyEmailCheckSpam.tr(),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
      ],
    );
  }
}
