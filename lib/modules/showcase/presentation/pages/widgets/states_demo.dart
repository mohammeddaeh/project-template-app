import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/sections/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The screen states a list or detail page shows while it waits, fails or
/// finds nothing — and the one progress widget in its shapes.
class StatesDemo extends StatelessWidget {
  const StatesDemo({super.key});

  static void _noop() {}

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const DemoBlock(
        code: 'AppProgress.circular · AppProgress.linear',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 16,
              children: [
                AppProgress.circular(size: AppProgressSize.sm),
                AppProgress.circular(),
                AppProgress.circular(value: 0.65),
              ],
            ),
            SizedBox(height: 16),
            AppProgress.linear(value: 0.4),
          ],
        ),
      ),
      const DemoBlock(
        code: 'Skeletonized(enabled: …, child: <the real body>)',
        child: Skeletonized(
          enabled: true,
          child: AppListTile(
            titleText: '— — — — — —',
            subtitleText: '— — — —',
            leadingIcon: Icons.person_outline,
          ),
        ),
      ),
      const DemoBlock(
        code: 'EmptyStateWidget',
        child: EmptyStateWidget(titleKey: LocaleKeys.noDataFound),
      ),
      const DemoBlock(
        code: 'ErrorStateWidget(onRetry: …)',
        child: ErrorStateWidget(
          messageKey: LocaleKeys.somethingWrong,
          onRetry: _noop,
        ),
      ),
    ],
  );
}
