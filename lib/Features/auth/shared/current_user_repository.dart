import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/Features/auth/shared/models/auth_user_model.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

/// Reactive holder for the currently authenticated user.
///
/// - `@singleton` (eager, same justification as `SessionRepository`): consumed
///   immediately after login succeeds and by any widget that shows who is
///   signed in.
/// - [setCurrentUser] is called by `LoginRepositoryImpl` after a successful
///   sign-in, and again by `MeRepositoryImpl` on every `GET /account/me`.
/// - [clear] is called by `LogoutRepositoryImpl`, and by
///   `TokenRefreshGatewayImpl.onRefreshFailed`.
///
/// ## Permissions were removed (2026-08-11)
///
/// This class carried `permissionKeys`, `isSuperAdmin` and `hasPermission()`.
/// No endpoint has ever sent those fields, so `hasPermission()` returned
/// `false` for every key on every call — a gate that is always shut reads in
/// code exactly like a gate that works. `backend_template` states that
/// authorization is deliberately out of scope; the client now says the same
/// thing instead of pretending otherwise.
///
/// **When you add RBAC**, the server issues the claims first. Then reinstate a
/// field here and cache it beside the user with the same two-key pattern below.
///
/// ## Persistence across app restarts
///
/// In-memory by itself — a fresh Dart process starts with `_user = null`.
/// [setCurrentUser] also JSON-encodes the user into [StorageService] under
/// [PersistenceKeys.cachedCurrentUser], so `SplashCubit` can call
/// [restoreFromCache] and repopulate this repository BEFORE the app navigates
/// past splash. Without it, Home and Profile render empty after a restart
/// despite a still-valid token. `SessionSyncService` then re-reads `/account/me`
/// in the background, so the snapshot is a bridge across the gap, never the
/// source of truth.
@singleton
class CurrentUserRepository {
  CurrentUserRepository(this._storage);

  final StorageService _storage;

  AuthUser? _user;

  final _userController = StreamController<AuthUser?>.broadcast();

  /// Emits the current user on every change; `null` when signed out.
  Stream<AuthUser?> get userStream => _userController.stream;

  AuthUser? get currentUser => _user;

  void setCurrentUser(AuthUser user) {
    _user = user;
    _userController.add(_user);
    unawaited(_persist(user));
  }

  /// Restores a previously-persisted snapshot — called once by
  /// `SplashCubit.loadResources()` right after a cached token is found.
  ///
  /// Never throws: a missing or corrupted entry is treated as "nothing to
  /// restore", because failing here would turn a stale cache into a startup
  /// crash while the background `/account/me` refresh already covers the gap.
  Future<void> restoreFromCache() async {
    try {
      final userJson =
          await _storage.readString(PersistenceKeys.cachedCurrentUser);
      if (userJson == null || userJson.isEmpty) return;

      _user = AuthUserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      ).toEntity();
      _userController.add(_user);
    } catch (_) {
      // Corrupted cache entry — treat as "not cached", never crash startup.
    }
  }

  Future<void> _persist(AuthUser user) async {
    await _storage.writeString(
      PersistenceKeys.cachedCurrentUser,
      jsonEncode(AuthUserModel.fromEntity(user).toJson()),
    );
  }

  void clear() {
    _user = null;
    _userController.add(null);
    unawaited(_storage.delete(PersistenceKeys.cachedCurrentUser));
  }
}
