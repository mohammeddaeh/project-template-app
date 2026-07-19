import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

/// Persistent distributed-safe sync lock.
///
/// ## Problem
/// An in-memory flag (bool) cannot survive process kills.
/// If the app is killed mid-sync, the flag resets to false and the next
/// sync starts immediately — potentially duplicating writes.
///
/// ## Solution
/// [acquiredAt] is written to [StorageService] before any sync work starts
/// and cleared only after [release].  On the next startup [releaseIfStale]
/// compares [acquiredAt] against [timeoutMs] and auto-releases stale locks.
///
/// ## Usage
/// ```dart
/// final lock = SyncLock(storage);
/// if (!await lock.tryAcquire()) {
///   return; // already running
/// }
/// try {
///   await doWork();
/// } finally {
///   await lock.release();
/// }
/// ```
class SyncLock {
  SyncLock(this._storage);

  final StorageService _storage;

  static const Duration _defaultTimeout = Duration(minutes: 10);

  /// Returns `true` if the lock was acquired by this call.
  /// Returns `false` if another sync is already running.
  Future<bool> tryAcquire({Duration timeout = _defaultTimeout}) async {
    final existing = await _storage.readString(PersistenceKeys.syncLockAcquiredAt);
    if (existing != null) {
      final acquiredAt = int.tryParse(existing);
      if (acquiredAt != null) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - acquiredAt;
        if (elapsed < timeout.inMilliseconds) {
          LogService.debug('SyncLock held — skip. (acquired ${elapsed}ms ago)', tag: 'SYNC');
          return false;
        }
        LogService.warning(
          'SyncLock was stale (${elapsed}ms old, timeout=${timeout.inMilliseconds}ms) — auto-releasing.',
          tag: 'SYNC',
        );
      }
    }
    await _storage.writeString(
      PersistenceKeys.syncLockAcquiredAt,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
    return true;
  }

  /// Releases the lock. Safe to call multiple times.
  Future<void> release() async {
    await _storage.delete(PersistenceKeys.syncLockAcquiredAt);
  }

  /// Called on app startup to clear any lock left over from a crash or kill.
  /// Only clears if the lock is older than [timeout].
  Future<void> releaseIfStale({Duration timeout = _defaultTimeout}) async {
    final existing = await _storage.readString(PersistenceKeys.syncLockAcquiredAt);
    if (existing == null) return;
    final acquiredAt = int.tryParse(existing);
    if (acquiredAt == null) {
      await _storage.delete(PersistenceKeys.syncLockAcquiredAt);
      return;
    }
    final elapsed = DateTime.now().millisecondsSinceEpoch - acquiredAt;
    if (elapsed >= timeout.inMilliseconds) {
      await _storage.delete(PersistenceKeys.syncLockAcquiredAt);
      LogService.warning(
        'Stale SyncLock released at startup (was ${elapsed}ms old).',
        tag: 'SYNC',
      );
    }
  }

  /// Returns `true` if the lock is currently held and not yet stale.
  Future<bool> isHeld({Duration timeout = _defaultTimeout}) async {
    final existing = await _storage.readString(PersistenceKeys.syncLockAcquiredAt);
    if (existing == null) return false;
    final acquiredAt = int.tryParse(existing);
    if (acquiredAt == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - acquiredAt;
    return elapsed < timeout.inMilliseconds;
  }
}
