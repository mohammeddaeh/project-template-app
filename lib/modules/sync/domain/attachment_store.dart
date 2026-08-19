import 'attachment_record.dart';

/// Row access for attachments. No policy — the cache manager and the download
/// manager decide, this only reads and writes.
abstract class AttachmentStore {
  Future<void> upsert(AttachmentRecord record);
  Future<void> upsertAll(List<AttachmentRecord> records);

  Future<AttachmentRecord?> findById(String attachmentId);

  /// Every attachment of one row — how a screen asks for its own files.
  Future<List<AttachmentRecord>> findForEntity({
    required String entityName,
    required String entityLocalId,
  });

  /// Files the device still owes the server, **device-origin first**.
  ///
  /// The ordering is not cosmetic. A server file that fails to upload can be
  /// re-fetched from where it came; a photograph taken in the field and not yet
  /// sent exists nowhere else. When bandwidth is scarce — which is the only
  /// time this ordering matters — the irreplaceable bytes go first.
  /// [maxRetries] retires a row rather than deleting it: at or above the
  /// ceiling it stops being offered for execution but keeps its payload path
  /// and last error, which is what makes a dead upload diagnosable.
  Future<List<AttachmentRecord>> findPendingUploads({
    int limit = 50,
    int maxRetries = 5,
  });

  /// Files that should be on disk and are not.
  Future<List<AttachmentRecord>> findMissingDownloads({
    int limit = 50,
    bool requiredOnly = false,
  });

  /// Candidates for eviction, least recently used first.
  ///
  /// Excludes everything [AttachmentRecord.isEvictable] refuses, **in SQL
  /// rather than in Dart**: a sweep that filtered after reading would load
  /// every row on a device holding tens of thousands, and the one time it
  /// matters is when the device is already under pressure.
  Future<List<AttachmentRecord>> findEvictable({int limit = 100});

  /// Records that a file was read — the LRU signal.
  Future<void> touch(String attachmentId);

  /// Total bytes of everything recorded as present on disk.
  Future<int> totalStoredBytes();

  /// Wipes every row. For account switches, alongside
  /// `AttachmentFileStore.deleteAll()` — the two must always be called
  /// together, or the device is left with orphaned bytes or dangling rows.
  Future<void> deleteAll();
}
