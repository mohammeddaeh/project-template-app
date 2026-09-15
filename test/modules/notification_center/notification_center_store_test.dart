import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/notification_center/data/notification_center_store.dart';
import 'package:app_template/modules/notification_center/domain/notification_center_item.dart';
import 'package:app_template/modules/notification_center/notification_center_config.dart';

/// خزنٌ في الذاكرة — بلا SharedPreferences حقيقيّة بالاختبار.
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

NotificationCenterItem _item(String id, {bool read = false, String? title}) =>
    NotificationCenterItem(
      id: id,
      title: title ?? 'title-$id',
      body: 'body-$id',
      receivedAt: DateTime(2026, 1, 1),
      read: read,
    );

void main() {
  late _FakeStorage storage;
  late NotificationCenterStore store;

  setUp(() {
    storage = _FakeStorage();
    store = NotificationCenterStore(storage);
  });

  test('load() on an empty store leaves items empty, does not throw', () async {
    await store.load();
    expect(store.items, isEmpty);
  });

  test('add() prepends — newest first', () async {
    await store.load();
    await store.add(_item('1'));
    await store.add(_item('2'));
    expect(store.items.map((i) => i.id), ['2', '1']);
  });

  test('changes emits the full list on every mutation', () async {
    await store.load();
    final emissions = <int>[];
    final sub = store.changes.listen((items) => emissions.add(items.length));

    await store.add(_item('1'));
    await store.add(_item('2'));
    await store.markRead('1');
    await pumpEventQueue();

    expect(emissions, [1, 2, 2]);
    await sub.cancel();
  });

  test('markRead flips only the matching item', () async {
    await store.load();
    await store.add(_item('1'));
    await store.add(_item('2'));
    await store.markRead('1');

    final byId = {for (final i in store.items) i.id: i.read};
    expect(byId, {'1': true, '2': false});
  });

  test('markAllRead flips every item', () async {
    await store.load();
    await store.add(_item('1'));
    await store.add(_item('2'));
    await store.markAllRead();

    expect(store.items.every((i) => i.read), isTrue);
  });

  test('clearAll empties the list', () async {
    await store.load();
    await store.add(_item('1'));
    await store.clearAll();
    expect(store.items, isEmpty);
  });

  test('clearForAccount (AccountScopedStore) clears exactly like clearAll', () async {
    await store.load();
    await store.add(_item('1'));
    await store.clearForAccount();
    expect(store.items, isEmpty);
  });

  test('persists across a fresh store reading the same storage', () async {
    await store.load();
    await store.add(_item('1'));

    final reloaded = NotificationCenterStore(storage);
    await reloaded.load();
    expect(reloaded.items.map((i) => i.id), ['1']);
  });

  test('a single corrupt stored line is dropped, not fatal to the rest', () async {
    await storage.writeStringList('notification_center_items', [
      'not json at all',
      '{"id": "ok", "received_at": "2026-01-01T00:00:00.000"}',
    ]);
    await store.load();
    expect(store.items.map((i) => i.id), ['ok']);
  });

  test('oldest items are dropped past NotificationCenterConfig.maxStored', () async {
    await store.load();
    for (var i = 0; i < NotificationCenterConfig.maxStored + 5; i++) {
      await store.add(_item('$i'));
    }
    expect(store.items.length, NotificationCenterConfig.maxStored);
    // آخر ما أُضيف يبقى، وأوّل ما أُضيف هو ما سقط.
    expect(store.items.first.id, '${NotificationCenterConfig.maxStored + 4}');
    expect(store.items.map((i) => i.id), isNot(contains('0')));
  });
}
