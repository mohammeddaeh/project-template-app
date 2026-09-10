part of 'logout_cubit.dart';

@freezed
abstract class LogoutState with _$LogoutState {
  const factory LogoutState.initial() = LogoutInitial;
  const factory LogoutState.loading() = LogoutLoading;
  const factory LogoutState.success() = LogoutSuccess;
  const factory LogoutState.error({required String errorMessage}) = LogoutError;

  /// The device is still holding [pendingOperations] writes the server has
  /// never seen. **Not an error — a question**, and the only state here the
  /// user answers rather than reads.
  ///
  /// Signing out strands them: the queue outlives the token, and its contents
  /// can only ever be pushed by the account that wrote them.
  const factory LogoutState.pendingWork({required int pendingOperations}) =
      LogoutPendingWork;
}
