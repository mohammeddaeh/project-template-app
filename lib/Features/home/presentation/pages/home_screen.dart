import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// The Home tab — a **deliberate placeholder**, and the first screen a signed-in
/// user of a fresh project sees.
///
/// It used to be `Text('Home — TODO')`: a hardcoded English string, on the
/// landing screen, in a template whose own `lib/CLAUDE.md` bans hardcoded
/// strings in capital letters. Every project generated from it inherited a
/// rule-breaking example at the most-read location in the app, which is the
/// worst possible place for one — a reader copies what the codebase does, not
/// what its documentation says.
///
/// It stays a placeholder, because a template cannot know what an application's
/// home screen is. It just does it correctly: localized, themed, built from the
/// widget barrel, and pointing at the reference feature rather than at nothing.
///
/// **Replace the body wholesale** when this project has a real home.
@RoutePage(name: 'HomeRoute')
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — registers this element for locale changes
    context.locale;

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.tabHome.tr())),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.widgets_outlined,
                size: 56,
                color: context.colors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.welcomeBack.tr(),
                style: context.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.homeSubtitle.tr(),
                style: context.textTheme.bodySmall
                    ?.copyWith(color: context.colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // The reference CRUD feature. Delete this button together with
              // `Features/notes/` — see the root CLAUDE.md.
              PrimaryButton(
                text: LocaleKeys.notes.tr(),
                onTap: () => context.router.push(const NotesRoute()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
