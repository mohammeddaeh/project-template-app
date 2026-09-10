part of 'login_cubit.dart';

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState.initial() = LoginInitial;
  const factory LoginState.loading() = LoginLoading;
  const factory LoginState.success({
    required LoginEntity entity,
  }) = LoginSuccess;
  const factory LoginState.error({
    required String errorMessage,
  }) = LoginError;
}
