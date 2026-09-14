import 'package:flutter/material.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/access_control/presentation/widgets/can.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/resources/permission_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:auto_route/auto_route.dart';

/// The module's mounting point for the roles screen — same pattern as
/// `DevicesSection`, for the same reason: the host writes
/// `AccessControlSection()` and knows nothing about `RolesCubit`, provides no
/// `BlocProvider`, and imports nothing from the module's `domain/` or `data/`.
///
/// ## Why the flag is checked HERE and not by the host
///
/// `AccessControlPlugin.initialize` registers `RolesCubit` and friends only
/// when `AppFeatures.accessControl` is `true` — `RolesRoute` itself stays
/// registered in every build so it never breaks a deep link (see
/// `routes/router.dart`), but opening it with nothing behind it would throw on
/// the first `getIt<RolesCubit>()`. Checking the flag once, here, is what
/// keeps a tile from ever being drawn in front of that gap.
///
/// `roles.view` decides whether the tile itself is worth drawing, not whether
/// the destination is reachable: [Can] renders its child unconditionally when
/// the module is off, which is exactly why this widget checks the flag before
/// reaching for [Can] at all.
///
/// Renders nothing at all when disabled or when the account cannot see roles.
class AccessControlSection extends StatelessWidget {
  const AccessControlSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppFeatures.accessControl) return const SizedBox.shrink();

    return Can(
      permission: PermKeys.rolesView,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SectionTitle(titleKey: LocaleKeys.security),
          ),
          AppListTile(
            leadingIcon: Icons.admin_panel_settings_outlined,
            titleKey: LocaleKeys.rolesTitle,
            subtitleKey: LocaleKeys.rolesManageSubtitle,
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.router.push(const RolesRoute()),
          ),
        ],
      ),
    );
  }
}
