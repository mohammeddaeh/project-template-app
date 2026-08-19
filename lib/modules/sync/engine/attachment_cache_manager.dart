import 'package:app_template/core/platform/logging/log_service.dart';

import '../data/attachment_file_store.dart';
import '../domain/attachment_record.dart';
import '../domain/attachment_store.dart';

/// What the device is currently holding.
class CacheUsage {
  const CacheUsage({
    required this.totalBytes,
    required this.evictableBytes,
    required this.budgetBytes,
  });

  final int totalBytes;

  /// Bytes that may be reclaimed — everything the three vetoes allow.
  final int evictableBytes;

  final int budgetBytes;

  /// Bytes that cannot be reclaimed at any pressure.
  ///
  /// Worth showing to a user: "4 GB in use, 3.6 GB not removable" explains a
  /// full disk in a way "4 GB in use" never will.
  int get protectedBytes => totalBytes - evictableBytes;

  bool get isOverBudget => totalBytes > budgetBytes;
}

/// Reclaims disk space — **and refuses to, three times over.**
///
/// ## A deleted file is not a lost file
///
/// Eviction empties `local_path` and returns `download_status` to
/// [AttachmentDownloadStatus.absent]. **The row survives**, because the row is
/// what knows the url, the checksum and the owner: it is what makes the bytes
/// re-fetchable. Deleting the row instead would turn an evicted file into a
/// missing one.
///
/// ## The three vetoes
///
/// | Never evicted | Because |
/// |---|---|
/// | `origin = device` still owed to the server | Nothing anywhere can recreate it |
/// | `is_required` | A field worker who finds it missing has no network and no way back |
/// | A bundle in `ready`/`inProgress` | Same, mid-round |
///
/// The first two are enforced in SQL by [AttachmentStore.findEvictable], so a
/// sweep never even reads a protected row. The third arrives with bundles
/// (P3.5) and is listed here so its absence is visible rather than assumed.
///
/// **Without these, a cache manager becomes the cause of the failure it exists
/// to prevent**: the disk fills mid-round, the sweep runs, and the reference
/// document for the next site is deleted with no way to get it back.
class AttachmentCacheManager {
  AttachmentCacheManager(this._store, this._files, {this.budgetBytes = _defaultBudget});

  final AttachmentStore _store;
  final AttachmentFileStore _files;

  /// Ceiling for attachment storage. A default, not a rule — the number that
  /// belongs here comes out of P8 and lands in `RULES.md` §أ٦.
  final int budgetBytes;

  static const _defaultBudget = 2 * 1024 * 1024 * 1024; // 2 GB
  static const _tag = 'SYNC-CACHE';

  Future<CacheUsage> usage() async {
    final total = await _files.totalBytes();
    final evictable = await _store.findEvictable(limit: 100000);
    final evictableBytes =
        evictable.fold<int>(0, (sum, r) => sum + (r.sizeBytes ?? 0));
    return CacheUsage(
      totalBytes: total,
      evictableBytes: evictableBytes,
      budgetBytes: budgetBytes,
    );
  }

  /// Frees space **before** it is needed, not after a download has already
  /// failed for want of it.
  ///
  /// [headroomBytes] is what the caller is about to write. Sweeping only when
  /// the disk is already full means the first symptom is a failed write — and
  /// on a device mid-round, a failed write is a photograph that was never
  /// stored.
  Future<int> sweep({int headroomBytes = 0}) async {
    final current = await _files.totalBytes();
    final target = budgetBytes - headroomBytes;
    if (current <= target) return 0;

    var toFree = current - target;
    var freed = 0;

    // Least recently used first. Never-read files count as coldest — they are
    // the ones nobody has looked at since they arrived.
    final candidates = await _store.findEvictable(limit: 500);

    for (final record in candidates) {
      if (toFree <= 0) break;

      // Second guard, in Dart, over the one already applied in SQL. Cheap, and
      // this is the operation where being wrong destroys a user's only copy of
      // something — a redundant check is the correct kind of paranoia.
      if (!record.isEvictable) continue;

      final size = record.sizeBytes ?? 0;
      try {
        if (record.checksum != null) {
          await _files.deleteContent(record.checksum!);
        }
        await _store.upsert(record.copyWith(
          clearLocalPath: true,
          downloadStatus: AttachmentDownloadStatus.absent,
          bytesReceived: 0,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ));
        freed += size;
        toFree -= size;
      } catch (e) {
        // A fallback path logs. A file that cannot be deleted is not fatal —
        // the sweep moves on — but a sweep that silently frees nothing looks
        // exactly like one that had nothing to free.
        LogService.error(
          'Could not evict "${record.attachmentId}" — skipping it.',
          tag: _tag,
          error: e,
        );
      }
    }

    LogService.info(
      'Cache sweep freed ${(freed / 1048576).toStringAsFixed(1)} MB.',
      tag: _tag,
    );
    return freed;
  }

  /// Does the device have room for [requiredBytes] on top of what it holds?
  ///
  /// Answered from the **manifest's declared totals before the first byte is
  /// requested** — the alternative is a download that runs to 80% and then
  /// fails, having spent the bandwidth and the battery to discover something
  /// one number would have told it.
  Future<bool> canAccommodate(int requiredBytes) async {
    final current = await _files.totalBytes();
    if (current + requiredBytes <= budgetBytes) return true;

    // Would it fit after reclaiming everything reclaimable?
    final usageNow = await usage();
    return current - usageNow.evictableBytes + requiredBytes <= budgetBytes;
  }
}
