import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/notification_center/data/notification_center_store.dart';
import 'package:app_template/modules/notification_center/domain/notification_center_item.dart';
import 'package:app_template/modules/notification_center/presentation/cubits/notification_center_cubit.dart';

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

void main() {
  late NotificationCenterStore store;
  late NotificationCenterCubit cubit;

  setUp(() async {
    store = NotificationCenterStore(_FakeStorage());
    await store.load();
    cubit = NotificationCenterCubit(store);
  });

  tearDown(() => cubit.close());

  test('starts loaded with whatever the store already holds', () async {
    final state = cubit.state;
    expect(state, isA<NotificationCenterLoaded>());
    expect((state as NotificationCenterLoaded).items, isEmpty);
  });

  test('reflects an item added to the store after construction', () async {
    await store.add(NotificationCenterItem(id: '1', receivedAt: _fixedDate));
    await pumpEventQueue();

    final state = cubit.state as NotificationCenterLoaded;
    expect(state.items.map((i) => i.id), ['1']);
  });

  test('unreadCount counts only unread items', () async {
    await store.add(NotificationCenterItem(id: '1', receivedAt: _fixedDate));
    await store.add(
      NotificationCenterItem(id: '2', receivedAt: _fixedDate, read: true),
    );
    await pumpEventQueue();

    final state = cubit.state as NotificationCenterLoaded;
    expect(state.unreadCount, 1);
  });

  test('markRead updates the state through the store', () async {
    await store.add(NotificationCenterItem(id: '1', receivedAt: _fixedDate));
    await pumpEventQueue();

    await cubit.markRead('1');
    await pumpEventQueue();

    final state = cubit.state as NotificationCenterLoaded;
    expect(state.items.single.read, isTrue);
  });

  test('markAllRead clears unreadCount to zero', () async {
    await store.add(NotificationCenterItem(id: '1', receivedAt: _fixedDate));
    await store.add(NotificationCenterItem(id: '2', receivedAt: _fixedDate));
    await pumpEventQueue();

    await cubit.markAllRead();
    await pumpEventQueue();

    final state = cubit.state as NotificationCenterLoaded;
    expect(state.unreadCount, 0);
  });

  test('clearAll empties the list through the cubit', () async {
    await store.add(NotificationCenterItem(id: '1', receivedAt: _fixedDate));
    await pumpEventQueue();

    await cubit.clearAll();
    await pumpEventQueue();

    final state = cubit.state as NotificationCenterLoaded;
    expect(state.items, isEmpty);
  });

  test('close() does not crash on a late store emission (SafeCubit)', () async {
    await cubit.close();
    // إضافةٌ بعد الإغلاق — `SafeCubit.emit` تتجاهلها بصمت بدل الرمي.
    await store.add(NotificationCenterItem(id: '1', receivedAt: _fixedDate));
    await pumpEventQueue();
  });
}

final _fixedDate = DateTime(2026, 1, 1);
