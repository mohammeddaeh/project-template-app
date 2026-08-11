import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/domain/no_params.dart';
import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/Features/auth/verify_email/domain/params/verify_email_params.dart';
import 'package:app_template/Features/auth/verify_email/domain/usecases/resend_verification_usecase.dart';
import 'package:app_template/Features/auth/verify_email/domain/usecases/verify_email_usecase.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';

part 'verify_email_cubit.freezed.dart';
part 'verify_email_state.dart';

/// Drives the code screen: spend a code, or ask for another.
@injectable
class VerifyEmailCubit extends SafeCubit<VerifyEmailState> {
  VerifyEmailCubit(this._verifyEmail, this._resendVerification)
      : super(const VerifyEmailState.initial());

  final VerifyEmailUseCase _verifyEmail;
  final ResendVerificationUseCase _resendVerification;

  /// Mirrors the server's resend cooldown so the button can say how long is
  /// left instead of inviting a tap that will be refused.
  ///
  /// A local countdown is a **courtesy, never a boundary** — the server refuses
  /// early requests regardless, and it is the only thing that actually can. If
  /// the two disagree (clock skew, an app restart clearing this) the server
  /// wins and the screen shows its message.
  static const _resendCooldown = Duration(seconds: 60);

  Timer? _cooldownTimer;
  int _secondsLeft = 0;
  int get secondsUntilResend => _secondsLeft;

  Future<void> verify(String code) async {
    emit(const VerifyEmailState.loading());

    final res = await _verifyEmail(VerifyEmailParams(code: code));

    res.fold(
      _emitFailure,
      (user) => emit(VerifyEmailState.verified(user: user)),
    );
  }

  Future<void> resend() async {
    if (_secondsLeft > 0) return;
    emit(const VerifyEmailState.loading());

    final res = await _resendVerification(const NoParams());

    res.fold(_emitFailure, (_) {
      _startCooldown();
      emit(const VerifyEmailState.codeResent());
    });
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _secondsLeft = _resendCooldown.inSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsLeft -= 1;
      if (_secondsLeft <= 0) {
        _secondsLeft = 0;
        timer.cancel();
      }
      // Re-emitting the current state is what refreshes the countdown label.
      // `SafeCubit` drops emits after close, so a user leaving mid-countdown
      // cannot crash this — the exact failure `safe_cubit_test.dart` guards.
      emit(VerifyEmailState.cooldownTick(secondsLeft: _secondsLeft));
    });
  }

  void _emitFailure(Failure failure) {
    switch (FailureUiMapper.toAction(failure)) {
      case ShowError(:final message):
        emit(VerifyEmailState.error(errorMessage: message));
      // Session expiry is handled centrally by the network layer; nothing to
      // add locally beyond not overwriting it with a screen-level error.
      case NavigateToLogin():
      case Silent():
        break;
    }
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
