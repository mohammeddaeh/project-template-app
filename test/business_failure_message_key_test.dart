import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/errors/dio_failure_mapper.dart';

/// `message_key` has to survive the wire — and when it does not, **everything
/// still looks fine**.
///
/// A refusal is an HTTP 4xx, which Dio raises as an exception. So the failure
/// is built here, in the mapper, and never by a datasource's `_parse` — that
/// branch is only reached by the rare `200 { status: false }` shape. Every
/// repository that read `res.error?.data?['message_key']` was therefore reading
/// `null` for every real refusal.
///
/// Nothing announced it. The server's sentence still arrived and still
/// displayed, so the refusal looked handled; only the branch keyed on WHICH
/// rule refused went quiet. Two screens degraded to the same red toast every
/// other failure produces: "create the role anyway" for a duplicate permission
/// set, and the two-answer sheet for a last-holder warning. Both were built,
/// wired, and unreachable.
void main() {
  const mapper = DioFailureMapper();

  DioException badResponse(int status, Object? body) {
    final options = RequestOptions(path: '/x');
    return DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<Object?>(
        requestOptions: options,
        statusCode: status,
        data: body,
      ),
    );
  }

  Map<String, Object?> envelope(int code, String message, Object? data) => {
    'status': false,
    'message': message,
    'code': code,
    'data': ?data,
  };

  group('message_key survives a thrown 4xx', () {
    test('409 carries the key, and a 409 without one carries null', () {
      final withKey = mapper.map(
        badResponse(
          409,
          envelope(409, 'آخر موظف', {
            'message_key': 'last_qualified_staff',
            'overridable': true,
          }),
        ),
      );
      expect(withKey, isA<BusinessFailure>());
      expect(
        (withKey as BusinessFailure).messageKey,
        'last_qualified_staff',
      );
      // The server's sentence must still come through — losing it while
      // gaining the key would trade one silent gap for another.
      expect(withKey.serverMessage, 'آخر موظف');

      // The opposite. An endpoint that reports no key must yield `null`, not a
      // guess: callers branch on equality, so a fabricated value would run the
      // wrong branch instead of falling through to "ordinary error".
      final withoutKey = mapper.map(
        badResponse(409, envelope(409, 'تعارض', null)),
      );
      expect((withoutKey as BusinessFailure).messageKey, isNull);
    });

    test('not 409-only — any business 4xx carries it', () {
      // 422 and 400 refusals key on it too. Scoping the lift to 409 would work
      // for today's two callers and quietly fail the next one.
      final failure = mapper.map(
        badResponse(
          422,
          envelope(422, 'الدور غير متاح', {
            'message_key': 'role_not_self_registerable',
          }),
        ),
      );
      expect(
        (failure as BusinessFailure).messageKey,
        'role_not_self_registerable',
      );
    });

    test('a sync conflict is still not a business failure', () {
      // 409 carries two unrelated meanings. Reaching into `data` must not turn
      // the sync shape into a BusinessFailure — that one is resolved by
      // `modules/sync/` and is deliberately never shown to anyone.
      final failure = mapper.map(
        badResponse(409, {
          'server_version': {'v': 2},
          'client_version': {'v': 1},
          'conflict_fields': ['name'],
        }),
      );
      expect(failure, isA<ConflictFailure>());
    });

    test('a body with no data object does not crash the mapper', () {
      // 5xx pages, HTML error bodies, empty responses. The mapper runs on every
      // failed request in the app, so a malformed body must degrade to "no
      // key", never to an exception thrown while handling an exception.
      expect(
        (mapper.map(badResponse(400, 'not json at all')) as BusinessFailure)
            .messageKey,
        isNull,
      );
      expect(
        (mapper.map(badResponse(400, {'data': 'not a map'})) as BusinessFailure)
            .messageKey,
        isNull,
      );
    });
  });
}
