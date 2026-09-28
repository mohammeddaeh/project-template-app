import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';

class _FakeSecureStorage implements SecureStorageService {
  final Map<String, String> _values = {};
  @override
  Future<void> write(String key, String value) async => _values[key] = value;
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<Map<String, String>> readAll() async => Map.of(_values);
  @override
  Future<void> delete(String key) async => _values.remove(key);
  @override
  Future<void> clear() async => _values.clear();
  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);
}

/// **The second sign-out of a launch did nothing — and nothing failed.**
///
/// `AuthEventBus` fires `sessionExpired` once per session so a burst of 401s
/// navigates once. The re-arm existed and nothing in `lib/` called it, so the
/// first expiry of a launch routed to sign-in and every later one was
/// swallowed: token cleared, app left on a shell with no identity.
///
/// Every case is paired with its opposite: re-arming on its own proves nothing
/// (a bus that never deduplicates passes it, and that bus navigates once per
/// concurrent 401), so the dedupe *within* a session is pinned beside it.
void main() {
  late SessionRepository session;
  late List<AuthEvent> events;
  late StreamSubscription<AuthEvent> sub;

  setUp(() {
    AuthEventBus.instance.resetForTest();
    session = SessionRepository(_FakeSecureStorage());
    events = [];
    sub = AuthEventBus.instance.stream.listen(events.add);
  });

  tearDown(() => sub.cancel());

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('a new session re-arms expiry — the second sign-out still navigates', () async {
    await session.saveToken('first');
    AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    session.clearSession();

    await session.saveToken('second');
    AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    await flush();

    expect(events, [AuthEvent.sessionExpired, AuthEvent.sessionExpired]);
  });

  test('re-arms revocation too — the flags are reset together', () async {
    await session.saveToken('first');
    AuthEventBus.instance.emit(AuthEvent.sessionRevoked);
    await session.saveToken('second');
    AuthEventBus.instance.emit(AuthEvent.sessionRevoked);
    await flush();

    expect(events, [AuthEvent.sessionRevoked, AuthEvent.sessionRevoked]);
  });

  test('within one session, concurrent 401s still navigate once', () async {
    await session.saveToken('only');
    AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    await flush();

    expect(events, [AuthEvent.sessionExpired]);
  });

  test('clearing a session does not re-arm — only a new one does', () async {
    await session.saveToken('only');
    AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    session.clearSession();
    AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    await flush();

    expect(events, [AuthEvent.sessionExpired]);
  });
}
