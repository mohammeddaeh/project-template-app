/// Contract for checking session authentication state.
/// Implemented in Features/auth; consumed by any feature that
/// needs to know if the user is authenticated — without
/// depending on the auth feature directly.
abstract interface class SessionReader {
  bool get isAuthenticated;
}
