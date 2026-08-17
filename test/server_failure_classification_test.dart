import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/errors/dio_failure_mapper.dart';
import 'package:app_template/core/platform/connectivity/network_state.dart';

/// What the server says wrong, and whether the app repeats it back correctly.
///
/// Every case here is a state a real deployment reaches — an overloaded proxy,
/// a maintenance window, a server that is simply switched off — and each one
/// used to arrive at the user as the same sentence as all the others.
void main() {
  final options = RequestOptions(path: '/notes');

  DioException badResponse(int status, {Map<String, List<String>>? headers}) =>
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: status,
          headers: Headers.fromMap(headers ?? const {}),
        ),
      );

  group('5xx is not one thing', () {
    const mapper = DioFailureMapper();

    test('502, 503 and 504 are transient — the retryable kind', () {
      for (final status in [502, 503, 504]) {
        final failure = mapper.map(badResponse(status));
        expect(
          failure,
          isA<ServiceUnavailableFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            status,
          ),
          reason: '$status means "busy now, fine later" — not a defect',
        );
      }
    });

    test('500 stays a defect, kept apart from the transient three', () {
      expect(mapper.map(badResponse(500)), isA<ServerFailure>());
      expect(mapper.map(badResponse(501)), isA<ServerFailure>());
    });

    test('a 503 carries the wait the server asked for', () {
      final failure = mapper.map(
        badResponse(503, headers: {'retry-after': ['120']}),
      );
      expect(
        failure,
        isA<ServiceUnavailableFailure>()
            .having((f) => f.retryAfterSeconds, 'retryAfterSeconds', 120),
        reason: 'Retry-After is defined on 503, not only on 429',
      );
    });

    test('4xx is untouched by the split', () {
      expect(mapper.map(badResponse(422)), isA<BusinessFailure>());
      expect(mapper.map(badResponse(403)), isA<ForbiddenFailure>());
      expect(mapper.map(badResponse(401)), isA<UnauthorizedFailure>());
    });
  });

  group('offline device vs closed server', () {
    DioException connectionError() => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );

    test('device online + nothing answered → the server is the culprit', () {
      const mapper = DioFailureMapper(networkState: _online);
      expect(mapper.map(connectionError()), isA<ServerUnreachableFailure>());
    });

    test('device offline → still the connection, as before', () {
      const mapper = DioFailureMapper(networkState: _offline);
      expect(mapper.map(connectionError()), isA<NoInternetFailure>());
    });

    test('link state unknown → falls back rather than accusing the server', () {
      const mapper = DioFailureMapper(networkState: _unknown);
      expect(
        mapper.map(connectionError()),
        isA<NoInternetFailure>(),
        reason: 'an unproven claim about the server is worse than a vague one',
      );
    });

    test('no probe wired at all → the historical answer, unchanged', () {
      const mapper = DioFailureMapper();
      expect(mapper.map(connectionError()), isA<NoInternetFailure>());
    });

    test('a refused socket reaches the same conclusion', () {
      const mapper = DioFailureMapper(networkState: _online);
      final failure = mapper.map(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: const SocketException('Connection refused'),
        ),
      );
      expect(failure, isA<ServerUnreachableFailure>());
    });
  });

  group('Retry-After, both legal forms', () {
    Headers header(String value) => Headers.fromMap({
          'retry-after': [value],
        });

    test('delta-seconds', () {
      expect(DioFailureMapper.retryAfterSeconds(header('30')), 30);
    });

    test('HTTP-date — the form that used to be dropped to null', () {
      final now = DateTime.utc(2026, 8, 16, 12, 0, 0);
      final seconds = DioFailureMapper.retryAfterSeconds(
        header('Sun, 16 Aug 2026 12:02:00 GMT'),
        now: now,
      );
      expect(seconds, 120);
    });

    test('a date already past yields null, never a negative wait', () {
      final now = DateTime.utc(2026, 8, 16, 12, 0, 0);
      expect(
        DioFailureMapper.retryAfterSeconds(
          header('Sun, 16 Aug 2026 11:58:00 GMT'),
          now: now,
        ),
        isNull,
      );
    });

    test('garbage does not throw — a bad header is not a crash', () {
      expect(DioFailureMapper.retryAfterSeconds(header('soon')), isNull);
      expect(DioFailureMapper.retryAfterSeconds(header('')), isNull);
      expect(DioFailureMapper.retryAfterSeconds(null), isNull);
    });

    test('a negative delta is refused', () {
      expect(DioFailureMapper.retryAfterSeconds(header('-5')), isNull);
    });
  });
}

NetworkState _online() => NetworkState.online;
NetworkState _offline() => NetworkState.offline;
NetworkState _unknown() => NetworkState.unknown;

