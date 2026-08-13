part of 'role_editor_cubit.dart';

/// Hand-written rather than `@freezed` — see `roles_state.dart` for why.
sealed class RoleEditorState {
  const RoleEditorState();
}

class RoleEditorInitial extends RoleEditorState {
  const RoleEditorInitial();
}

class RoleEditorReady extends RoleEditorState {
  const RoleEditorReady({
    required this.role,
    required this.catalog,
    required this.selected,
  });

  final Role role;
  final PermissionCatalog catalog;

  /// The keys as they will be **stored** — chosen, not resolved. Wildcards stay
  /// wildcards; implications are shown but never silently added.
  final Set<String> selected;

  /// Nothing to save. Compared as sets, so re-ordering is not a change.
  bool get isUnchanged =>
      selected.length == role.permissions.length &&
      selected.containsAll(role.permissions);

  /// A system role is read-only through the API, so the screen renders it that
  /// way rather than offering a save that the server will refuse.
  bool get isReadOnly => role.isSystem;

  RoleEditorReady copyWith({Set<String>? selected}) => RoleEditorReady(
    role: role,
    catalog: catalog,
    selected: selected ?? this.selected,
  );
}

class RoleEditorSaving extends RoleEditorState {
  const RoleEditorSaving({required this.ready});

  final RoleEditorReady ready;
}

class RoleEditorSaved extends RoleEditorState {
  const RoleEditorSaved({required this.role});

  final Role role;
}

/// Carries [ready] so a refused save leaves the user's selection on screen.
/// Losing twenty ticks because the network dropped is not an acceptable way to
/// report a failure.
class RoleEditorFailed extends RoleEditorState {
  const RoleEditorFailed({required this.ready, required this.message});

  final RoleEditorReady ready;

  /// Already translated by `FailureUiMapper` in the cubit — including the
  /// server's own wording, which is more specific than anything hardcoded here
  /// (an unknown permission key is named in the 422).
  final String message;
}
