import 'package:get_it/get_it.dart';

import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/access_control/integration/abilities_store.dart';

import 'integration/access_control_bootstrap.dart';

export 'domain/ability_set.dart' show AbilitySet;
export 'domain/access_control_repository.dart' show AccessControlRepository;
export 'domain/permission_catalog.dart'
    show LocalizedLabel, PermissionCatalog, PermissionDescriptor, PermissionGroup;
export 'domain/role.dart' show OverrideEffect, PermissionOverride, Role, UserAccess;
export 'guards/permission_route_guard.dart' show PermissionRouteGuard;
export 'integration/abilities_store.dart' show AbilitiesStore;
export 'presentation/widgets/can.dart' show AbilityContext, Can, CanMode;

/// Entry point for role-based access control.
///
/// ## What it gives you
///
/// One line per control, anywhere, for any permission the backend declares:
///
/// ```dart
/// Can(permission: 'notes.delete', child: DeleteButton())
/// ```
///
/// and one generic screen an administrator uses to hand those permissions out —
/// `RolesScreen`, built entirely from `GET /api/v1/authz/catalog`.
///
/// **No per-permission Dart, ever.** A feature becomes guarded by adding
/// `requirePermission('invoices.approve')` to its route on the server; the key
/// appears in the roles screen of a build shipped before invoices existed. The
/// same property `modules/data_transfer/` has, applied to authorization.
///
/// ## Activation
/// 1. Set `AppFeatures.accessControl = true` in `app_features.dart`.
/// 2. Nothing else — `ModulesBootstrap.initializeAll()` already calls this.
/// 3. Server side: seed a role, then `AUTHZ_ENABLED=true`. Until then the
///    server reports `enabled: false` and every gate here stays open, so the
///    order of the rollout cannot lock anyone out.
///
/// ## Deactivation
/// Set the flag to `false`. [initialize] returns immediately, nothing is
/// registered, and **every gate answers `true`** — `Can` renders its child and
/// `context.can()` returns true. An app built without access control behaves
/// exactly as it did before the module existed, and switching the flag on later
/// needs no edit to a single call site.
///
/// ## ⚠️ The client gate is not the security boundary
///
/// It stops a user being offered a button that will be refused.
/// `requirePermission` on the server is what refuses, and it is the only thing
/// that does. See `readme/permissions.md`.
abstract final class AccessControlPlugin {
  static bool _initialized = false;

  static const String _tag = 'ACCESS_CONTROL';

  static Future<void> initialize(GetIt di) async {
    if (_initialized) return;
    if (!AppFeatures.accessControl) {
      LogService.debug(
        'AccessControlPlugin disabled (AppFeatures.accessControl=false).',
        tag: _tag,
      );
      return;
    }

    LogService.debug('AccessControlPlugin initializing...', tag: _tag);
    await registerAccessControl(di);

    final store = di<AbilitiesStore>();

    // Restored **before** the first frame, and awaited. Without it a relaunch
    // with a valid token starts with every gate shut, and the user watches
    // their own controls appear a moment later — the same empty-first-frame
    // problem `CurrentUserRepository.restoreFromCache()` exists to solve, and
    // the reason both are awaited rather than fired and forgotten.
    await store.restoreFromCache();

    // Sign-in and sign-out. Subscribed here rather than by a screen, because a
    // screen that owned it would stop listening the moment it was popped.
    store.bindToSession();

    _initialized = true;
    LogService.debug('AccessControlPlugin ready.', tag: _tag);
  }

  /// Re-reads `/authz/me`.
  ///
  /// Safe to call unconditionally — a no-op when the module is off. Call it
  /// after anything that could have changed what the account may do: an
  /// administrator editing their own roles, or a 403 that suggests the client's
  /// picture is out of date.
  static Future<void> refresh(GetIt di) async {
    if (!AppFeatures.accessControl) return;
    if (!di.isRegistered<AbilitiesStore>()) return;
    await di<AbilitiesStore>().refresh();
  }

  static void reset() => _initialized = false;
}
