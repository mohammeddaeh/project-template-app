part of 'user_access_cubit.dart';

/// Hand-written rather than `@freezed` — see `roles_state.dart` for why.
sealed class UserAccessState {
  const UserAccessState();
}

class UserAccessInitial extends UserAccessState {
  const UserAccessInitial();
}

class UserAccessLoading extends UserAccessState {
  const UserAccessLoading();
}

class UserAccessReady extends UserAccessState {
  const UserAccessReady({
    required this.access,
    required this.catalog,
    required this.allRoles,
  });

  /// The inputs **and** the outcome — the server sends both, and the screen
  /// shows both. An administrator ticking boxes without seeing the result is
  /// how a deny on `view` quietly revokes an `update` nobody meant to touch.
  final UserAccess access;

  final PermissionCatalog catalog;

  /// Assignable roles — active ones only. A deactivated role would be refused
  /// by the server, so offering it would be offering a choice that fails.
  final List<Role> allRoles;

  UserAccessReady copyWith({UserAccess? access}) => UserAccessReady(
    access: access ?? this.access,
    catalog: catalog,
    allRoles: allRoles,
  );
}

class UserAccessSaving extends UserAccessState {
  const UserAccessSaving({required this.ready});

  final UserAccessReady ready;
}

/// Carries an already-translated sentence, not a [Failure] — see
/// `roles_state.dart`.
class UserAccessFailed extends UserAccessState {
  const UserAccessFailed({required this.message});

  final String message;
}

/// Carries [ready] so a refused change leaves the screen legible against the
/// state that caused it — which matters most for the one refusal this screen
/// produces on purpose: an administrator removing their own full access.
class UserAccessActionFailed extends UserAccessState {
  const UserAccessActionFailed({required this.ready, required this.message});

  final UserAccessReady ready;
  final String message;
}
