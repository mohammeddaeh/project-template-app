import 'package:equatable/equatable.dart';

/// What the signed-in account may do — **the answer, not the inputs.**
///
/// The server sends this set already resolved: implications applied, wildcards
/// materialised, denies subtracted (`core/authz/inference.ts`). So [can] is a
/// plain lookup, and there is no client-side copy of a rule that could drift
/// out of step with the one that actually refuses the request.
///
/// That is deliberate, and it is the correction to what this template shipped
/// before. The previous implementation kept `permissionKeys` and a
/// `hasPermission()` on the client while **no endpoint ever sent the field** —
/// so the method returned `false` for every key on every call, and a gate that
/// is always shut reads in code exactly like a gate that works. It was deleted
/// on 2026-08-11 rather than repaired. This class exists only because the
/// server now issues the claims.
class AbilitySet extends Equatable {
  const AbilitySet({
    required this.permissions,
    required this.isSuperAdmin,
    required this.version,
    required this.enforced,
    this.declaredKeys,
  });

  /// Every key granted, fully expanded. Never contains a wildcard.
  final Set<String> permissions;

  /// Holds the unrestricted `*` grant. Kept so a screen can say "full access"
  /// instead of listing two hundred keys.
  final bool isSuperAdmin;

  /// Changes whenever anything feeding this set changes. Compared against the
  /// cached copy to decide whether a re-fetch changed anything.
  final int version;

  /// Whether the **server** enforces permissions at all (`AUTHZ_ENABLED`).
  ///
  /// When false, [can] answers `true` for everything. This is not a loophole,
  /// it is the only correct behaviour: a client hiding buttons against a server
  /// that refuses nothing shows the user an application with no controls and no
  /// explanation. A deployment mid-rollout is exactly when that would happen.
  final bool enforced;

  /// Every key the server declares — present **only in debug builds**, where
  /// the module asks for it to catch keys that no server knows. See
  /// [AbilitySet.isKnown].
  final Set<String>? declaredKeys;

  /// Nothing granted, everything enforced.
  ///
  /// The state before the first `/authz/me` lands, and the deliberate choice
  /// between two imperfect options: starting *open* would flash controls the
  /// user may not have and then snatch them away, which reads as a bug and, for
  /// one frame, invites a tap that will be refused. Starting *closed* shows a
  /// slightly bare screen that fills in — and the cached set restored at
  /// startup means, after the first run, that frame does not happen at all.
  static const AbilitySet none = AbilitySet(
    permissions: <String>{},
    isSuperAdmin: false,
    version: 0,
    enforced: true,
  );

  /// Everything allowed. Used when the module is switched off in
  /// [AppFeatures.accessControl] — an app built without access control must
  /// behave exactly as it did before the module existed.
  static const AbilitySet unrestricted = AbilitySet(
    permissions: <String>{},
    isSuperAdmin: true,
    version: 0,
    enforced: false,
  );

  /// The only question this class answers.
  ///
  /// ⚠️ **This is not security.** It decides whether a control is drawn; the
  /// server's `requirePermission` decides whether the action happens. A client
  /// gate exists so the user is not offered a button that will be refused —
  /// never as the thing that does the refusing.
  bool can(String key) => !enforced || permissions.contains(key);

  /// True when the account holds **any** of [keys]. Mirrors the server's
  /// `requireAnyPermission`.
  bool canAny(Iterable<String> keys) => keys.any(can);

  /// True when the account holds **every** key.
  bool canAll(Iterable<String> keys) => keys.every(can);

  /// Whether the server declares this key at all — answerable only in debug
  /// builds, where [declaredKeys] is requested. Returns `true` when unknown, so
  /// a release build never treats a legitimate key as a mistake.
  bool isKnown(String key) => declaredKeys?.contains(key) ?? true;

  @override
  List<Object?> get props => [
    permissions,
    isSuperAdmin,
    version,
    enforced,
    declaredKeys,
  ];
}
