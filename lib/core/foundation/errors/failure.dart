/// Single source of truth for all application failures.
///
/// Rules enforced by this hierarchy:
/// - Raw data ONLY — no `.tr()`, no localization keys, no BuildContext.
/// - All UI translation lives exclusively in [FailureUiMapper].
/// - The `sealed` modifier enables exhaustive `switch` in every mapper,
///   so adding a new failure type causes compile-time errors wherever
///   the switch is incomplete.
sealed class Failure {
  const Failure();

  /// Diagnostic string for logging ONLY — NOT for display in UI.
  ///
  /// ⚠️  Architecture rule: do NOT access [diagnosticMessage] in widgets,
  /// cubits, or any presentation-layer code.
  /// All user-facing text must be produced by [FailureUiMapper.toAction].
  /// This field is exposed exclusively to [FailureMapperRegistry] and
  /// [LogService] calls within lib/core/.
  String? get diagnosticMessage => null;
}

// ── Transport failures ───────────────────────────────────────────────────────

/// No internet connection, DNS failure, or socket refused.
final class NoInternetFailure extends Failure {
  const NoInternetFailure();
}

/// Connection, send, or receive timed out.
final class TimeoutFailure extends Failure {
  const TimeoutFailure();
}

/// SSL/TLS certificate is invalid or untrusted.
final class BadCertificateFailure extends Failure {
  const BadCertificateFailure();
}

/// The request was cancelled by the caller (CancelToken / CancelInstance).
final class CancelledFailure extends Failure {
  const CancelledFailure();
}

// ── Server response failures ─────────────────────────────────────────────────

/// 401 on a login endpoint — wrong credentials.
///
/// Distinct from [UnauthorizedFailure] (session expiry).
/// [FailureUiMapper] maps this to [ShowError] so the user sees a message.
/// [AuthInterceptor] and [AuthEventBus] are NOT involved for login 401s.
final class LoginFailure extends Failure {
  const LoginFailure({this.serverMessage});

  final String? serverMessage;

  @override
  String? get diagnosticMessage => serverMessage;
}

/// 400 / 422 returned by the register endpoint (duplicate email, weak password …).
final class RegisterFailure extends Failure {
  const RegisterFailure({this.serverMessage});

  final String? serverMessage;

  @override
  String? get diagnosticMessage => serverMessage;
}

/// 401 / 403 during an active session — token expired or insufficient scope.
///
/// [AuthInterceptor] (REST) and [GqlFailureMapper] (GQL) both fire
/// [AuthEventBus.sessionExpired] BEFORE this reaches the cubit.
/// [FailureUiMapper] maps this to [NavigateToLogin].
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({this.serverMessage});

  final String? serverMessage;

  @override
  String? get diagnosticMessage => serverMessage;
}

/// 429 — the server is rate-limiting the client.
final class RateLimitFailure extends Failure {
  const RateLimitFailure({this.retryAfterSeconds, this.serverMessage});

  final int? retryAfterSeconds;
  final String? serverMessage;

  @override
  String? get diagnosticMessage => serverMessage;
}

/// 5xx — internal server error.
final class ServerFailure extends Failure {
  const ServerFailure({required this.statusCode, this.serverMessage});

  final int statusCode;
  final String? serverMessage;

  @override
  String? get diagnosticMessage => serverMessage;
}

/// 4xx (excluding 401, 403, 408, 429) — business or validation error.
final class BusinessFailure extends Failure {
  const BusinessFailure({required this.statusCode, this.serverMessage});

  final int statusCode;
  final String? serverMessage;

  @override
  String? get diagnosticMessage => serverMessage;
}

// ── Parse failures ───────────────────────────────────────────────────────────

/// Discriminates the exact parse error for logging and crash-reporting.
/// All three values share the same [FailureUiMapper] user-facing message.
enum ParseErrorKind {
  /// Response body is not valid JSON (e.g. server returned HTML).
  malformedJson,

  /// A JSON field holds the wrong Dart type (e.g. `int` field received `"abc"`).
  typeMismatch,

  /// A required / non-nullable field is `null` in the response.
  missingRequiredField,
}

/// Failure produced when the API response cannot be parsed into a model.
///
/// All three [ParseErrorKind] values map to the same user-facing message
/// ("حدث خطأ في بيانات الاستجابة").
///
/// [kind] and [fieldName] are preserved exclusively for [LogService] and
/// crash-reporting — they are never shown to the user.
final class ParseFailure extends Failure {
  const ParseFailure({required this.kind, this.fieldName, this.message});

  final ParseErrorKind kind;

  /// The JSON key that caused the error — available when using
  /// `@JsonSerializable(checked: true)` (from `CheckedFromJsonException`).
  final String? fieldName;

  final String? message;

  @override
  String? get diagnosticMessage => fieldName != null
      ? '[$kind] field "$fieldName": $message'
      : '[$kind] $message';
}

// ── Validation failures ───────────────────────────────────────────────────────

/// Failure produced when user-supplied data fails local validation
/// (form fields, value objects, business rules).
///
/// This is a **local** failure — it is never produced by [FailureMapperRegistry]
/// from a network exception. It is constructed manually in a UseCase or
/// Repository after running validation logic.
///
/// Usage:
/// ```dart
/// // With specific field messages (shown per-field in the form):
/// return Left(ValidationFailure(
///   fields: {'email': 'البريد غير صالح', 'phone': 'الرقم قصير'},
/// ));
///
/// // General validation error (no specific field):
/// return Left(ValidationFailure(message: 'يرجى ملء جميع الحقول'));
/// ```
///
/// The [FailureUiMapper] shows `fields.values.first` when fields are present,
/// or [message], or the generic `invalidInput` translation key as fallback.
final class ValidationFailure extends Failure {
  const ValidationFailure({this.fields = const {}, this.message});

  /// Maps field names to their validation error messages.
  /// Example: `{'email': 'البريد غير صالح', 'phone': 'الرقم قصير'}`.
  final Map<String, String> fields;

  /// General validation message when no specific field is involved.
  final String? message;

  @override
  String? get diagnosticMessage =>
      fields.isNotEmpty ? 'fields=${fields.toString()}' : message;
}

// ── Local failures ────────────────────────────────────────────────────────────

/// Local cache read/write error.
final class CacheFailure extends Failure {
  const CacheFailure({this.message});

  final String? message;

  @override
  String? get diagnosticMessage => message;
}

// ── Permission failures ───────────────────────────────────────────────────────

/// Why a platform permission was not granted.
enum PermissionDeniedReason {
  /// User tapped "Deny" — can ask again later.
  denied,

  /// User tapped "Don't ask again" — must direct to OS Settings.
  permanentlyDenied,

  /// OS restricts the permission (parental controls, MDM, etc.) — cannot ask.
  restricted,
}

/// Failure produced when a required platform permission is not granted.
///
/// [reason] drives the UI decision:
/// - [PermissionDeniedReason.denied]            → "إعادة الطلب" button
/// - [PermissionDeniedReason.permanentlyDenied] → "فتح الإعدادات" button
/// - [PermissionDeniedReason.restricted]        → informational message only
///
/// Constructed by [PermissionsService] implementations — never by
/// [FailureMapperRegistry].
final class PermissionFailure extends Failure {
  const PermissionFailure({required this.permission, required this.reason});

  /// The permission that was denied (e.g. `AppPermission.camera`).
  final String permission;

  final PermissionDeniedReason reason;

  @override
  String? get diagnosticMessage => '[$reason] permission=$permission';
}

// ── Storage failures ──────────────────────────────────────────────────────────

/// The storage I/O operation that failed.
enum StorageOperation { read, write, delete, clear }

/// Failure produced when a local storage read/write operation fails.
///
/// Distinct from [CacheFailure] which covers HTTP-cache errors in repositories.
/// [StorageFailure] is produced by [StorageService] / [SecureStorageService]
/// implementations for SharedPreferences / FlutterSecureStorage I/O errors.
///
/// [operation] and [key] are for logging/crash-reporting only — never shown
/// to the user (the UI receives the generic `cacheError` translation key).
final class StorageFailure extends Failure {
  const StorageFailure({required this.operation, this.key, this.message});

  final StorageOperation operation;

  /// The storage key that was being accessed — for diagnostics only.
  final String? key;

  final String? message;

  @override
  String? get diagnosticMessage => '[${operation.name}] key=$key: $message';
}

// ── Sync conflict failures ────────────────────────────────────────────────────

/// HTTP 409 — the server rejected a write due to a version conflict.
///
/// [serverVersion] and [clientVersion] are the full entity snapshots from
/// the 409 response body. [conflictFields] lists only the differing fields.
///
/// ⚠️  Sync-internal failure — mapped to [Silent()] in [FailureUiMapper].
/// The conflict is resolved by [SyncConflictResolver], NOT shown to the user
/// directly. For [SyncConflictStrategy.manual], the resolver emits a
/// [ConflictDetected] event for the UI to display a resolution sheet.
final class ConflictFailure extends Failure {
  const ConflictFailure({
    this.serverVersion,
    this.clientVersion,
    this.conflictFields = const [],
  });

  final Map<String, dynamic>? serverVersion;
  final Map<String, dynamic>? clientVersion;

  /// Fields that differ between server and client versions.
  /// Used by [SyncConflictStrategy.merge] for per-field resolution.
  final List<String> conflictFields;

  @override
  String? get diagnosticMessage =>
      'conflict_fields=[${conflictFields.join(', ')}]';
}

// ── Multi-Device Session failures ─────────────────────────────────────────────

/// The device session requested for revocation does not exist on the server.
final class DeviceNotFoundFailure extends Failure {
  const DeviceNotFoundFailure({this.serverMessage});
  final String? serverMessage;
}

/// A non-primary device attempted to revoke another session.
/// Only the primary device has that permission.
final class NotPrimaryDeviceFailure extends Failure {
  const NotPrimaryDeviceFailure({this.serverMessage});
  final String? serverMessage;
}

// ── Unknown failures ──────────────────────────────────────────────────────────

/// Catch-all for unclassified or unexpected errors.
final class UnknownFailure extends Failure {
  const UnknownFailure({this.message});

  final String? message;

  @override
  String? get diagnosticMessage => message;
}
