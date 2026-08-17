import 'dart:io';

import 'package:dio/dio.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/errors/failure_mapper.dart';
import 'package:app_template/core/infra/errors/server_message_extractor.dart';
import 'package:app_template/core/platform/connectivity/network_state.dart';

/// Answers "does this device have a link right now".
///
/// A function rather than the [NetworkStateMonitor] itself, so this mapper
/// stays constructible with `const` and testable without a platform channel.
typedef NetworkStateProbe = NetworkState Function();

/// Maps a [DioException] to a typed [Failure].
///
/// ⚠️  Contract:
/// - NO `.tr()` or localization calls — those live in [FailureUiMapper].
/// - NO navigation or side effects (handled by [AuthInterceptor]).
/// - Pure data transformation only.
class DioFailureMapper implements FailureMapper {
  const DioFailureMapper({NetworkStateProbe? networkState})
      : _networkState = networkState;

  /// Null until the composition root wires it — see
  /// [FailureMapperRegistry.useNetworkStateProbe]. When absent, a connection
  /// error keeps its historical meaning ([NoInternetFailure]) rather than
  /// guessing, so a project that never wires it loses nothing it had.
  final NetworkStateProbe? _networkState;

  @override
  Failure map(Object error) {
    if (error is! DioException) {
      return UnknownFailure(message: error.toString());
    }
    return _fromDioException(error);
  }

  Failure _fromDioException(DioException error) => switch (error.type) {
        DioExceptionType.cancel => const CancelledFailure(),
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          const TimeoutFailure(),
        DioExceptionType.connectionError => _fromConnectionError(error),
        DioExceptionType.badCertificate => const BadCertificateFailure(),
        DioExceptionType.badResponse => _fromBadResponse(error),
        DioExceptionType.unknown => _fromUnknown(error),
      };

  /// Nothing answered — but *whose* fault is it?
  ///
  /// Dio reports "no wifi" and "the server is switched off" as the same
  /// exception type, and for years this returned [NoInternetFailure] for both.
  /// That is a wrong accusation half the time: it tells a user on a healthy
  /// connection to fix their connection, so they toggle wifi and try again into
  /// the same wall.
  ///
  /// The device's own link state settles it, and only when it is actually
  /// known: [NetworkState.unknown] falls back to the old answer rather than
  /// claiming the server is down on no evidence.
  Failure _fromConnectionError(DioException error) =>
      _classifyUnreachable(error.message);

  Failure _classifyUnreachable(String? message) {
    final state = _networkState?.call();
    if (state != null && state.isOnline) {
      return ServerUnreachableFailure(message: message);
    }
    return const NoInternetFailure();
  }

  Failure _fromBadResponse(DioException error) {
    final status = error.response?.statusCode;
    final serverMessage = ServerMessageExtractor.extract(error.response?.data);

    // Split, never merged: a 403 must not sign the user out over one refused
    // action. See [ForbiddenFailure] for why the distinction is load-bearing.
    if (status == 403) {
      return ForbiddenFailure(serverMessage: serverMessage);
    }
    if (status == 401) {
      return UnauthorizedFailure(serverMessage: serverMessage);
    }
    if (status == 408) return const TimeoutFailure();
    if (status == 409) {
      final body = error.response?.data;
      final map = body is Map<String, dynamic> ? body : null;
      return ConflictFailure(
        serverVersion: map?['server_version'] as Map<String, dynamic>?,
        clientVersion: map?['client_version'] as Map<String, dynamic>?,
        conflictFields: (map?['conflict_fields'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
    }
    if (status == 429) {
      return RateLimitFailure(
        retryAfterSeconds: retryAfterSeconds(error.response?.headers),
        serverMessage: serverMessage,
      );
    }

    // 502 · 503 · 504 — reachable but not serving, and **transient**. Kept
    // apart from the 500s below so the UI can offer a retry that is worth
    // taking and say "shortly" without lying. `Retry-After` is read here for
    // the same reason it is read on a 429: the server named a wait, and
    // ignoring it means retrying straight back into an overload it just
    // announced.
    if (status == 502 || status == 503 || status == 504) {
      return ServiceUnavailableFailure(
        statusCode: status!,
        retryAfterSeconds: retryAfterSeconds(error.response?.headers),
        serverMessage: serverMessage,
      );
    }

    if (status != null && status >= 500) {
      return ServerFailure(statusCode: status, serverMessage: serverMessage);
    }
    return BusinessFailure(statusCode: status ?? 0, serverMessage: serverMessage);
  }

  Failure _fromUnknown(DioException error) {
    // Same question as `_fromConnectionError`, reached by a different route:
    // a refused socket to a live server is the server being closed, not the
    // device being offline.
    if (error.error is SocketException) {
      return _classifyUnreachable(error.message);
    }

    // Dio wraps a FormatException when the response body is not valid JSON
    // (e.g. the server returned HTML instead of JSON).
    if (error.error is FormatException) {
      return ParseFailure(
        kind: ParseErrorKind.malformedJson,
        message: (error.error as FormatException).message,
      );
    }

    return UnknownFailure(message: error.message);
  }

  /// Reads `Retry-After` in **both** forms RFC 9110 defines.
  ///
  /// The delta-seconds form (`Retry-After: 120`) is the common one, and was the
  /// only one parsed here — so a server answering with the equally legal
  /// HTTP-date form (`Retry-After: Wed, 21 Oct 2015 07:28:00 GMT`) had its
  /// answer silently dropped to `null`, and the app retried immediately into
  /// the wall it was just asked to back off from.
  ///
  /// A date already in the past yields `null`, not a negative number: "wait
  /// -5 seconds" is not a wait, and a caller scheduling on it would compute a
  /// time in the past.
  ///
  /// `static` and `@visibleForTesting`-in-spirit: exercised directly by
  /// `test/retry_after_test.dart`, since reaching it through a live 503 would
  /// need a server that is actually overloaded.
  static int? retryAfterSeconds(Headers? headers, {DateTime? now}) {
    final raw = headers?.value('retry-after')?.trim();
    if (raw == null || raw.isEmpty) return null;

    final seconds = int.tryParse(raw);
    if (seconds != null) return seconds < 0 ? null : seconds;

    final date = _tryParseHttpDate(raw);
    if (date == null) return null;

    final delta = date.difference(now ?? DateTime.now()).inSeconds;
    return delta <= 0 ? null : delta;
  }
}

/// `HttpDate.parse` throws on anything unparseable and dart:io ships no
/// `tryParse`. A malformed header is a server's problem, not a reason to
/// replace a "service unavailable" message with a crash.
DateTime? _tryParseHttpDate(String value) {
  try {
    return HttpDate.parse(value);
  } catch (_) {
    return null;
  }
}
