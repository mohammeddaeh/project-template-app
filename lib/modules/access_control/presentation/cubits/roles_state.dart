part of 'roles_cubit.dart';

/// Hand-written rather than `@freezed`, matching every other module state here
/// and for the same documented reason: `lib/modules/` ships disabled by default
/// and must not force a code-generation step on a project that never enables
/// it. States in `lib/Features/` stay freezed.
sealed class RolesState {
  const RolesState();
}

class RolesInitial extends RolesState {
  const RolesInitial();
}

class RolesLoading extends RolesState {
  const RolesLoading();
}

/// The list. Everything the screen draws comes from [catalog] and [roles] —
/// this module has no hardcoded knowledge of any permission.
class RolesReady extends RolesState {
  const RolesReady({
    required this.roles,
    required this.catalog,
    this.busyRoleId,
  });

  final List<Role> roles;
  final PermissionCatalog catalog;

  /// The row currently waiting on the server, so one card shows a spinner
  /// rather than the whole list being replaced by one.
  final int? busyRoleId;

  RolesReady copyWith({
    List<Role>? roles,
    PermissionCatalog? catalog,
    int? busyRoleId,
  }) => RolesReady(
    roles: roles ?? this.roles,
    catalog: catalog ?? this.catalog,
    busyRoleId: busyRoleId,
  );
}

/// Carries an already-translated sentence, not a [Failure].
///
/// `FailureUiMapper` runs in the cubit, so every `.tr()` in this module stays
/// in one place and the screen renders whatever it is handed — including a
/// server-written message more specific than anything hardcoded here.
class RolesFailed extends RolesState {
  const RolesFailed({required this.message});

  final String message;
}

/// A write failed while the list is on screen.
///
/// Carries [ready] so the screen keeps rendering rather than blanking: nothing
/// the user was looking at became invalid because a save was refused, and
/// replacing the list with an error page loses their place for no reason.
class RolesActionFailed extends RolesState {
  const RolesActionFailed({required this.ready, required this.message});

  final RolesReady ready;
  final String message;
}
