part of 'logout_cubit.dart';

@freezed
abstract class LogoutState with _$LogoutState {
  const factory LogoutState.initial() = LogoutInitial;
  const factory LogoutState.loading() = LogoutLoading;
  const factory LogoutState.success() = LogoutSuccess;
  const factory LogoutState.error({required String errorMessage}) = LogoutError;
}
