import 'package:auto_route/auto_route.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/access_control/integration/abilities_store.dart';

/// Keeps a whole screen behind a permission.
///
/// ```dart
/// AutoRoute(
///   page: RolesRoute.page,
///   guards: [PermissionRouteGuard(PermKeys.rolesView)],
/// )
/// ```
///
/// For a screen whose *existence* is privileged — an administration area, a
/// reports section. A screen that merely contains one privileged button does
/// not need this; wrap the button in `Can` instead, or the user loses the whole
/// page to gain one control they could not use.
///
/// ## What it does when the answer is no
///
/// Refuses the navigation and nothing else — no redirect to a "forbidden"
/// screen. The entry point that led here should itself have been wrapped in
/// `Can`, so reaching a guarded route usually means a deep link, a stale
/// bookmark or a race with a permission that was just revoked. In every one of
/// those cases, staying where the user is beats bouncing them somewhere they
/// did not ask for.
///
/// ## ⚠️ Still not the security boundary
///
/// A hidden screen whose endpoints are unguarded is not protected — the data is
/// one HTTP call away. Guard the routes on the server; this only keeps the
/// navigation honest.
class PermissionRouteGuard extends AutoRouteGuard {
  const PermissionRouteGuard(this.permission);

  final String permission;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    // Module off, or not yet wired (a widget test, an isolated preview) — the
    // app behaves as it did before access control existed.
    if (!AppFeatures.accessControl || !getIt.isRegistered<AbilitiesStore>()) {
      resolver.next();
      return;
    }

    final store = getIt<AbilitiesStore>();
    store.debugWarnIfUnknown(permission);

    if (store.abilities.can(permission)) {
      resolver.next();
      return;
    }

    LogService.debug(
      'Navigation to ${resolver.route.name} refused — missing "$permission".',
      tag: 'ACCESS_CONTROL',
    );
    resolver.next(false);
  }
}
