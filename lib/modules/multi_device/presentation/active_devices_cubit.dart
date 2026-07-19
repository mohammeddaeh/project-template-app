import 'package:app_template/modules/multi_device/config/multi_device_config.dart';
import 'package:app_template/modules/multi_device/domain/device_session.dart';
import 'package:app_template/modules/multi_device/domain/device_session_repository.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'active_devices_state.dart';

class ActiveDevicesCubit extends Cubit<ActiveDevicesState> {
  ActiveDevicesCubit(this._repository) : super(const ActiveDevicesInitial());

  final DeviceSessionRepository _repository;

  Future<void> load() async {
    emit(const ActiveDevicesLoading());

    final result = await _repository.getActiveSessions();

    result.fold(
      (failure) {
        switch (FailureUiMapper.toAction(failure)) {
          case ShowError(:final message):
            emit(ActiveDevicesError(message: message));
          case NavigateToLogin():
          case Silent():
            emit(const ActiveDevicesError(message: ''));
        }
      },
      (sessions) {
        final isPrimary = sessions
            .where((s) => s.isCurrent)
            .any((s) => s.isPrimary);
        emit(ActiveDevicesLoaded(
          sessions: sessions,
          maxDevices: MultiDeviceConfig.maxDevices,
          isCurrentDevicePrimary: isPrimary,
        ));
      },
    );
  }

  Future<void> revokeSession(String deviceSessionId) async {
    emit(ActiveDevicesRevoking(deviceSessionId: deviceSessionId));

    final result = await _repository.revokeSession(deviceSessionId);

    result.fold(
      (failure) {
        switch (FailureUiMapper.toAction(failure)) {
          case ShowError(:final message):
            emit(ActiveDevicesError(message: message));
          case NavigateToLogin():
          case Silent():
            emit(const ActiveDevicesError(message: ''));
        }
      },
      (_) => load(), // Reload list after revocation
    );
  }

  Future<void> revokeAllExceptCurrent() async {
    emit(const ActiveDevicesLoading());

    final result = await _repository.revokeAllExceptCurrent();

    result.fold(
      (failure) {
        switch (FailureUiMapper.toAction(failure)) {
          case ShowError(:final message):
            emit(ActiveDevicesError(message: message));
          case NavigateToLogin():
          case Silent():
            emit(const ActiveDevicesError(message: ''));
        }
      },
      (_) => load(),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
  }
}
