import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/sections/buttons_demo.dart';
import 'package:app_template/modules/showcase/presentation/sections/formats_demo.dart';
import 'package:app_template/modules/showcase/presentation/sections/inputs_demo.dart';
import 'package:app_template/modules/showcase/presentation/sections/motion_demo.dart';
import 'package:app_template/modules/showcase/presentation/sections/states_demo.dart';
import 'package:app_template/modules/showcase/presentation/sections/theme_demo.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// The areas of the tour, in the order the home tab lists them.
enum ShowcaseSection {
  buttons(LocaleKeys.showcaseButtons, Icons.smart_button_outlined),
  inputs(LocaleKeys.showcaseInputs, Icons.edit_note_outlined),
  states(LocaleKeys.showcaseStates, Icons.inbox_outlined),
  motion(LocaleKeys.showcaseMotion, Icons.animation_outlined),
  formats(LocaleKeys.showcaseFormats, Icons.calendar_month_outlined),
  theme(LocaleKeys.showcaseTheme, Icons.palette_outlined);

  const ShowcaseSection(this.titleKey, this.icon);

  final String titleKey;
  final IconData icon;

  Widget body() => switch (this) {
    ShowcaseSection.buttons => const ButtonsDemo(),
    ShowcaseSection.inputs => const InputsDemo(),
    ShowcaseSection.states => const StatesDemo(),
    ShowcaseSection.motion => const MotionDemo(),
    ShowcaseSection.formats => const FormatsDemo(),
    ShowcaseSection.theme => const ThemeDemo(),
  };
}

/// One area of the tour, opened from its card on the home tab.
class ShowcaseSectionPage extends StatelessWidget {
  const ShowcaseSectionPage({required this.section, super.key});

  final ShowcaseSection section;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return Scaffold(
      appBar: AppBar(title: Text(section.titleKey.tr())),
      body: ResponsiveContentBox(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [section.body()],
        ),
      ),
    );
  }
}
