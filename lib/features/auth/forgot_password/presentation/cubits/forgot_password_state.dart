part of 'forgot_password_cubit.dart';

@freezed
abstract class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState.initial() = ForgotPasswordInitial;
  const factory ForgotPasswordState.loading() = ForgotPasswordLoading;

  /// Step one finished — a code was requested.
  ///
  /// Deliberately **not** called `emailSent`: the server does not tell us
  /// whether an account existed, and naming the state after an email we cannot
  /// confirm was sent would make the next reader trust it.
  const factory ForgotPasswordState.codeSent() = ForgotPasswordCodeSent;

  /// Step two finished — the password is changed and the code is spent.
  const factory ForgotPasswordState.success() = ForgotPasswordSuccess;

  const factory ForgotPasswordState.error({required String errorMessage}) =
      ForgotPasswordError;
}
