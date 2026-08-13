import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:app_template/modules/access_control/domain/access_control_repository.dart';
import 'package:app_template/modules/access_control/domain/permission_catalog.dart';
import 'package:app_template/modules/access_control/domain/role.dart';

part 'roles_state.dart';

/// Drives the roles list.
///
/// It loads the catalog alongside the roles, in one pass, because the list
/// already needs it: a role's stored grants are keys, and rendering
/// "Notes · Edit" instead of `notes.update` is only possible with the catalog
/// in hand. Fetching it lazily per row would be one request per role.
class RolesCubit extends SafeCubit<RolesState> {
  RolesCubit(this._repository) : super(const RolesInitial());

  final AccessControlRepository _repository;

  Future<void> load() async {
    emit(const RolesLoading());

    final catalogResult = await _repository.catalog();
    await catalogResult.fold(
      (failure) async => _emitFailure(failure),
      (catalog) async {
        final rolesResult = await _repository.roles();
        rolesResult.fold(
          (failure) => _emitFailure(failure),
          (roles) => emit(RolesReady(roles: roles, catalog: catalog)),
        );
      },
    );
  }

  /// Reloads only the list, keeping the catalog already held.
  ///
  /// The catalog changes when the *server* is redeployed, not when an
  /// administrator saves a role — re-fetching it after every edit would be a
  /// request whose answer is known to be identical.
  Future<void> refreshRoles() async {
    final current = state;
    if (current is! RolesReady) return await load();

    final result = await _repository.roles();
    result.fold(
      (failure) => _emitFailure(failure),
      (roles) => emit(current.copyWith(roles: roles)),
    );
  }

  Future<void> setActive(Role role, {required bool isActive}) async {
    final current = state;
    if (current is! RolesReady) return;

    emit(current.copyWith(busyRoleId: role.id));
    final result = await _repository.setRoleActive(
      id: role.id,
      isActive: isActive,
    );

    await result.fold(
      (failure) async {
        emit(current.copyWith(busyRoleId: null));
        _emitActionFailure(current, failure);
      },
      (_) => refreshRoles(),
    );
  }

  Future<void> create({
    required String key,
    required String nameAr,
    required String nameEn,
  }) async {
    final current = state;
    if (current is! RolesReady) return;

    final result = await _repository.createRole(
      key: key,
      nameAr: nameAr,
      nameEn: nameEn,
    );

    await result.fold(
      (failure) async => _emitActionFailure(current, failure),
      (_) => refreshRoles(),
    );
  }

  /// Translates the failure **here**, in the presentation layer, so the state
  /// carries a sentence and the screen carries no `.tr()` — the same split
  /// every other cubit in this project uses.
  void _emitFailure(Failure failure) {
    final message = _describe(failure);
    if (message != null) emit(RolesFailed(message: message));
  }

  void _emitActionFailure(RolesReady ready, Failure failure) {
    final message = _describe(failure);
    if (message != null) {
      emit(RolesActionFailed(ready: ready, message: message));
    }
  }

  /// `null` for the two actions that are not messages: an expired session is
  /// routed to login by the network layer on its own, and painting an error
  /// over a screen already being torn down is noise.
  String? _describe(Failure failure) => switch (FailureUiMapper.toAction(failure)) {
    ShowError(:final message) => message,
    NavigateToLogin() || Silent() => null,
  };
}
