import 'package:easy_localization/easy_localization.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:app_template/resources/locale_keys.g.dart';

/// The ONLY place where a [Failure] is translated into a [UiAction].
///
/// ✅ Rules (enforced by location + custom lint):
/// - All `.tr()` / localization calls are confined here and ONLY here.
/// - Returns a sealed [UiAction] — consumers MUST handle every case via
///   exhaustive `switch`, preventing silent error swallowing.
/// - No business logic — only message selection per failure type.
///
/// ⚠️  Layer: PRESENTATION only.
/// Importing this file from lib/core/, lib/Features/*/data/, or
/// lib/Features/*/domain/ is an architecture violation.
abstract final class FailureUiMapper {
  const FailureUiMapper._();

  static UiAction toAction(Failure failure) => switch (failure) {
        // ── Silent cases ────────────────────────────────────────────────────

        // Caller cancelled — intentional, nothing to show.
        CancelledFailure() => const Silent(),

        // Auth event bus + AuthInterceptor already handle navigation.
        // The cubit fires AuthEventBus as a safety-net (deduplicated).
        UnauthorizedFailure() => const NavigateToLogin(),

        // 403 — the session is valid, this one action is not permitted. The
        // user stays exactly where they are; ejecting them to the login screen
        // over a missing permission reads as the app breaking, not a refusal.
        ForbiddenFailure(:final serverMessage) => ShowError(
            title: LocaleKeys.error.tr(),
            message: serverMessage?.isNotEmpty == true
                ? serverMessage!
                : LocaleKeys.forbiddenAction.tr(),
          ),

        // ── Auth-specific ───────────────────────────────────────────────────

        LoginFailure(:final serverMessage) => ShowError(
            title: LocaleKeys.error.tr(),
            message: serverMessage?.isNotEmpty == true
                ? serverMessage!
                : LocaleKeys.unauthorised.tr(),
          ),

        // The four refused-account states. Each says something different about
        // what the user should do next, which is the entire reason they are
        // separate types — see their docs in core/foundation/errors/failure.dart.
        //
        // The server's own message wins when it sends one: it can be more
        // specific than anything hardcoded here ("suspended until Sunday").
        // The local key is the floor, not the preference.
        LoginPendingApprovalFailure(:final serverMessage) => ShowError(
            title: LocaleKeys.error.tr(),
            message: serverMessage?.isNotEmpty == true
                ? serverMessage!
                : LocaleKeys.loginPendingApproval.tr(),
          ),

        // `reason` outranks even the server message: it is the admin's own
        // words about this specific account, and it is the only thing that
        // makes a rejection actionable.
        LoginRejectedFailure(:final reason, :final serverMessage) => ShowError(
            title: LocaleKeys.error.tr(),
            message: reason?.isNotEmpty == true
                ? reason!
                : serverMessage?.isNotEmpty == true
                    ? serverMessage!
                    : LocaleKeys.loginRejected.tr(),
          ),

        LoginSuspendedFailure(:final serverMessage) => ShowError(
            title: LocaleKeys.error.tr(),
            message: serverMessage?.isNotEmpty == true
                ? serverMessage!
                : LocaleKeys.loginSuspended.tr(),
          ),

        LoginDisabledFailure(:final serverMessage) => ShowError(
            title: LocaleKeys.error.tr(),
            message: serverMessage?.isNotEmpty == true
                ? serverMessage!
                : LocaleKeys.loginDisabled.tr(),
          ),

        RegisterFailure(:final serverMessage) => ShowError(
            title: LocaleKeys.error.tr(),
            message: serverMessage?.isNotEmpty == true
                ? serverMessage!
                : LocaleKeys.somethingWrong.tr(),
          ),

        // ── Transport failures ───────────────────────────────────────────────

        NoInternetFailure() => ShowError(
            title: LocaleKeys.error.tr(),
            message: LocaleKeys.noInternetConnection.tr(),
            canRetry: true,
          ),

        TimeoutFailure() => ShowError(
            title: LocaleKeys.error.tr(),
            message: LocaleKeys.sessionTimedOut.tr(),
            canRetry: true,
          ),

        BadCertificateFailure() => ShowError(
            title: LocaleKeys.error.tr(),
            message: LocaleKeys.noInternetConnection.tr(),
          ),

        // ── Server response failures ─────────────────────────────────────────

        // The wait the server asked for is appended when it sent one — it is
        // the only actionable fact in a rate-limit refusal, and it used to be
        // parsed and then dropped on the floor.
        //
        // `canRetry: false` on purpose: retrying immediately is precisely the
        // behaviour that produced the 429, and a retry button here invites the
        // user to make it worse.
        RateLimitFailure(:final retryAfterSeconds, :final serverMessage) =>
          ShowError(
            title: LocaleKeys.error.tr(),
            message: _withWait(
              serverMessage?.isNotEmpty == true
                  ? serverMessage!
                  : LocaleKeys.tooManyRequests.tr(),
              retryAfterSeconds,
            ),
          ),

        // ── Server is up but not serving — 502 / 503 / 504 ───────────────────

        // Retryable, and said so: "busy right now, try shortly" is true here
        // and false for the 500 below, which is why they are separate types.
        ServiceUnavailableFailure(
          :final retryAfterSeconds,
          :final serverMessage
        ) =>
          ShowError(
            title: LocaleKeys.error.tr(),
            message: _withWait(
              serverMessage?.isNotEmpty == true
                  ? serverMessage!
                  : LocaleKeys.serviceUnavailable.tr(),
              retryAfterSeconds,
            ),
            canRetry: true,
          ),

        // Nothing answered, but the device is online — so the fault is the
        // server's, and the message must not blame the user's connection.
        ServerUnreachableFailure() => ShowError(
            title: LocaleKeys.error.tr(),
            message: LocaleKeys.serverUnreachable.tr(),
            canRetry: true,
          ),

        // A genuine defect inside the server. `canRetry` stays **false**: the
        // same request in two seconds reproduces the same 500, and a retry
        // button that never works is a worse answer than none.
        ServerFailure(:final serverMessage) => ShowError(
            title: LocaleKeys.error.tr(),
            message: serverMessage?.isNotEmpty == true
                ? serverMessage!
                : LocaleKeys.serverError.tr(),
          ),

        BusinessFailure(:final serverMessage) => ShowError(
            title: LocaleKeys.error.tr(),
            message: serverMessage?.isNotEmpty == true
                ? serverMessage!
                : LocaleKeys.somethingWrong.tr(),
          ),

        // ── Validation failures ───────────────────────────────────────────────

        // Local validation error — show the first field message when available,
        // otherwise the general message, otherwise the generic invalidInput key.
        ValidationFailure(:final fields, :final message) => ShowError(
            title: LocaleKeys.error.tr(),
            message: fields.isNotEmpty
                ? fields.values.first
                : message?.isNotEmpty == true
                    ? message!
                    : LocaleKeys.invalidInput.tr(),
          ),

        // ── Parse failures ────────────────────────────────────────────────────

        // All three ParseErrorKind values show the same user-facing message.
        // The kind + fieldName are preserved in diagnosticMessage for logging.
        ParseFailure() => ShowError(
            title: LocaleKeys.error.tr(),
            message: LocaleKeys.parseDataError.tr(),
          ),

        // ── Permission failures ────────────────────────────────────────────────

        // permanentlyDenied → direct user to OS Settings (canRetry=false).
        // denied / restricted → show informational message (canRetry=true only
        // for denied so the caller can re-request).
        PermissionFailure(:final reason) => ShowError(
            title: LocaleKeys.error.tr(),
            message: reason == PermissionDeniedReason.permanentlyDenied
                ? LocaleKeys.permissionPermanentlyDenied.tr()
                : LocaleKeys.permissionDenied.tr(),
            canRetry: reason == PermissionDeniedReason.denied,
          ),

        // ── Storage failures ───────────────────────────────────────────────────

        // operation + key are for logging only — user sees the generic cacheError.
        StorageFailure() => ShowError(
            title: LocaleKeys.error.tr(),
            message: LocaleKeys.cacheError.tr(),
          ),

        // ── Local failures ────────────────────────────────────────────────────

        CacheFailure(:final message) => ShowError(
            title: LocaleKeys.error.tr(),
            message: message ?? LocaleKeys.cacheError.tr(),
          ),

        UnknownFailure(:final message) => ShowError(
            title: LocaleKeys.error.tr(),
            message: message?.isNotEmpty == true
                ? message!
                : LocaleKeys.unknownError.tr(),
            canRetry: true,
          ),

        // ── Sync conflict ──────────────────────────────────────────────────────

        // Conflicts are resolved internally by SyncConflictResolver.
        // For manual strategy: ConflictDetected event is emitted separately.
        // Never show a conflict toast — the resolver owns the UX decision.
        ConflictFailure() => const Silent(),

        // ── Multi-Device session failures ─────────────────────────────────────

        DeviceNotFoundFailure() => ShowError(
            title: LocaleKeys.error.tr(),
            message: LocaleKeys.deviceNotFound.tr(),
          ),

        NotPrimaryDeviceFailure() => ShowError(
            title: LocaleKeys.error.tr(),
            message: LocaleKeys.notPrimaryDevice.tr(),
          ),
      };

  /// Appends the server's own `Retry-After` to a message, as a **bucket rather
  /// than a number**.
  ///
  /// Interpolating the count — "أعد المحاولة بعد {} ثانية" — is ungrammatical in
  /// Arabic for most values it would receive: the counted noun changes form
  /// across 1, 2, 3–10 and 11+ (ثانية · ثانيتان · ثوانٍ · ثانية). Getting that
  /// right needs the six CLDR plural categories, and this project wires no
  /// plurals in `easy_localization` at all — so an interpolated string would
  /// read as broken Arabic to every user, for a precision nobody acts on.
  ///
  /// "Less than a minute" / "a few minutes" / "later" is what a person does
  /// with the number anyway, and it is correct in both languages for every
  /// input.
  ///
  /// Returns [base] untouched when the server named no wait — the common case.
  /// A message that invents a delay the server never promised is worse than one
  /// that stays quiet.
  static String _withWait(String base, int? retryAfterSeconds) {
    if (retryAfterSeconds == null || retryAfterSeconds <= 0) return base;

    final hint = switch (retryAfterSeconds) {
      <= 60 => LocaleKeys.retryAfterUnderMinute.tr(),
      <= 300 => LocaleKeys.retryAfterFewMinutes.tr(),
      _ => LocaleKeys.retryAfterLater.tr(),
    };
    return '$base $hint';
  }
}
