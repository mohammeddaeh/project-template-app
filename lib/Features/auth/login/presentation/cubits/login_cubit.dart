import 'package:app_template/Features/auth/login/domain/entities/login_entity.dart';
import 'package:app_template/Features/auth/login/domain/params/login_params.dart';
import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/Features/auth/login/domain/usecases/login_usecase.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'login_cubit.freezed.dart';
part 'login_state.dart';

@injectable
class LoginCubit extends SafeCubit<LoginState> {
  LoginCubit(this._loginUseCase) : super(const LoginState.initial());

  final LoginUseCase _loginUseCase;

  Future<void> login({required String email, required String password}) async {
    emit(const LoginState.loading());

    final res = await _loginUseCase(
      LoginParams(email: email, password: password),
    );

    res.fold(
      (failure) {
        switch (FailureUiMapper.toAction(failure)) {
          case ShowError(:final message):
            emit(LoginState.error(errorMessage: message));
          case NavigateToLogin():
            break;
          case Silent():
            break;
        }
      },
      (entity) => emit(LoginState.success(entity: entity)),
    );
  }
}
