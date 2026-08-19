import 'package:app_template/core/foundation/contracts/unsynced_work_probe.dart';
import 'package:app_template/core/foundation/domain/no_params.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/Features/auth/logout/domain/usecases/logout_usecase.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'logout_cubit.freezed.dart';
part 'logout_state.dart';

@injectable
class LogoutCubit extends SafeCubit<LogoutState> {
  LogoutCubit(this._logoutUseCase, this._unsyncedWork)
      : super(const LogoutState.initial());

  final LogoutUseCase _logoutUseCase;
  final UnsyncedWorkProbe _unsyncedWork;

  /// Signs out — **unless the device is still holding work nobody else has.**
  ///
  /// ## Why a sign-out is a destructive action here
  ///
  /// With an offline queue, signing out is not just "forget this token". The
  /// queue outlives it, and its contents can only ever be pushed by the account
  /// that wrote them — so a sign-out with pending operations strands them:
  /// unpushable under the next account, invisible to this one. And the user
  /// most likely to hit it is the one furthest from help, mid-round, tapping
  /// sign-out because the app "seemed stuck".
  ///
  /// The probe answers zero when no offline module is registered, so an app
  /// without sync takes exactly the path it always did.
  ///
  /// [force] is how the user says "yes, I understand" after being told. The
  /// screen asks; this method only refuses to decide on their behalf.
  Future<void> logout({bool force = false}) async {
    if (!force) {
      final pending = await _unsyncedWork.pendingOperations();
      if (pending > 0) {
        emit(LogoutState.pendingWork(pendingOperations: pending));
        return;
      }
    }

    emit(const LogoutState.loading());
    final res = await _logoutUseCase(const NoParams());
    res.fold(
      (failure) {
        switch (FailureUiMapper.toAction(failure)) {
          case ShowError(:final message):
            emit(LogoutState.error(errorMessage: message));
          case NavigateToLogin():
            AuthEventBus.instance.emit(AuthEvent.sessionExpired);
          case Silent():
            break;
        }
      },
      (_) => AuthEventBus.instance.emit(AuthEvent.sessionExpired),
    );
  }
}
