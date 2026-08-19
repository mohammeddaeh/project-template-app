import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/foundation/contracts/auth_network_gateway.dart';
import 'package:app_template/core/foundation/contracts/token_refresh_gateway.dart';
import 'package:app_template/core/foundation/contracts/unsynced_work_probe.dart';
import 'package:app_template/core/infra/network/interceptors/token_refresh_interceptor.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';

/// Locks down P0.6: **a dropped packet must not sign anyone out.**
///
/// ## The defect this file exists for
///
/// `TokenRefreshInterceptor` caught every failure of the refresh call in one
/// `catch` and treated them alike: clear the token, clear the cached user, emit
/// `sessionExpired`, land on the login screen. So a phone that lost signal in
/// the second between a 401 and its renewal was signed out.
///
/// On a phone that is a nuisance. On a field device holding a queue of unsynced
/// work it is worse: the user is ejected to a login screen they cannot pass —
/// there is no network to log in with — while a morning's writes sit behind an
/// account the app no longer believes in.
///
/// Nothing here can be verified by hand: it needs a 401, then a connection that
/// dies during the renewal, in that order.
void main() {
  setUp(AuthEventBus.instance.resetForTest);
  tearDown(AuthEventBus.instance.resetForTest);

  group('a refresh that never reached a server', () {
    test('keeps the session and does not sign the user out', () async {
      final gateway = _RecordingRefreshGateway(
        // No response — the request died in transit.
        throws: DioException.connectionError(
          requestOptions: RequestOptions(path: '/anything'),
          reason: 'Network is unreachable',
        ),
      );
      final events = <AuthEvent>[];
      final sub = AuthEventBus.instance.stream.listen(events.add);

      await _fireUnauthorised(gateway);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // The credential survives: nothing refused it.
      expect(gateway.onRefreshFailedCalls, 0);
      expect(events, [AuthEvent.sessionRefreshDeferred]);
      expect(events, isNot(contains(AuthEvent.sessionExpired)));
    });

    test('a cancelled request is not a refusal either', () async {
      // Leaving a screen mid-request must never end a session — and a cancel
      // carries no response, so it takes the same path.
      final gateway = _RecordingRefreshGateway(
        throws: DioException.requestCancelled(
          requestOptions: RequestOptions(path: '/anything'),
          reason: 'user left the screen',
        ),
      );
      final events = <AuthEvent>[];
      final sub = AuthEventBus.instance.stream.listen(events.add);

      await _fireUnauthorised(gateway);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(gateway.onRefreshFailedCalls, 0);
      expect(events, isNot(contains(AuthEvent.sessionExpired)));
    });

    test('every attempt is reported — the event is not deduplicated', () async {
      // Unlike sessionExpired, this one describes right now. Collapsing repeats
      // would leave a UI showing "syncing" long after it stopped being true.
      final events = <AuthEvent>[];
      final sub = AuthEventBus.instance.stream.listen(events.add);

      AuthEventBus.instance
        ..emit(AuthEvent.sessionRefreshDeferred)
        ..emit(AuthEvent.sessionRefreshDeferred);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events, hasLength(2));
    });
  });

  group('a refresh the server actually refused', () {
    test('clears the session, exactly as before', () async {
      final gateway = _RecordingRefreshGateway(
        throws: DioException.badResponse(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/auth/refresh'),
          response: Response<dynamic>(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/auth/refresh'),
          ),
        ),
      );
      final events = <AuthEvent>[];
      final sub = AuthEventBus.instance.stream.listen(events.add);

      await _fireUnauthorised(gateway);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(gateway.onRefreshFailedCalls, 1);
      expect(events, contains(AuthEvent.sessionExpired));
    });

    test('a client with no token to rotate is terminal, not transient', () async {
      // `StateError` from the gateway carries no response either — but it is
      // not a connectivity problem: the client holds a credential it cannot
      // renew, and retrying forever would be worse than saying so.
      final gateway = _RecordingRefreshGateway(
        throws: StateError('No session token to refresh'),
      );
      final events = <AuthEvent>[];
      final sub = AuthEventBus.instance.stream.listen(events.add);

      await _fireUnauthorised(gateway);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(gateway.onRefreshFailedCalls, 1);
      expect(events, contains(AuthEvent.sessionExpired));
    });
  });

  group('UnsyncedWorkProbe', () {
    test('an app with no offline queue reports nothing pending', () async {
      expect(await const NoUnsyncedWorkProbe().pendingOperations(), 0);
    });
  });
}

/// Drives the interceptor's 401 path with a gateway whose refresh fails.
Future<void> _fireUnauthorised(_RecordingRefreshGateway gateway) async {
  final interceptor = TokenRefreshInterceptor(
    Dio(),
    gateway,
    _TokenHolder(),
  );

  final completer = _CapturingHandler();
  interceptor.onError(
    DioException.badResponse(
      statusCode: 401,
      requestOptions: RequestOptions(path: '/notes'),
      response: Response<dynamic>(
        statusCode: 401,
        requestOptions: RequestOptions(path: '/notes'),
      ),
    ),
    completer,
  );
  await completer.done;
}

class _RecordingRefreshGateway implements TokenRefreshGateway {
  _RecordingRefreshGateway({required this.throws});

  final Object throws;
  int onRefreshFailedCalls = 0;

  @override
  Future<void> refresh() async => throw throws;

  @override
  Future<void> onRefreshFailed() async => onRefreshFailedCalls++;
}

class _TokenHolder implements AuthNetworkGateway {
  @override
  String? getToken() => 'a-token';

  @override
  void clearSession() {}
}

/// Minimal [ErrorInterceptorHandler] stand-in — the real one cannot be
/// constructed outside Dio's own chain.
class _CapturingHandler implements ErrorInterceptorHandler {
  final _completer = Completer<void>();

  Future<void> get done => _completer.future;

  void _finish() {
    if (!_completer.isCompleted) _completer.complete();
  }

  @override
  void next(DioException err) => _finish();

  @override
  void reject(DioException error) => _finish();

  @override
  void resolve(Response<dynamic> response) => _finish();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
