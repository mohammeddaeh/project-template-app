import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/modules/multi_device/domain/device_session.dart';
import 'package:app_template/modules/multi_device/domain/device_session_repository.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';

part 'active_devices_state.dart';

class ActiveDevicesCubit extends SafeCubit<ActiveDevicesState> {
  ActiveDevicesCubit(this._repository) : super(const ActiveDevicesInitial());

  final DeviceSessionRepository _repository;

  Future<void> load() async {
    emit(const ActiveDevicesLoading());

    final result = await _repository.getActiveSessions();
    result.fold(
      _emitFailure,
      (sessions) => emit(ActiveDevicesLoaded(sessions: sessions)),
    );
  }

  Future<void> revokeSession(int id) async {
    // Keeps the current list on screen while one row works. Emitting a bare
    // loading state would blank every other device — none of which changed,
    // and all of which the user is mid-way through reading.
    final current = state;
    final sessions = switch (current) {
      ActiveDevicesLoaded(:final sessions) => sessions,
      ActiveDevicesRevoking(:final sessions) => sessions,
      _ => const <DeviceSession>[],
    };
    emit(ActiveDevicesRevoking(sessions: sessions, id: id));

    final result = await _repository.revokeSession(id);
    // Reloaded rather than removed locally: the server is the authority on
    // what is still live, and a list edited by hand drifts the first time a
    // revocation half-succeeds.
    result.fold(_emitFailure, (_) => load());
  }

  Future<void> revokeOthers() async {
    emit(const ActiveDevicesLoading());

    final result = await _repository.revokeOthers();
    result.fold(_emitFailure, (_) => load());
  }

  void _emitFailure(Failure failure) {
    switch (FailureUiMapper.toAction(failure)) {
      case ShowError(:final message):
        emit(ActiveDevicesError(message: message));
      // Session expiry is handled centrally by the network layer — it routes to
      // login on its own. Emitting an empty-string error here (as this cubit
      // used to) painted a blank red state over a screen that was already being
      // torn down.
      case NavigateToLogin():
      case Silent():
        break;
    }
  }
}
