import 'dart:async';

/// Authentication lifecycle events emitted by the network layer.
enum AuthEvent {
  /// The server returned 401 while the user had a valid token.
  /// The network layer clears credentials and fires this event.
  /// The presentation layer ([App] widget) reacts by navigating to login.
  sessionExpired,

  /// The server returned 401 with code SESSION_REVOKED — this device's session
  /// was explicitly revoked from another device (or the primary device).
  /// [MultiDeviceInterceptor] fires this; app.dart shows a specific message.
  sessionRevoked,
}

/// A lightweight broadcast stream for authentication lifecycle events.
///
/// **Deduplication guarantee:**
/// Multiple concurrent 401 failures will all call [emit].
/// Only the FIRST call per session fires the event.
/// Call [resetSessionState] after a successful login to re-arm.
class AuthEventBus {
  AuthEventBus._();

  static final AuthEventBus instance = AuthEventBus._();

  final _controller = StreamController<AuthEvent>.broadcast();

  bool _sessionExpiredFired = false;
  bool _sessionRevokedFired = false;

  Stream<AuthEvent> get stream => _controller.stream;

  void emit(AuthEvent event) {
    if (_controller.isClosed) return;

    if (event == AuthEvent.sessionExpired) {
      if (_sessionExpiredFired) return;
      _sessionExpiredFired = true;
    }

    if (event == AuthEvent.sessionRevoked) {
      if (_sessionRevokedFired) return;
      _sessionRevokedFired = true;
    }

    _controller.add(event);
  }

  /// Re-arms the bus after a successful login.
  void resetSessionState() {
    _sessionExpiredFired = false;
    _sessionRevokedFired = false;
  }

  /// For testing only — resets bus state between test runs.
  // ignore: invalid_use_of_visible_for_testing_member
  void resetForTest() => _sessionExpiredFired = false;
}
