import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/Features/auth/shared/models/auth_user_model.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

/// Reactive holder for the currently authenticated user + their effective RBAC permissions.
///
/// - `@singleton` (eager, same justification as [SessionRepository]): consumed immediately
///   after login succeeds and by any widget that needs to gate UI on permissions.
/// - [setCurrentUser] is called by `LoginRepositoryImpl` after a successful login, and
///   again after every successful `GET /users/me` background refresh.
/// - [clear] is called by `LogoutRepositoryImpl` on logout (and should be called on 401).
///
/// `permissionKeys` comes from `POST /users/login`'s `permission_keys` field — the
/// union of the user's effective RBAC permissions at login time (same source as the
/// backend's `findAllEffectivePermissionKeys`, branch-agnostic). Parsed by
/// `LoginModel`/`LoginEntity` (`Features/auth/login/`) and passed through here by
/// `LoginRepositoryImpl`.
///
/// ## Persistence across app restarts
/// This repository is in-memory only by itself — a fresh Dart process (full app
/// restart, not hot reload) starts with `_user = null`. [setCurrentUser] also
/// JSON-encodes the user + permission keys into [StorageService] (via
/// [PersistenceKeys.cachedCurrentUser]/[PersistenceKeys.cachedPermissionKeys],
/// same pattern as `DynamicLanguageCache`), so `SplashCubit.loadResources()` can
/// call [restoreFromCache] to repopulate this repository BEFORE the app
/// navigates past splash — fixing the bug where Home/Profile appeared empty
/// after a restart despite a still-valid token. A silent `GET /users/me` call
/// fired shortly after landing in the main app then re-syncs both the in-memory
/// state and this same local cache, in case anything changed server-side while
/// the app was closed (docs/reference/session_permission_integrity.md §4/§6/§10).
@singleton
class CurrentUserRepository {
  CurrentUserRepository(this._storage);

  final StorageService _storage;

  AuthUser? _user;
  Set<String> _permissionKeys = const {};
  bool _isSuperAdmin = false;

  final _userController = StreamController<AuthUser?>.broadcast();

  /// Emits the current user on every change; `null` when signed out.
  Stream<AuthUser?> get userStream => _userController.stream;

  AuthUser? get currentUser => _user;

  Set<String> get permissionKeys => _permissionKeys;

  /// Whether this session holds the Super Admin role — **not** a permission
  /// key, and not derivable from them. See `CurrentUserEntity.isSuperAdmin`.
  bool get isSuperAdmin => _isSuperAdmin;

  bool hasPermission(String key) => _permissionKeys.contains(key);

  void setCurrentUser(
    AuthUser user, {
    Set<String> permissionKeys = const {},
    bool isSuperAdmin = false,
  }) {
    _user = user;
    _permissionKeys = permissionKeys;
    _isSuperAdmin = isSuperAdmin;
    _userController.add(_user);
    unawaited(_persist(user, permissionKeys, isSuperAdmin));
  }

  /// Restores a previously-persisted user/permissions snapshot into this
  /// repository — called once by `SplashCubit.loadResources()` right after a
  /// cached token is found, before emitting `SplashState.loadedWithAuth()`.
  /// Never throws: a missing/corrupted cache entry is treated as "nothing to
  /// restore" (defensive — the background `GET /users/me` refresh covers this
  /// gap shortly after, same as before this fix, just transient instead of
  /// permanent).
  Future<void> restoreFromCache() async {
    try {
      final userJson = await _storage.readString(PersistenceKeys.cachedCurrentUser);
      if (userJson == null || userJson.isEmpty) return;

      final user = AuthUserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      ).toEntity();

      final keysJson = await _storage.readString(PersistenceKeys.cachedPermissionKeys);
      final keys = keysJson != null && keysJson.isNotEmpty
          ? (jsonDecode(keysJson) as List<dynamic>).map((e) => e as String).toSet()
          : <String>{};

      _user = user;
      _permissionKeys = keys;
      _isSuperAdmin =
          await _storage.readBool(PersistenceKeys.cachedIsSuperAdmin) ?? false;
      _userController.add(_user);
    } catch (_) {
      // Corrupted cache entry — treat as "not cached", never crash startup.
    }
  }

  Future<void> _persist(
    AuthUser user,
    Set<String> permissionKeys,
    bool isSuperAdmin,
  ) async {
    await _storage.writeString(
      PersistenceKeys.cachedCurrentUser,
      jsonEncode(AuthUserModel.fromEntity(user).toJson()),
    );
    await _storage.writeString(
      PersistenceKeys.cachedPermissionKeys,
      jsonEncode(permissionKeys.toList()),
    );
    await _storage.writeBool(
      PersistenceKeys.cachedIsSuperAdmin,
      value: isSuperAdmin,
    );
  }

  void clear() {
    _user = null;
    _permissionKeys = const {};
    _isSuperAdmin = false;
    _userController.add(null);
    unawaited(_storage.delete(PersistenceKeys.cachedCurrentUser));
    unawaited(_storage.delete(PersistenceKeys.cachedPermissionKeys));
    unawaited(_storage.delete(PersistenceKeys.cachedIsSuperAdmin));
  }
}
