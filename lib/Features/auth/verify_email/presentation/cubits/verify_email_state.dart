part of 'verify_email_cubit.dart';

@freezed
abstract class VerifyEmailState with _$VerifyEmailState {
  const factory VerifyEmailState.initial() = VerifyEmailInitial;
  const factory VerifyEmailState.loading() = VerifyEmailLoading;

  /// Carries the user with their **new** status, straight from the server —
  /// so the screen routes on what actually happened rather than on what
  /// verification usually leads to.
  const factory VerifyEmailState.verified({
    required AuthUser user,
  }) = VerifyEmailVerified;

  const factory VerifyEmailState.codeResent() = VerifyEmailCodeResent;

  /// A distinct state rather than a field on the others: the countdown ticks
  /// once a second, and folding it into `initial` would make every tick
  /// indistinguishable from "the screen just opened".
  const factory VerifyEmailState.cooldownTick({
    required int secondsLeft,
  }) = VerifyEmailCooldownTick;

  const factory VerifyEmailState.error({
    required String errorMessage,
  }) = VerifyEmailError;
}
