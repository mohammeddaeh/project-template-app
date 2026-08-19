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

  /// A token refresh **could not be delivered** — the request never reached a
  /// server. Transient by definition, and **not** a reason to sign anyone out.
  ///
  /// ## The distinction this event exists to make
  ///
  /// [sessionExpired] used to cover both cases, because the refresh path caught
  /// every exception in one `catch` and treated them alike. But "the server
  /// refused this credential" and "this request never arrived" are opposite
  /// facts: the first is terminal, the second clears the moment the signal does.
  ///
  /// Conflating them signs a user out for a dropped packet. On a phone that is
  /// a nuisance; on a field device holding a queue of unsynced work it is worse
  /// than a nuisance, because the user is ejected to a login screen they cannot
  /// pass — there is no network to log in with — while their morning's work
  /// sits in a queue behind an account the app no longer believes in.
  ///
  /// **Nothing navigates on this event.** The session stays exactly as it was;
  /// the next request retries, and the one after that. It is emitted so the app
  /// can say "not synced yet" instead of saying nothing.
  ///
  /// Not deduplicated: every failed attempt is a fresh fact about right now.
  sessionRefreshDeferred,

  /// The server refused an action the client believed was allowed (403 with
  /// `permission_missing`).
  ///
  /// **A disagreement, not a failure** — and the disagreement is the signal:
  /// the client holds a permission set the server no longer agrees with, so it
  /// re-reads `/authz/me`. The screen corrects itself in the same breath as the
  /// refusal, which is the moment the user is looking at it.
  ///
  /// Unlike the two above it is **not deduplicated**: each refusal is fresh
  /// evidence, and `AbilitiesStore` does its own in-flight guard. Dropping all
  /// but the first would leave the app stale after the session's second change.
  ///
  /// ⚠️ Anything listening to this bus must **switch on the event**, not act on
  /// its arrival. Qirtas — the first application to add this — had a handler
  /// that navigated to sign-in for any event at all, so the first 403 over one
  /// missing permission signed the user out mid-task. See `app.dart`.
  permissionsStale,
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
  ///
  /// Delegates to [resetSessionState] rather than re-listing the flags: the
  /// hand-written copy reset only `_sessionExpiredFired`, so a test that
  /// emitted [AuthEvent.sessionRevoked] silently poisoned every test after it
  /// — the second emit was deduplicated away and the assertion failed in a
  /// file that had nothing to do with the cause. A flag added to this class
  /// now cannot be forgotten here.
  void resetForTest() => resetSessionState();
}
