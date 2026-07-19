import 'package:app_template/core/foundation/contracts/auth_network_gateway.dart';
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

  @override
  String? getToken() => _cachedToken;

  @override
  void clearSession() {
    _cachedToken = null;
    _secureStorage.delete(PersistenceKeys.token);
  }

  /// Loads the stored token into memory — call once at app start (SplashCubit).
  Future<String?> loadCachedToken() async {
    _cachedToken = await _secureStorage.read(PersistenceKeys.token);
    return _cachedToken;
  }

  /// Persists the token after successful login — call from the login feature.
  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _secureStorage.write(PersistenceKeys.token, token);
  }
}
