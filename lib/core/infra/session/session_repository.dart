import 'package:app_template/core/foundation/contracts/auth_network_gateway.dart';
import 'dart:async';

import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';
import 'package:injectable/injectable.dart';

/// Single source of truth for the auth token.
///
/// - Implements [AuthNetworkGateway] so [AuthInterceptor] can read the token
///   synchronously without coupling to SecureStorageService.
/// - Token is cached in memory after [loadCachedToken] (called by SplashCubit).
/// - [saveToken] persists to secure storage + updates cache (called after login).
/// - [clearSession] wipes both cache and storage (called on logout / 401).
@singleton
class SessionRepository implements AuthNetworkGateway {
  SessionRepository(this._secureStorage);

  final SecureStorageService _secureStorage;
  String? _cachedToken;

  final _tokenController = StreamController<String?>.broadcast();

  /// Emits the new token on sign-in and `null` when the session ends — whether
  /// that is a deliberate sign-out or a 401 clearing it mid-use.
  ///
  /// Exists so anything holding **per-account state** can discard it at exactly
  /// the right moment without reaching into the auth feature. `AbilitiesStore`
  /// is the first consumer: without this, a signed-out user's permissions would
  /// stay in memory, and the next account to sign in on the device would
  /// briefly inherit them.
  ///
  /// Deliberately not replayed to late subscribers — a consumer registered
  /// during composition subscribes before any sign-in can happen, and a
  /// replayed token would look like a fresh sign-in on every hot restart.
  Stream<String?> get tokenStream => _tokenController.stream;

  @override
  String? getToken() => _cachedToken;

  @override
  void clearSession() {
    _cachedToken = null;
    _secureStorage.delete(PersistenceKeys.token);
    _emit(null);
  }

  /// Loads the stored token into memory — call once at app start (SplashCubit).
  ///
  /// Does **not** emit on [tokenStream]: nothing changed hands, the same
  /// account is still signed in. Startup state is restored from each holder's
  /// own cache instead, which is what keeps the first frame from being empty.
  Future<String?> loadCachedToken() async {
    _cachedToken = await _secureStorage.read(PersistenceKeys.token);
    return _cachedToken;
  }

  /// Persists the token after successful login — call from the login feature.
  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _secureStorage.write(PersistenceKeys.token, token);
    _emit(token);
  }

  void _emit(String? token) {
    if (!_tokenController.isClosed) _tokenController.add(token);
  }
}
