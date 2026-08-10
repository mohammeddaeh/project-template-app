abstract class ApiUrls {
  static const String login = '/login';
  static const String logout = '/logout';

  /// The signed-in user. Re-fetched on resume, so a status change an admin
  /// made (suspended, approved, disabled) reaches the client without waiting
  /// for the next sign-in — see `auth/me/`.
  static const String me = '/users/me';

  static const String register = '/register';

  // ── Password reset (unauthenticated) ──────────────────────────────────────
  /// Step 1 — ask for a reset code.
  ///
  /// **Must answer identically for a registered and an unregistered address.**
  /// A "no such account" response turns this into a membership oracle anyone
  /// can query one address at a time.
  static const String forgotPassword = '/forgot-password';

  /// Step 2 — spend the code and set the new password.
  static const String resetPassword = '/reset-password';

  /// Authenticated — changing your own password. Requires the current one, so a
  /// stolen unlocked device cannot take the account over.
  static const String changePassword = '/change-password';

  static const String profile = '/profile';
  static const String users = '/users';
}
