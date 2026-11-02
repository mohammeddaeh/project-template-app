import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/token_inspector/domain/grant_facts.dart';
import 'package:app_template/modules/token_inspector/domain/inspector_event.dart';

/// السجلّ ووقائع آخر ردٍّ على القرص — **يبقيان بعد الإغلاق وبعد الخروج**.
///
/// ⛔ **ولا يُضافان إلى `AccountDataCleaner` ولا `LocalDataWiper`**: الخروجُ
/// حدثٌ يُراد رؤيتُه بالسجلّ، ومسحُه معه يمحو الدليل. يُمسحان بزرّ Clear وحده.
/// ولا توكن فيهما — بصماتٌ ووقائع.
class InspectorStore {
  const InspectorStore(this._storage);

  final StorageService _storage;

  static const _eventsKey = 'token_inspector.events';
  static const _factsKey = 'token_inspector.facts';

  Future<List<InspectorEvent>> readEvents() async {
    final raw = await _storage.readStringList(_eventsKey) ?? const [];
    return raw
        .map(InspectorEvent.tryDecode)
        .whereType<InspectorEvent>()
        .toList();
  }

  Future<void> writeEvents(List<InspectorEvent> events) => _storage
      .writeStringList(_eventsKey, [for (final e in events) e.encode()]);

  Future<GrantFacts?> readFacts() async =>
      GrantFacts.tryDecode(await _storage.readString(_factsKey));

  Future<void> writeFacts(GrantFacts facts) =>
      _storage.writeString(_factsKey, facts.encode());

  Future<void> clear() async {
    await _storage.delete(_eventsKey);
    await _storage.delete(_factsKey);
  }
}
