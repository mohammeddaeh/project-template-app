import 'package:dio/dio.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/errors/dio_failure_mapper.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// Central entry point for all error-to-Failure mapping.
abstract final class FailureMapperRegistry {
  const FailureMapperRegistry._();

  static DioFailureMapper _dioMapper = const DioFailureMapper();

  /// Lets the mapper tell "this device is offline" apart from "the server is
  /// closed" — two situations Dio reports identically and that need opposite
  /// messages. See [ServerUnreachableFailure].
  ///
  /// Wired once by the composition root, because this registry is `static` (it
  /// is reached from repositories, interceptors and use cases that hold no
  /// container) while [NetworkStateMonitor] is a DI singleton. Leaving it
  /// unwired is a supported state, not a broken one: every connection error
  /// then keeps its previous classification.
  static void useNetworkStateProbe(NetworkStateProbe probe) {
    _dioMapper = DioFailureMapper(networkState: probe);
  }

  /// Restores the unwired default. Tests only — a probe left over from one test
  /// silently changes what the next one classifies.
  static void resetNetworkStateProbe() {
    _dioMapper = const DioFailureMapper();
  }

  static Failure map(Object error, {String source = 'unknown'}) {
    final failure = _classify(error);
    _logFailure(error: error, failure: failure, source: source);
    return failure;
  }

  static Failure _classify(Object error) => switch (error) {
        // ── Already a typed Failure — pass through ──────────────────────────
        Failure() => error,

        // ── Dio network/HTTP errors ──────────────────────────────────────────
        DioException() => _dioMapper.map(error),

        // ── JSON parse errors (thrown by Retrofit / fromJson, NOT via Dio) ──
        // FormatException: response body is not valid JSON (e.g. HTML response).
        FormatException() => ParseFailure(
            kind: ParseErrorKind.malformedJson,
            message: error.message,
          ),

        // TypeError: wrong Dart type in a JSON field (int got "abc", etc.).
        TypeError() => ParseFailure(
            kind: ParseErrorKind.typeMismatch,
            message: error.toString(),
          ),

        // ── Catch-all ────────────────────────────────────────────────────────
        _ => UnknownFailure(message: error.toString()),
      };

  // NOTE — CheckedFromJsonException (json_annotation):
  // If your models use @JsonSerializable(checked: true), override this method
  // in your project to handle CheckedFromJsonException, which provides the
  // exact field name that failed (error.key) for richer diagnostics.

  static void _logFailure({
    required Object error,
    required Failure failure,
    required String source,
  }) {
    LogService.error(
      '[${failure.runtimeType}] source=$source msg=${failure.diagnosticMessage ?? '-'}',
      tag: 'FAILURE-MAPPER',
      error: error,
    );
  }
}
