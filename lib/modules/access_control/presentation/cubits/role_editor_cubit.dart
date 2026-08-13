import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:app_template/modules/access_control/domain/access_control_repository.dart';
import 'package:app_template/modules/access_control/domain/permission_catalog.dart';
import 'package:app_template/modules/access_control/domain/role.dart';

part 'role_editor_state.dart';

/// Edits one role's permission set.
///
/// The whole state is a `Set<String>` of keys and a catalog to render them
/// against — which is why this class does not change when the application gains
/// a resource. It never names a permission.
class RoleEditorCubit extends SafeCubit<RoleEditorState> {
  RoleEditorCubit(this._repository) : super(const RoleEditorInitial());

  final AccessControlRepository _repository;

  void start({required Role role, required PermissionCatalog catalog}) {
    emit(
      RoleEditorReady(
        role: role,
        catalog: catalog,
        selected: role.permissions.toSet(),
      ),
    );
  }

  /// Ticks or unticks one key.
  ///
  /// **The implications are not applied here.** `notes.update` implies
  /// `notes.view`, and the server closes that gap when it resolves the set — so
  /// applying it in the client too would silently tick a box the administrator
  /// did not tick, and re-saving would persist a grant they never chose. The
  /// screen *shows* what a tick will also grant (`PermissionDescriptor.implies`)
  /// and leaves the stored set exactly as chosen.
  void toggle(String key) {
    final current = state;
    if (current is! RoleEditorReady) return;

    final next = <String>{...current.selected};
    if (!next.remove(key)) next.add(key);
    emit(current.copyWith(selected: next));
  }

  /// Ticks or unticks every key of one resource at once — the header checkbox
  /// on a card.
  void toggleGroup(PermissionGroup group, {required bool select}) {
    final current = state;
    if (current is! RoleEditorReady) return;

    final next = <String>{...current.selected};
    // The synthetic `manage` key is deliberately excluded: "tick everything
    // shown" and "grant this resource forever, including what is added later"
    // are different promises, and a select-all that quietly made the second one
    // would be the most consequential checkbox on the screen pretending to be
    // the least.
    final keys = group.permissions.where((p) => !p.synthetic).map((p) => p.key);

    if (select) {
      next.addAll(keys);
    } else {
      next.removeAll(keys);
      next.remove('${group.resource}.manage');
    }
    emit(current.copyWith(selected: next));
  }

  Future<void> save() async {
    final current = state;
    if (current is! RoleEditorReady) return;

    emit(RoleEditorSaving(ready: current));

    final result = await _repository.setRolePermissions(
      id: current.role.id,
      permissions: current.selected.toList(),
    );

    result.fold(
      (failure) => _emitFailure(current, failure),
      (role) => emit(RoleEditorSaved(role: role)),
    );
  }

  /// A refused save must leave the selection on screen, so the failure state
  /// carries [ready]. Losing twenty ticks because the network dropped is not an
  /// acceptable way to report a failure.
  void _emitFailure(RoleEditorReady ready, Failure failure) {
    switch (FailureUiMapper.toAction(failure)) {
      case ShowError(:final message):
        emit(RoleEditorFailed(ready: ready, message: message));
      // Session expiry is routed to login by the network layer on its own.
      case NavigateToLogin():
      case Silent():
        emit(ready);
    }
  }
}
