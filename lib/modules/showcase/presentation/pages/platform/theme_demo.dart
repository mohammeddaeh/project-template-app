import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/sections/demo_block.dart';
import 'package:app_template/ui/locale/locale_switcher.dart';
import 'package:app_template/ui/theme/theme_switcher.dart';

/// The two switches the settings tab uses — flip them here and the whole
/// tour redraws in the other theme or language.
class ThemeDemo extends StatelessWidget {
  const ThemeDemo({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DemoBlock(
        code: 'ThemeSwitcher',
        child: ThemeSwitcher(padding: EdgeInsets.zero),
      ),
      DemoBlock(code: 'LocaleSwitcher.tile', child: LocaleSwitcher.tile()),
    ],
  );
}
