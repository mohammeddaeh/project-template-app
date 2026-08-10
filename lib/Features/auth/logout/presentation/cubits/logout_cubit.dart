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
  LogoutCubit(this._logoutUseCase) : super(const LogoutState.initial());

  final LogoutUseCase _logoutUseCase;

  Future<void> logout() async {
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
