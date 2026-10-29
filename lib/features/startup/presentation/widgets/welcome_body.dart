import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/resources/assets.gen.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/images/app_asset_image.dart';
import 'package:app_template/ui/widgets/layout/app_button.dart';

/// جسدُ شاشة الترحيب: الشعار · العنوان · الجملة · زرّ البدء.
///
/// **الشعار بألوانه** (بلا `color`): هو نفسه ما يرسمه splash النظام فوق
/// `bgBrand`، فينتقل المستخدم من الإقلاع إلى الترحيب بلا قفزة لون.
class WelcomeBody extends StatelessWidget {
  const WelcomeBody({required this.onStart, super.key});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — registers this element for locale changes
    context.locale;
    final s = context.screen;
    final colors = context.colors;

    return Column(
      children: [
        const Spacer(),
        AppAssetImage(Assets.images.brand.appLogoSvg, height: s.size(132)),
        const ResponsiveGap(32),
        Text(
          LocaleKeys.welcomeTitle.tr(),
          textAlign: TextAlign.center,
          style: context.textTheme.headlineLarge?.copyWith(
            color: colors.onBrand,
          ),
        ),
        const ResponsiveGap(12),
        Text(
          LocaleKeys.welcomeBody.tr(),
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(color: colors.onBrand),
        ),
        const Spacer(),
        AppButton(
          text: LocaleKeys.welcomeStart.tr(),
          variant: AppButtonVariant.tonal,
          width: double.infinity,
          onTap: onStart,
        ),
        const ResponsiveGap(24),
      ],
    );
  }
}
