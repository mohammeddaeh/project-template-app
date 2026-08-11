import 'package:flutter/material.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/multi_device/presentation/pages/active_devices_screen.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// The module's single mounting point — drop it into settings or profile.
///
/// ## Why the module exports a widget instead of the host importing a screen
///
/// Same pattern and same reason as `LogoutSection`: the host writes
/// `DevicesSection()` and knows nothing about `ActiveDevicesCubit`, provides no
/// `BlocProvider`, and imports nothing from the module's `domain/` or `data/`.
/// That is the project's stated test for a legitimate cross-boundary widget
/// (`lib/Features/CLAUDE.md`).
///
/// ## Why the flag is checked HERE and not by the host
///
/// The host would have to write `if (AppFeatures.multiDevice) DevicesSection()`
/// — and every future host would have to remember to. Worse, forgetting it
/// renders a tile that opens a screen whose dependencies were never registered,
/// because `MultiDevicePlugin.initialize` also returns early on the same flag.
/// Checking it once, here, makes the two impossible to disagree.
///
/// Renders nothing at all when disabled — no header, no spacing, no divider.
class DevicesSection extends StatelessWidget {
  const DevicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppFeatures.multiDevice) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SectionTitle(titleKey: LocaleKeys.security),
        ),
        AppListTile(
          leadingIcon: Icons.devices_outlined,
          titleKey: LocaleKeys.activeDevicesTitle,
          subtitleKey: LocaleKeys.activeDevicesSubtitle,
          trailing: const Icon(Icons.chevron_right, size: 20),
          // A plain MaterialPageRoute rather than an auto_route entry: the
          // screen must not exist in the router of a project that ships with
          // this module disabled, or the route would resolve to a screen whose
          // dependencies are absent.
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ActiveDevicesScreen(),
            ),
          ),
        ),
      ],
    );
  }
}
