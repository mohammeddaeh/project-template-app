part of 'change_password_cubit.dart';

@freezed
abstract class ChangePasswordState with _$ChangePasswordState {
  const factory ChangePasswordState.initial() = ChangePasswordInitial;
  const factory ChangePasswordState.loading() = ChangePasswordLoading;
  const factory ChangePasswordState.success() = ChangePasswordSuccess;
  const factory ChangePasswordState.error({required String errorMessage}) =
      ChangePasswordError;
}
