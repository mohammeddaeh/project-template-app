import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/Features/auth/register/domain/params/register_params.dart';
import 'package:app_template/Features/auth/register/domain/usecases/register_usecase.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'register_cubit.freezed.dart';
part 'register_state.dart';

@injectable
class RegisterCubit extends SafeCubit<RegisterState> {
  RegisterCubit(this._register) : super(const RegisterState.initial());

  final RegisterUseCase _register;

  Future<void> submit({
    required String email,
    required String password,
    String? fullName,
  }) async {
    emit(const RegisterState.loading());

    final res = await _register(
      RegisterParams(email: email, password: password, fullName: fullName),
    );

    res.fold(
      (failure) {
        switch (FailureUiMapper.toAction(failure)) {
          case ShowError(:final message):
            emit(RegisterState.error(errorMessage: message));
          // Unreachable in practice — registration is unauthenticated, so
          // nothing here can produce a 401. Handled rather than ignored because
          // the switch is exhaustive and a silent fallthrough would leave the
          // screen spinning forever if that ever changed.
          case NavigateToLogin():
          case Silent():
            emit(const RegisterState.initial());
        }
      },
      (account) => emit(RegisterState.success(account: account)),
    );
  }
}
