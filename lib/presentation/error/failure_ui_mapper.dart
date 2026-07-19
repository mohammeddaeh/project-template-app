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

        // ── Auth-specific ───────────────────────────────────────────────────

        LoginFailure(:final serverMessage) => ShowError(
            title: LocaleKeys.error.tr(),
            message: serverMessage?.isNotEmpty == true
                ? serverMessage!
                : LocaleKeys.unauthorised.tr(),
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

        RateLimitFailure(:final serverMessage) => ShowError(
            title: LocaleKeys.error.tr(),
            message: serverMessage?.isNotEmpty == true
                ? serverMessage!
                : LocaleKeys.serverError.tr(),
          ),

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
}
