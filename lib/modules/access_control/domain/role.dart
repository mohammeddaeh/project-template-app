import 'package:equatable/equatable.dart';

import 'permission_catalog.dart';

/// A named bundle of permissions.
class Role extends Equatable {
  const Role({
    required this.id,
    required this.key,
    required this.name,
    required this.isSystem,
    required this.isActive,
    required this.permissions,
    required this.stalePermissions,
    required this.usersCount,
  });

  final int id;

  /// The stable machine name (`super_admin`). Seeds and scripts refer to it;
  /// the API refuses to rename it, because renaming re-points nothing while
  /// breaking everything that referred to it.
  final String key;
  final LocalizedLabel name;

  /// A role the application depends on. The screen renders it read-only — the
  /// server refuses to change it either way, and a form that submits a request
  /// it knows will be refused is a worse experience than a disabled control.
  final bool isSystem;

  final bool isActive;

  /// Exactly what is stored — **wildcards unexpanded**. `notes.*` arrives as
  /// one entry, not four, so re-saving cannot silently convert one into the
  /// other.
  final List<String> permissions;

  /// Grants this server no longer declares — a feature was deleted, its keys
  /// stayed. Shown rather than hidden, so they are cleaned up on purpose.
  final List<String> stalePermissions;

  final int usersCount;

  bool get hasStaleGrants => stalePermissions.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    key,
    name,
    isSystem,
    isActive,
    permissions,
    stalePermissions,
    usersCount,
  ];
}

/// `allow` widens what the roles gave; `deny` takes away, and wins.
///
/// The third state an administrator sees — *inherit* — is the **absence** of an
/// override, not a value. Storing it would create two ways to say the same
/// thing, and a migration the first time they disagreed.
enum OverrideEffect {
  allow('allow'),
  deny('deny');

  const OverrideEffect(this.wire);

  final String wire;

  static OverrideEffect? fromWire(String? raw) => switch (raw) {
    'allow' => OverrideEffect.allow,
    'deny' => OverrideEffect.deny,
    _ => null,
  };
}

class PermissionOverride extends Equatable {
  const PermissionOverride({
    required this.key,
    required this.effect,
    this.note,
  });

  final String key;
  final OverrideEffect effect;

  /// Why the exception exists. An override with no stated reason outlives
  /// everyone who remembers it.
  final String? note;

  @override
  List<Object?> get props => [key, effect, note];
}

/// One account's complete access picture: the inputs **and** the outcome.
///
/// Both, because an administrator ticking boxes without seeing the result is
/// how a deny on `view` quietly revokes an `update` nobody meant to touch — the
/// server closes denies upward on purpose (`inference.ts` rule 4), and the only
/// honest way to present that is to show what the choices actually resolve to.
class UserAccess extends Equatable {
  const UserAccess({
    required this.userId,
    required this.roles,
    required this.overrides,
    required this.effectivePermissions,
    required this.isSuperAdmin,
  });

  final int userId;
  final List<Role> roles;
  final List<PermissionOverride> overrides;
  final Set<String> effectivePermissions;
  final bool isSuperAdmin;

  OverrideEffect? effectFor(String key) =>
      overrides.where((o) => o.key == key).firstOrNull?.effect;

  @override
  List<Object?> get props => [
    userId,
    roles,
    overrides,
    effectivePermissions,
    isSuperAdmin,
  ];
}
