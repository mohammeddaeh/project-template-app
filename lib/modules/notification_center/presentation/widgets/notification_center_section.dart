import 'package:flutter/material.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/notification_center/presentation/pages/notification_center_screen.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The module's mounting point — drop it into settings. Same pattern and same
/// reasons as `DevicesSection`: the host writes `NotificationCenterSection()`
/// and knows nothing else, and the flag is checked here, once, so the tile can
/// never appear without the module behind it.
///
/// Renders nothing when `AppFeatures.notificationCenter` is off.
class NotificationCenterSection extends StatelessWidget {
  const NotificationCenterSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppFeatures.notificationCenter) return const SizedBox.shrink();

    return AppListTile(
      leadingIcon: Icons.notifications_outlined,
      titleKey: LocaleKeys.notificationCenterTitle,
      trailing: const Icon(Icons.chevron_right, size: 20),
      // A plain route, not auto_route: a project shipping with the module off
      // must not carry a route to a screen whose dependencies are absent.
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const NotificationCenterScreen(),
        ),
      ),
    );
  }
}
