import 'dart:async';

/// Announces that an entity's local rows changed.
///
/// ## Why this is a shared object and not a stream on the store
///
/// **Three classes write `synced_entities`**, and a listener that only heard
/// one of them would be worse than no listener at all — it would refresh
/// sometimes, which reads as flakiness rather than as a missing wire:
///
/// | Writer | When |
/// |---|---|
/// | `SqlSyncEntityStore` | a pull merged server rows |
/// | `SqlSyncWriteGateway` | the user saved or deleted something |
/// | `SqlSyncQueueRepository` | a push succeeded, failed, or conflicted |
///
/// So the notifier is injected into all three, and `SyncEntityStore.watch()`
/// is a filtered view of it.
///
/// ## sqflite has no change feed
///
/// Unlike a reactive layer such as Drift, sqflite cannot tell anyone that a
/// table changed — which is why this is hand-rolled rather than obtained. The
/// cost of that is exactly one rule: **every write path must call [notify]**,
/// and forgetting it produces a screen that silently stops updating.
class SyncChangeNotifier {
  final _controller = StreamController<String>.broadcast();

  /// Entity names, as they change.
  Stream<String> get stream => _controller.stream;

  /// Announces a change to [entityName].
  ///
  /// Called **after** a write commits, never before: a listener that refreshes
  /// on the announcement would otherwise read the state that existed before it.
  void notify(String entityName) {
    if (_controller.isClosed) return;
    _controller.add(entityName);
  }

  /// Only the changes to [entityName], as a signal with no payload.
  ///
  /// Void rather than the rows themselves: a listener that gets data has to be
  /// told *which* data — which page, which filter, which sort — and the store
  /// does not know any of that. The listener re-reads on its own terms.
  Stream<void> watch(String entityName) =>
      stream.where((name) => name == entityName);

  Future<void> dispose() => _controller.close();
}
