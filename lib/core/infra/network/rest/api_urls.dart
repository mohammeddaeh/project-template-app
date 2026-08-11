/// The REST contract this client speaks.
///
/// Mirrors `backend_template`'s routers exactly:
/// - `/account/*` — who this application's users are. **Yours to grow.**
/// - `/auth/*` — proving an identity. Served by `core/auth`, portable across
///   applications, and not expected to change per project.
///
/// That split is the same one the backend enforces, and it is why an app can
/// replace its whole account model without touching verification, password
/// reset, session listing or token rotation.
abstract class ApiUrls {
  // ── Account — /api/v1/account ─────────────────────────────────────────────
  static const String login = '/account/login';
  static const String logout = '/account/logout';
  static const String register = '/account/register';

  /// The signed-in account. Re-fetched on resume, so a status change made
  /// server-side (disabled, verified, approved) reaches the client without
  /// waiting for the next sign-in — see `auth/me/`.
  static const String me = '/account/me';

  // ── Authentication & sessions — /api/v1/auth ──────────────────────────────

  /// Step 1 of a password reset.
  ///
  /// **Answers identically for a registered and an unregistered address** — a
  /// "no such account" response would turn this into a membership oracle anyone
  /// can query one address at a time. Do not add client-side branching that
  /// assumes otherwise.
  static const String forgotPassword = '/auth/forgot-password';

  /// Step 2 — spend the code and set the new password.
  ///
  /// The field is `code`, not `token`: it is eight characters a person reads
  /// off a screen and retypes, and calling it a token invites clients to treat
  /// it as opaque and arbitrarily long.
  static const String resetPassword = '/auth/reset-password';

  /// Authenticated. Requires the current password, so a stolen unlocked device
  /// cannot take the account over. A wrong current password answers **422, not
  /// 401** — 401 would sign the user out over a typo.
  static const String changePassword = '/auth/change-password';

  /// Authenticated — an account pending verification receives a real session
  /// precisely so it can reach this. The session unlocks nothing else.
  static const String verifyEmail = '/auth/verify-email';

  /// Issues a new code **and invalidates the previous one**, so repeated
  /// resends cannot stack independent guess budgets against an account.
  static const String resendVerification = '/auth/resend-verification';

  /// Extends the session, rotating its token once it is old enough.
  /// `rotated: false` means the token was still young and came back unchanged —
  /// the client stores whatever it receives either way.
  static const String refreshSession = '/auth/refresh';

  /// The account's own devices. The token is never returned — only its digest
  /// is stored, and only its holder ever saw the plaintext.
  static const String sessions = '/auth/sessions';
  static String session(dynamic id) => '/auth/sessions/$id';
  static const String revokeOtherSessions = '/auth/sessions/revoke-others';

  // ── Your own features go below ────────────────────────────────────────────
  static const String users = '/users';
}
