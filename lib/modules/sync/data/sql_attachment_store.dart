import 'package:sqflite/sqflite.dart';

import '../domain/attachment_record.dart';
import '../domain/attachment_store.dart';
import 'sync_database.dart';

class SqlAttachmentStore implements AttachmentStore {
  const SqlAttachmentStore(this._database);

  final SyncDatabase _database;

  static const _table = 'attachments';

  @override
  Future<void> upsert(AttachmentRecord record) async {
    final db = await _database.database;
    await db.insert(
      _table,
      _toMap(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> upsertAll(List<AttachmentRecord> records) async {
    if (records.isEmpty) return;
    final db = await _database.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final record in records) {
        batch.insert(
          _table,
          _toMap(record),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<AttachmentRecord?> findById(String attachmentId) async {
    final db = await _database.database;
    final rows = await db.query(
      _table,
      where: 'attachment_id = ?',
      whereArgs: [attachmentId],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromMap(rows.first);
  }

  @override
  Future<List<AttachmentRecord>> findForEntity({
    required String entityName,
    required String entityLocalId,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      _table,
      where: 'entity_name = ? AND entity_local_id = ?',
      whereArgs: [entityName, entityLocalId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<List<AttachmentRecord>> findPendingUploads({int limit = 50}) async {
    final db = await _database.database;
    final rows = await db.query(
      _table,
      // **Exactly the states `AttachmentUploadStatus.isOwed` names** — the bytes
      // this device still owes the server.
      //
      // `uploading` was missing, and its absence stranded files permanently.
      // `_uploadOne` writes `uploading` *before* the network call, so a process
      // killed mid-transfer — an OS reclaim, a crash, a flat battery — leaves
      // the row in it. Nothing resets it: there is no equivalent of
      // `SyncLock.releaseIfStale` here. Excluded from this query it was never
      // retried; counted by `isOwed` it was never evictable either. The
      // photograph sat on disk forever, unsent and unreclaimable.
      //
      // No staleness window is needed to tell an abandoned upload from a live
      // one, because the distinction is structural rather than temporal: a
      // cycle holds `SyncLock`, `uploadPending` selects its batch once, and each
      // `_uploadOne` is awaited in turn — so a cycle that ends normally leaves
      // no row in `uploading`. A row seen here in that state is one whose cycle
      // died.
      //
      // Re-sending is safe by the server's own contract: same `attachment_id`
      // and same content returns the stored row (`attachments.service.ts` —
      // "an offline queue cannot tell a request that committed from one that
      // never arrived, so its only correct move is to send again, and the
      // second send must not become a second file"). The idempotency key is
      // derived from the attachment's identity and is stable across attempts.
      //
      // `findEvictable` below and `idx_attachments_pending_upload` both already
      // spell out this same triple; this query was the one place that did not.
      where: "upload_status IN ('pending', 'uploading', 'failed')",
      // Device-origin first: those bytes exist nowhere else. Then oldest, so a
      // long queue drains in the order the work was done.
      orderBy: "CASE origin WHEN 'device' THEN 0 ELSE 1 END, created_at ASC",
      limit: limit,
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<List<AttachmentRecord>> findMissingDownloads({
    int limit = 50,
    bool requiredOnly = false,
  }) async {
    final db = await _database.database;
    final where = StringBuffer(
      "download_status IN ('absent', 'queued', 'failed') AND remote_url IS NOT NULL",
    );
    if (requiredOnly) where.write(' AND is_required = 1');

    final rows = await db.query(
      _table,
      where: where.toString(),
      // Required files first — they are what a bundle waits on before it can
      // call itself ready.
      orderBy: 'is_required DESC, created_at ASC',
      limit: limit,
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<List<AttachmentRecord>> findEvictable({int limit = 100}) async {
    final db = await _database.database;
    final rows = await db.query(
      _table,
      // The three vetoes, expressed as a WHERE clause so the sweep never reads
      // a row it cannot touch:
      //   1. present on disk at all
      //   2. not required
      //   3. not a device file the server has yet to confirm
      where: "download_status = 'downloaded' "
          'AND local_path IS NOT NULL '
          'AND is_required = 0 '
          "AND NOT (origin = 'device' AND upload_status IN ('pending', 'uploading', 'failed'))",
      // Least recently used first. NULL means never read since the column was
      // added, which makes it the coldest thing on the device.
      orderBy: 'last_accessed_at IS NULL DESC, last_accessed_at ASC',
      limit: limit,
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<void> touch(String attachmentId) async {
    final db = await _database.database;
    await db.update(
      _table,
      {'last_accessed_at': DateTime.now().millisecondsSinceEpoch},
      where: 'attachment_id = ?',
      whereArgs: [attachmentId],
    );
  }

  @override
  Future<int> totalStoredBytes() async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      "SELECT COALESCE(SUM(size_bytes), 0) AS total FROM $_table "
      "WHERE download_status = 'downloaded' AND local_path IS NOT NULL",
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  @override
  Future<void> deleteAll() async {
    final db = await _database.database;
    await db.delete(_table);
  }

  Map<String, dynamic> _toMap(AttachmentRecord r) => {
        'attachment_id': r.attachmentId,
        'entity_name': r.entityName,
        'entity_local_id': r.entityLocalId,
        'role': r.role,
        'remote_url': r.remoteUrl,
        'local_path': r.localPath,
        'file_name': r.fileName,
        'mime_type': r.mimeType,
        'size_bytes': r.sizeBytes,
        'checksum': r.checksum,
        'checksum_algo': r.checksumAlgo,
        'bytes_received': r.bytesReceived,
        'download_status': r.downloadStatus.raw,
        'upload_status': r.uploadStatus.raw,
        'origin': r.origin.raw,
        'is_required': r.isRequired ? 1 : 0,
        'last_accessed_at': r.lastAccessedAt,
        'retry_count': r.retryCount,
        'last_error': r.lastError,
        'created_at': r.createdAt,
        'updated_at': r.updatedAt,
      };

  AttachmentRecord _fromMap(Map<String, dynamic> m) => AttachmentRecord(
        attachmentId: m['attachment_id'] as String,
        entityName: m['entity_name'] as String,
        entityLocalId: m['entity_local_id'] as String,
        role: m['role'] as String?,
        remoteUrl: m['remote_url'] as String?,
        localPath: m['local_path'] as String?,
        fileName: m['file_name'] as String,
        mimeType: m['mime_type'] as String?,
        sizeBytes: m['size_bytes'] as int?,
        checksum: m['checksum'] as String?,
        checksumAlgo: m['checksum_algo'] as String?,
        bytesReceived: (m['bytes_received'] as int?) ?? 0,
        downloadStatus:
            AttachmentDownloadStatus.fromRaw(m['download_status'] as String),
        uploadStatus:
            AttachmentUploadStatus.fromRaw(m['upload_status'] as String),
        origin: AttachmentOrigin.fromRaw(m['origin'] as String),
        isRequired: (m['is_required'] as int? ?? 0) == 1,
        lastAccessedAt: m['last_accessed_at'] as int?,
        retryCount: (m['retry_count'] as int?) ?? 0,
        lastError: m['last_error'] as String?,
        createdAt: m['created_at'] as int,
        updatedAt: m['updated_at'] as int,
      );
}
