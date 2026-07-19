/// Contract between [TokenRefreshInterceptor] (core) and the auth feature.
///
/// The auth feature implements this interface — core never imports Features/.
///
/// ## Implementation guide (auth feature)
/// ```dart
/// @Singleton(as: TokenRefreshGateway)
/// class TokenRefreshGatewayImpl implements TokenRefreshGateway {
///   TokenRefreshGatewayImpl(this._authApiService, this._secureStorage);
///
///   @override
///   Future<void> refresh() async {
///     final refreshToken = await _secureStorage.read(PersistenceKeys.refreshToken);
///     if (refreshToken == null) throw Exception('No refresh token');
///
///     final response = await _authApiService.refreshToken(refreshToken);
///     await _secureStorage.write(PersistenceKeys.token, response.accessToken);
///     if (response.refreshToken != null) {
///       await _secureStorage.write(PersistenceKeys.refreshToken, response.refreshToken!);
///     }
///   }
///
///   @override
///   Future<void> onRefreshFailed() async {
///     await _secureStorage.clear();
///   }
/// }
/// ```
abstract interface class TokenRefreshGateway {
  /// Exchanges the stored refresh token for a new access token.
  ///
  /// Implementations must:
  /// 1. Read the refresh token from [SecureStorageService].
  /// 2. Call the `/refresh` endpoint (using a fresh Dio without interceptors).
  /// 3. Persist the new access (and refresh) token in [SecureStorageService].
  ///
  /// Throws on any failure — [TokenRefreshInterceptor] catches and calls
  /// [onRefreshFailed].
  Future<void> refresh();

  /// Called when [refresh] throws or returns null — should clear all session
  /// data (tokens, user cache, etc.).
  Future<void> onRefreshFailed();
}
