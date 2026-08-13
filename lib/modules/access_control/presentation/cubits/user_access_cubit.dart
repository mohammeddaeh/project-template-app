import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:app_template/modules/access_control/domain/access_control_repository.dart';
import 'package:app_template/modules/access_control/domain/permission_catalog.dart';
import 'package:app_template/modules/access_control/domain/role.dart';

part 'user_access_state.dart';

/// One account's roles and per-permission exceptions.
///
/// The exceptions are the reason this screen exists at all: without them, "Sara
/// also approves invoices" is modelled by inventing a role with one member, and
/// a deployment ends up with forty roles nobody can describe.
class UserAccessCubit extends SafeCubit<UserAccessState> {
  UserAccessCubit(this._repository) : super(const UserAccessInitial());

  final AccessControlRepository _repository;

  Future<void> load(int userId) async {
    emit(const UserAccessLoading());

    final catalogResult = await _repository.catalog();
    await catalogResult.fold(
      (failure) async => _emitFailure(failure),
      (catalog) async {
        final rolesResult = await _repository.roles();
        await rolesResult.fold(
          (failure) async => _emitFailure(failure),
          (allRoles) async {
            final accessResult = await _repository.userAccess(userId);
            accessResult.fold(
              (failure) => _emitFailure(failure),
              (access) => emit(
                UserAccessReady(
                  access: access,
                  catalog: catalog,
                  allRoles: allRoles.where((r) => r.isActive).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> toggleRole(Role role) async {
    final current = state;
    if (current is! UserAccessReady) return;

    final held = current.access.roles.any((r) => r.id == role.id);
    final next = current.access.roles.map((r) => r.id).toSet();
    if (held) {
      next.remove(role.id);
    } else {
      next.add(role.id);
    }

    emit(UserAccessSaving(ready: current));
    final result = await _repository.setUserRoles(
      userId: current.access.userId,
      roleIds: next.toList(),
    );

    result.fold(
      // The server refuses a change that would strip the acting administrator
      // of their own unrestricted access. Keeping the screen as it was — rather
      // than reloading — leaves the refusal legible against the state that
      // caused it.
      (failure) => _emitActionFailure(current, failure),
      (access) => emit(current.copyWith(access: access)),
    );
  }

  /// Moves one key through *inherit → allow → deny → inherit*.
  ///
  /// A cycle rather than three controls: the tri-state belongs to one key, and
  /// three radio buttons per permission would turn a screen of two hundred keys
  /// into six hundred targets.
  Future<void> cycleOverride(String key) async {
    final current = state;
    if (current is! UserAccessReady) return;

    final next = <PermissionOverride>[
      ...current.access.overrides.where((o) => o.key != key),
    ];

    final effect = switch (current.access.effectFor(key)) {
      null => OverrideEffect.allow,
      OverrideEffect.allow => OverrideEffect.deny,
      OverrideEffect.deny => null,
    };
    if (effect != null) {
      next.add(PermissionOverride(key: key, effect: effect));
    }

    emit(UserAccessSaving(ready: current));
    final result = await _repository.setUserOverrides(
      userId: current.access.userId,
      overrides: next,
    );

    result.fold(
      (failure) => _emitActionFailure(current, failure),
      (access) => emit(current.copyWith(access: access)),
    );
  }

  void _emitFailure(Failure failure) {
    final message = _describe(failure);
    if (message != null) emit(UserAccessFailed(message: message));
  }

  /// Keeps the screen as it was rather than reloading, which matters most for
  /// the one refusal this screen produces on purpose: an administrator removing
  /// their own full access. The message is only legible next to the state that
  /// caused it.
  void _emitActionFailure(UserAccessReady ready, Failure failure) {
    final message = _describe(failure);
    emit(
      message == null
          ? ready
          : UserAccessActionFailed(ready: ready, message: message),
    );
  }

  String? _describe(Failure failure) => switch (FailureUiMapper.toAction(failure)) {
    ShowError(:final message) => message,
    NavigateToLogin() || Silent() => null,
  };
}
