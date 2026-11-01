import 'dart:ui' as ui;

import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the screen asks for, and the address the code was sent to.
class VerifyEmailIntro extends StatelessWidget {
  const VerifyEmailIntro({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.verifyEmailSubtitle.tr(),
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        // LTR and selectable: an address is never Arabic text, and a user
        // comparing it against what they typed needs to be able to read every
        // character of it.
        Directionality(
          // `ui.` prefixed: easy_localization re-exports intl, which has its
          // own TextDirection and shadows Flutter's.
          textDirection: ui.TextDirection.ltr,
          child: SelectableText(
            email,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
