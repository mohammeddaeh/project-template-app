import 'package:app_template/features/auth/login/domain/entities/login_entity.dart';
import 'package:app_template/features/auth/login/domain/params/login_params.dart';
import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/infra/session/session_guard_fresh_auth.dart';
import 'package:app_template/features/auth/login/domain/usecases/login_usecase.dart';
import 'package:app_template/ui/error/failure_ui_mapper.dart';
import 'package:app_template/ui/error/ui_action.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'login_cubit.freezed.dart';
part 'login_state.dart';

@injectable
class LoginCubit extends SafeCubit<LoginState> {
  LoginCubit(this._loginUseCase, this._freshAuth)
    : super(const LoginState.initial());

  final LoginUseCase _loginUseCase;
  final SessionGuardFreshAuth _freshAuth;

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
      (entity) {
        // إثبات حضورٍ حيّ (كلمة مرور كُتبت للتوّ) — يعفي أول قفل جلسة محلي
        // (SessionGuard) من طلب رقمٍ أو بصمة بعد ثوانٍ من هذا الإدخال.
        _freshAuth.raise();
        emit(LoginState.success(entity: entity));
      },
    );
  }
}
