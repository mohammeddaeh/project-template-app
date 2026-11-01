import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Explains why the app is asking, in one short card.
///
/// Present because the step is otherwise unexplained friction — the user just
/// finished a form and is being asked to do more before anything happens. One
/// sentence naming what it buys ("nobody can register with an address they do
/// not own") converts an obstacle into a reason.
class VerifyEmailWhyCard extends StatelessWidget {
  const VerifyEmailWhyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.statusInfoBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: colors.statusInfoFg),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.verifyEmailWhyTitle.tr(),
                style: context.textTheme.labelLarge?.copyWith(
                  color: colors.statusInfoFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.verifyEmailWhyBody.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
