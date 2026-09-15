import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/notification_center/data/notification_center_store.dart';
import 'package:app_template/modules/notification_center/services/notification_center_listener.dart';
import 'package:app_template/modules/push_notifications/push_notification_event.dart';
import 'package:app_template/modules/push_notifications/push_notifications_service.dart';

class _FakeStorage implements StorageService {
  final Map<String, Object?> _values = {};
  @override
  Future<void> writeString(String key, String value) async =>
      _values[key] = value;
  @override
  Future<String?> readString(String key) async => _values[key] as String?;
  @override
  Future<void> writeBool(String key, {required bool value}) async =>
      _values[key] = value;
  @override
  Future<bool?> readBool(String key) async => _values[key] as bool?;
  @override
  Future<void> writeInt(String key, int value) async => _values[key] = value;
  @override
  Future<int?> readInt(String key) async => _values[key] as int?;
  @override
  Future<void> writeDouble(String key, double value) async =>
      _values[key] = value;
  @override
  Future<double?> readDouble(String key) async => _values[key] as double?;
  @override
  Future<void> writeStringList(String key, List<String> values) async =>
      _values[key] = List<String>.of(values);
  @override
  Future<List<String>?> readStringList(String key) async =>
      (_values[key] as List<String>?)?.toList();
  @override
  Future<void> delete(String key) async => _values.remove(key);
  @override
  Future<void> clear() async => _values.clear();
  @override
  bool containsKey(String key) => _values.containsKey(key);
  @override
  Iterable<String> keys() => _values.keys;
}

/// إشعارٌ واحد فقط بثابتة — الكافي لاختبار الجسر لا خدمة FCM نفسها.
class _FakePush implements PushNotificationsService {
  final _foreground = StreamController<PushNotificationEvent>.broadcast();
  final _tap = StreamController<PushNotificationEvent>.broadcast();

  @override
  Stream<PushNotificationEvent> get foregroundStream => _foreground.stream;
  @override
  Stream<PushNotificationEvent> get tapStream => _tap.stream;

  void emitForeground(PushNotificationEvent e) => _foreground.add(e);
  void emitTap(PushNotificationEvent e) => _tap.add(e);

  @override
  Future<String?> getToken() async => 'fake-token';
  @override
  Future<void> deleteToken() async {}
  @override
  Future<void> subscribeToTopic(String topic) async {}
  @override
  Future<void> unsubscribeFromTopic(String topic) async {}

  Future<void> dispose() async {
    await _foreground.close();
    await _tap.close();
  }
}

void main() {
  late NotificationCenterStore store;
  late _FakePush push;
  late NotificationCenterListener listener;

  setUp(() async {
    store = NotificationCenterStore(_FakeStorage());
    await store.load();
    push = _FakePush();
    listener = NotificationCenterListener(store, push);
  });

  tearDown(() => push.dispose());

  test('a foreground event is added to the store', () async {
    listener.start();
    push.emitForeground(
      const PushNotificationEvent(id: '1', title: 't', body: 'b'),
    );
    await pumpEventQueue();

    expect(store.items, hasLength(1));
    expect(store.items.single.id, '1');
    expect(store.items.single.read, isFalse);
  });

  test('start() is idempotent — a second call does not double-subscribe', () async {
    listener.start();
    listener.start();
    push.emitForeground(const PushNotificationEvent(id: '1'));
    await pumpEventQueue();

    expect(store.items, hasLength(1));
  });

  test('a tap-stream event is never recorded — foreground only', () async {
    listener.start();
    push.emitTap(const PushNotificationEvent(id: '1'));
    await pumpEventQueue();

    expect(store.items, isEmpty);
  });

  test('stop() ends the subscription — a later event is not recorded', () async {
    listener.start();
    await listener.stop();
    push.emitForeground(const PushNotificationEvent(id: '1'));
    await pumpEventQueue();

    expect(store.items, isEmpty);
  });

  test('without start(), nothing is ever recorded', () async {
    push.emitForeground(const PushNotificationEvent(id: '1'));
    await pumpEventQueue();
    expect(store.items, isEmpty);
  });
}
