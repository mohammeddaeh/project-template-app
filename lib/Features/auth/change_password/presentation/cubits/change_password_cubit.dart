import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/Features/auth/change_password/domain/params/change_password_params.dart';
import 'package:app_template/Features/auth/change_password/domain/usecases/change_password_usecase.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'change_password_cubit.freezed.dart';
part 'change_password_state.dart';

@injectable
class ChangePasswordCubit extends SafeCubit<ChangePasswordState> {
  ChangePasswordCubit(this._changePassword)
    : super(const ChangePasswordState.initial());

  final ChangePasswordUseCase _changePassword;

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(const ChangePasswordState.loading());

    final res = await _changePassword(
      ChangePasswordParams(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );

    res.fold(
      (failure) {
        switch (FailureUiMapper.toAction(failure)) {
          case ShowError(:final message):
            emit(ChangePasswordState.error(errorMessage: message));
          case NavigateToLogin():
          case Silent():
            break;
        }
      },
      (_) => emit(const ChangePasswordState.success()),
    );
  }
}
