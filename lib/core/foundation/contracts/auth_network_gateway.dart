/// Contract between the network layer (core) and the auth feature.
///
/// Implemented by the auth feature — injected into [AuthInterceptor].
/// Keeps core/infra free of any direct dependency on Features/auth.
abstract interface class AuthNetworkGateway {
  /// Returns the stored access token, or null if not authenticated.
  String? getToken();

  /// Clears stored credentials (called on 401 session expiry).
  void clearSession();
}
