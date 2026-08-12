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

  // ── Reference feature — delete together with `Features/notes/` ────────────

  /// The one endpoint that exercises the paginated list contract end to end.
  ///
  /// `static const String users = '/users'` used to sit here instead: a path no
  /// router has ever served, referenced by nothing in `lib/`, left over from
  /// the project this template was extracted from.
  static const String notes = '/notes';
  static String note(int id) => '/notes/$id';

  // ── Import / export — generic, one set of paths for every resource ────────

  /// Everything this backend can import or export, with its columns.
  ///
  /// The `modules/data_transfer/` screens are built entirely from this
  /// response — a feature that becomes transferable server-side needs **no**
  /// Dart change to appear in them.
  static const String transferResources = '/data-transfer/resources';

  /// ⚠️ **Answers file bytes, not the `{status, message, data}` envelope.**
  ///
  /// Never call this through a repository that runs `HandleBodyResponse`: it
  /// parses every body as JSON and would report "something went wrong" over a
  /// perfectly good CSV — with a `200 OK` in the server log. Use
  /// `TransferFileDownloader`, which reads it as bytes.
  static String transferExport(String resource) =>
      '/data-transfer/$resource/export';

  /// Empty file with the importer's expected header. Bytes, like [transferExport].
  static String transferTemplate(String resource) =>
      '/data-transfer/$resource/template';

  /// Both import phases. `?mode=validate` (multipart) then `?mode=commit`
  /// (`{token}`). Ordinary envelope in both directions.
  static String transferImport(String resource) =>
      '/data-transfer/$resource/import';

  // ── Your own features go below ────────────────────────────────────────────
}
