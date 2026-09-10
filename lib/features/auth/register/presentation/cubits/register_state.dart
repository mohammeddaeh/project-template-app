part of 'register_cubit.dart';

@freezed
abstract class RegisterState with _$RegisterState {
  const factory RegisterState.initial() = RegisterInitial;
  const factory RegisterState.loading() = RegisterLoading;

  /// Carries the created account because the next screen needs its address.
  ///
  /// With verification on, registration lands on the code screen — and that
  /// screen displays which address the code went to. Re-reading it from the
  /// form's controller would work until the day the server normalises it
  /// (it lower-cases and trims), at which point the screen would show a
  /// slightly different address from the one the mail was sent to.
  const factory RegisterState.success({required AuthUser account}) =
      RegisterSuccess;

  const factory RegisterState.error({required String errorMessage}) =
      RegisterError;
}
