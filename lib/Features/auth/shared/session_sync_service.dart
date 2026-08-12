import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/foundation/domain/no_params.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/lifecycle/app_lifecycle_service.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/Features/auth/me/domain/usecases/get_current_user_usecase.dart';

/// Keeps the locally-held account in step with the server's.
///
/// ## The gap this closes
///
/// `api_urls.dart` has described `/account/me` as "re-fetched on resume, so a
/// status change made server-side reaches the client without waiting for the
/// next sign-in" since the endpoint was added. **Nothing did the re-fetching.**
/// `AppLifecycleService` existed, `GetCurrentUserUseCase` existed, and no line
/// of code connected them — so an account disabled by an administrator kept
/// working on the device until its token expired, and the documentation said
/// otherwise.
///
/// ## What it does
///
/// - **Once at startup**, after a restored session: the cached snapshot
///   `SplashCubit` put in place is a bridge, and this is what replaces it with
///   the truth.
/// - **On every foreground resume**, at most once per [_minInterval]: coming
///   back to an app is exactly when its picture of the world is most likely to
///   be stale, and it is the only moment a user is present to act on what
///   changed.
///
/// The refusal is handled by the layers that already own it: a 401 goes to
/// `TokenRefreshInterceptor`, which refreshes and retries or emits
/// `sessionExpired`; a 403 becomes a `Failure` and `MeRepositoryImpl` simply
/// does not publish. So this service never decides anything — it only asks.
///
/// ## Why the throttle
///
/// Resume fires on far more than a user returning: a permission dialog, a
/// share sheet, the camera, an OS-level pull-down. Without a floor, a single
/// screen that opens a picker three times issues three identical requests, and
/// on a slow connection they overlap.
@lazySingleton
class SessionSyncService {
  SessionSyncService(this._sessionRepository, this._getCurrentUser);

  final SessionRepository _sessionRepository;
  final GetCurrentUserUseCase _getCurrentUser;

  static const _tag = 'SESSION-SYNC';
  static const _minInterval = Duration(minutes: 1);

  StreamSubscription<AppLifecycleState>? _lifecycleSub;
  DateTime? _lastSyncAt;

  /// Called once from `App.initState`. Safe to call with no session — it does
  /// nothing until there is a token to sync against.
  void start() {
    unawaited(_sync());

    // Guarded because `AppLifecycleService` is only registered when
    // `AppFeatures.appLifecycle` is on. Reading `getIt` unconditionally would
    // make a feature flag that is documented as costing nothing throw at boot.
    if (!AppFeatures.appLifecycle) {
      LogService.debug(
        'appLifecycle is off — syncing at startup only.',
        tag: _tag,
      );
      return;
    }

    _lifecycleSub = getIt<AppLifecycleService>().stateStream.listen((state) {
      if (state == AppLifecycleState.resumed) unawaited(_sync());
    });
  }

  Future<void> _sync() async {
    if (_sessionRepository.getToken() == null) return;

    final now = DateTime.now();
    if (_lastSyncAt != null && now.difference(_lastSyncAt!) < _minInterval) {
      return;
    }
    _lastSyncAt = now;

    // The result is deliberately unused: `MeRepositoryImpl` publishes the
    // account to `CurrentUserRepository` itself, and every listener redraws
    // from there. A failure needs no handling here — the picture stays as it
    // was, which is the correct outcome for a background refresh nobody asked
    // for.
    final result = await _getCurrentUser(const NoParams());
    result.fold(
      (failure) => LogService.debug('Sync skipped: $failure', tag: _tag),
      (user) => LogService.debug('Account synced (${user.status}).', tag: _tag),
    );
  }

  void dispose() {
    _lifecycleSub?.cancel();
    _lifecycleSub = null;
  }
}
