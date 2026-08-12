import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/Features/auth/shared/current_user_repository.dart';

part 'splash_cubit.freezed.dart';
part 'splash_state.dart';

/// Decides where the first frame after the logo goes.
///
/// Three outcomes, and each has exactly one destination — see
/// `splash_screen.dart`. The cubit deliberately makes the decision and the
/// screen deliberately performs it, so the rule is testable without a widget
/// tree.
class SplashCubit extends SafeCubit<SplashState> {
  SplashCubit(this._sessionRepository, this._currentUserRepository)
      : super(const SplashState.initial());

  final SessionRepository _sessionRepository;
  final CurrentUserRepository _currentUserRepository;

  Future<void> loadResources() async {
    emit(const SplashState.loading());

    if (AppFeatures.debugSkipLogin) {
      emit(const SplashState.guestLoaded());
      return;
    }

    final token = await _sessionRepository.loadCachedToken();
    if (token == null || token.isEmpty) {
      emit(const SplashState.loaded());
      return;
    }

    // Restored BEFORE the navigation, not after.
    //
    // `CurrentUserRepository` is in-memory, so a relaunch with a still-valid
    // token starts with no user — and Profile, and anything else reading
    // `currentUser`, renders its empty state for as long as the network takes.
    // This call was documented as happening here and was never actually made,
    // which is why that empty first frame existed at all.
    //
    // Awaited rather than fired-and-forgotten: the whole point is that it wins
    // the race against the first build. It never throws — a corrupt entry is
    // treated as "nothing cached" — so there is no failure path to handle, and
    // `SessionSyncService` re-reads `/account/me` moments later regardless.
    await _currentUserRepository.restoreFromCache();

    emit(const SplashState.loadedWithAuth());
  }
}
