import 'dart:io';

import 'package:dio/dio.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/errors/failure_mapper.dart';
import 'package:app_template/core/infra/errors/server_message_extractor.dart';

/// Maps a [DioException] to a typed [Failure].
///
/// ⚠️  Contract:
/// - NO `.tr()` or localization calls — those live in [FailureUiMapper].
/// - NO navigation or side effects (handled by [AuthInterceptor]).
/// - Pure data transformation only.
class DioFailureMapper implements FailureMapper {
  const DioFailureMapper();

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

  Failure _fromConnectionError(DioException error) =>
      const NoInternetFailure();

  Failure _fromBadResponse(DioException error) {
    final status = error.response?.statusCode;
    final serverMessage = ServerMessageExtractor.extract(error.response?.data);

    if (status == 401 || status == 403) {
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
        retryAfterSeconds: _retryAfter(error.response?.headers),
        serverMessage: serverMessage,
      );
    }
    if (status != null && status >= 500) {
      return ServerFailure(statusCode: status, serverMessage: serverMessage);
    }
    return BusinessFailure(statusCode: status ?? 0, serverMessage: serverMessage);
  }

  Failure _fromUnknown(DioException error) {
    if (error.error is SocketException) return const NoInternetFailure();

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

  static int? _retryAfter(Headers? headers) {
    final value = headers?.value('retry-after');
    return value == null ? null : int.tryParse(value.trim());
  }
}
