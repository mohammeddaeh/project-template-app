import 'dart:async';
import 'dart:convert';

import 'package:app_template/core/foundation/contracts/account_scoped_store.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/notification_center/domain/notification_center_item.dart';
import 'package:app_template/modules/notification_center/notification_center_config.dart';

/// Persists the received-notifications list and broadcasts it on every
/// change. The single source of truth [NotificationCenterCubit] reads from
/// and [NotificationCenterListener] writes into.
///
/// [AccountScopedStore]: the list belongs to whoever was signed in when each
/// notification arrived — a device handed to someone else must not show them
/// the previous account's notifications. Registered under that interface in
/// `integration/notification_center_bootstrap.dart` so `AccountDataCleaner`
/// wipes it on logout/account-switch, the same two-registrations pattern
/// documented on the contract itself (`AccountScopedStore`).
class NotificationCenterStore implements AccountScopedStore {
  NotificationCenterStore(this._storage);

  static const _key = 'notification_center_items';

  final StorageService _storage;
  final _controller = StreamController<List<NotificationCenterItem>>.broadcast();
  List<NotificationCenterItem> _items = const [];

  List<NotificationCenterItem> get items => List.unmodifiable(_items);

  /// Emits the full list on every mutation — including the initial [load].
  Stream<List<NotificationCenterItem>> get changes => _controller.stream;

  /// Restores the persisted list. Called once from
  /// `NotificationCenterPlugin.initialize` before anything reads [items].
  Future<void> load() async {
    final raw = await _storage.readStringList(_key) ?? const [];
    // سطرٌ معطوب واحد لا يُفرغ القائمة كلَّها — يُسقَط وحده، سواء عطبه
    // بصيغة JSON نفسِها (`jsonDecode` يرمي) أو بحقولها (`tryFromJson` تُعيد
    // `null`).
    _items = raw.map(_tryDecode).whereType<NotificationCenterItem>().toList();
    _emit();
  }

  NotificationCenterItem? _tryDecode(String raw) {
    try {
      return NotificationCenterItem.tryFromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> add(NotificationCenterItem item) async {
    _items = [item, ..._items];
    if (_items.length > NotificationCenterConfig.maxStored) {
      _items = _items.sublist(0, NotificationCenterConfig.maxStored);
    }
    await _persist();
  }

  Future<void> markRead(String id) async {
    _items = [
      for (final item in _items)
        if (item.id == id) item.copyWith(read: true) else item,
    ];
    await _persist();
  }

  Future<void> markAllRead() async {
    _items = [for (final item in _items) item.copyWith(read: true)];
    await _persist();
  }

  Future<void> clearAll() async {
    _items = const [];
    await _persist();
  }

  Future<void> _persist() async {
    _emit();
    await _storage.writeStringList(
      _key,
      [for (final item in _items) jsonEncode(item.toJson())],
    );
  }

  void _emit() => _controller.add(items);

  @override
  Future<void> clearForAccount() => clearAll();
}
