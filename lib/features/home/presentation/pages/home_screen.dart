import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/showcase/presentation/showcase_view.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// The Home tab — a **deliberate placeholder**, and the first screen a signed-in
/// user of a fresh project sees.
///
/// It is a placeholder because a template cannot know what an application's
/// home screen is — but a correct one: localized, themed and built from the
/// widget barrel. This is the most-read screen in the app, and a reader copies
/// what the codebase does, not what its documentation says.
///
/// **Replace the body wholesale** when this project has a real home.
///
/// While [AppFeatures.showcase] is on, the tab shows the template's tour
/// ([ShowcaseView]) instead — turn the flag off with the real home.
@RoutePage(name: 'HomeRoute')
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — registers this element for locale changes
    context.locale;

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.tabHome.tr())),
      body: AppFeatures.showcase ? const ShowcaseView() : const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — registers this element for locale changes
    context.locale;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.screen.space(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.widgets_outlined,
              size: 56,
              color: context.colors.textMuted,
            ),
            const ResponsiveGap(16),
            Text(
              LocaleKeys.welcomeBack.tr(),
              style: context.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const ResponsiveGap(8),
            Text(
              LocaleKeys.homeSubtitle.tr(),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
