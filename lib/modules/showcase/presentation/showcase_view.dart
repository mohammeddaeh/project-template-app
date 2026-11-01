import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/showcase_section.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// **What the template provides, on the home tab of a fresh project** — one
/// card per area; each card expands into a page that uses the real widgets.
///
/// Nothing here needs a server: every demo runs on the device alone, so the
/// tour works the moment the project is created. Turn it off with
/// `AppFeatures.showcase = false`, or delete `lib/modules/showcase/` — see
/// `SETUP.md` beside this folder.
class ShowcaseView extends StatelessWidget {
  const ShowcaseView({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return ResponsiveContentBox(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Text(
            LocaleKeys.showcaseTitle.tr(),
            style: context.textTheme.headlineMedium,
          ),
          4.heightBox,
          Text(
            LocaleKeys.showcaseHint.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          16.heightBox,
          for (final (i, section) in ShowcaseSection.values.indexed)
            ListItemAppearWdg(
              staggerIndex: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SectionCard(section),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(this.section);

  final ShowcaseSection section;

  @override
  Widget build(BuildContext context) => AppOpenContainer<void>(
    closedBuilder: (context, open) => AppListTile(
      titleKey: section.titleKey,
      leadingIcon: section.icon,
      // Mirrors itself in right-to-left text.
      trailing: Icon(Icons.chevron_right, color: context.colors.textMuted),
      onTap: open,
    ),
    openBuilder: (context, close) => ShowcaseSectionPage(section: section),
  );
}
