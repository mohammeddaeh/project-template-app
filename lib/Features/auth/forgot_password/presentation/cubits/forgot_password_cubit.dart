import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/forgot_password/domain/params/request_reset_params.dart';
import 'package:app_template/Features/auth/forgot_password/domain/params/reset_password_params.dart';
import 'package:app_template/Features/auth/forgot_password/domain/usecases/request_reset_usecase.dart';
import 'package:app_template/Features/auth/forgot_password/domain/usecases/reset_password_usecase.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'forgot_password_cubit.freezed.dart';
part 'forgot_password_state.dart';

/// Drives both steps of the reset journey.
///
/// One cubit for two screens, because the second step needs the email the first
/// one collected. Splitting them would mean either passing the address through
/// a route argument (and trusting it) or asking for it twice.
@injectable
class ForgotPasswordCubit extends SafeCubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._requestReset, this._resetPassword)
    : super(const ForgotPasswordState.initial());

  final RequestResetUseCase _requestReset;
  final ResetPasswordUseCase _resetPassword;

  /// The address the code was sent to — held so step two does not have to ask
  /// again, and so a resend targets the same address.
  String? _email;
  String? get email => _email;

  Future<void> requestReset(String email) async {
    emit(const ForgotPasswordState.loading());
    _email = email;

    final res = await _requestReset(RequestResetParams(email: email));

    res.fold(_emitFailure, (_) => emit(const ForgotPasswordState.codeSent()));
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final email = _email;
    if (email == null) {
      // Reachable only if the reset screen is opened directly — a deep link, or
      // a route pushed by hand. Better a named error than a request with an
      // empty address that the server rejects for the wrong reason.
      emit(const ForgotPasswordState.initial());
      return;
    }

    emit(const ForgotPasswordState.loading());

    final res = await _resetPassword(
      ResetPasswordParams(
        email: email,
        token: token,
        newPassword: newPassword,
      ),
    );

    res.fold(_emitFailure, (_) => emit(const ForgotPasswordState.success()));
  }

  void _emitFailure(Failure failure) {
    switch (FailureUiMapper.toAction(failure)) {
      case ShowError(:final message):
        emit(ForgotPasswordState.error(errorMessage: message));
      // Nothing to do locally: session expiry is handled centrally, and these
      // endpoints are unauthenticated anyway.
      case NavigateToLogin():
      case Silent():
        break;
    }
  }
}
