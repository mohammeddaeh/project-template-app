import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Names the address the code went to.
///
/// Without it, a user who typed their address wrong has no way to notice
/// except by waiting for an email that will never come.
class ResetCodeSentNotice extends StatelessWidget {
  const ResetCodeSentNotice({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKeys.resetCodeSentTo.tr(namedArgs: {'email': email}),
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colors.textMuted,
      ),
    );
  }
}
