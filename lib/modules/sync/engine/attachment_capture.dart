import 'dart:io';

import 'package:uuid/uuid.dart';

import 'package:app_template/core/platform/logging/log_service.dart';

import '../data/attachment_file_store.dart';
import '../domain/attachment_record.dart';
import '../domain/attachment_store.dart';

/// Takes a file the device just produced and makes it durable, recorded, and
/// queued for upload — **in that order, and immediately.**
///
/// ## Why capture is its own step
///
/// `image_picker` returns a path in the temporary directory. The OS empties
/// that directory whenever storage runs short, and storage runs short during
/// exactly the long, photo-heavy sessions this module exists for. So between
/// the shutter and the copy there is a window in which the only record of a
/// site nobody will revisit can simply disappear — and the queued job would
/// then point at a path that no longer resolves, which surfaces much later as
/// "upload failed" rather than as "the photo is gone".
///
/// The copy therefore happens **before** the queue row is written, not after:
/// a queue entry that references bytes we have not secured is a promise the
/// device cannot keep.
///
/// ## The bytes are hashed after processing, never before
///
/// If a project compresses or resizes an image, that must happen before this
/// call. A checksum taken from the original describes a file that will never be
/// uploaded, and every later verification compares against a fingerprint of
/// something that no longer exists.
class AttachmentCapture {
  const AttachmentCapture(this._files, this._store, this._uuid);

  final AttachmentFileStore _files;
  final AttachmentStore _store;
  final Uuid _uuid;

  static const _tag = 'SYNC-FILES';

  /// Ingests [source] and records it as owed to the server.
  ///
  /// Returns the stored record, or `null` when the file could not be secured —
  /// which is reported rather than swallowed, because the caller is holding the
  /// only copy and needs to know it did not survive.
  Future<AttachmentRecord?> capture({
    required File source,
    required String entityName,
    required String entityLocalId,
    String? role,
    String? mimeType,
  }) async {
    if (!source.existsSync()) {
      LogService.error(
        'Capture source no longer exists: ${source.path}. If this came from the '
        'camera, the temporary file was reclaimed before it could be copied.',
        tag: _tag,
      );
      return null;
    }

    try {
      // Copy first, hash on the way — the file is durable before anything else
      // in the system learns it exists.
      final ingested = await _files.ingestLocalFile(source);
      final now = DateTime.now().millisecondsSinceEpoch;

      final record = AttachmentRecord(
        attachmentId: _uuid.v4(),
        entityName: entityName,
        entityLocalId: entityLocalId,
        fileName: source.uri.pathSegments.last,
        role: role,
        mimeType: mimeType,
        localPath: ingested.file.path,
        sizeBytes: ingested.file.lengthSync(),
        checksum: ingested.checksum,
        checksumAlgo: 'sha256',
        // Present on disk from the moment it is created — there is nothing to
        // download, and this is what makes it readable offline straight away.
        downloadStatus: AttachmentDownloadStatus.downloaded,
        // And owed to the server from the same moment. This pairing is why the
        // two statuses are separate columns.
        uploadStatus: AttachmentUploadStatus.pending,
        origin: AttachmentOrigin.device,
        lastAccessedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      await _store.upsert(record);

      LogService.info(
        'Captured ${record.fileName} (${record.sizeBytes} bytes) for '
        '$entityName/$entityLocalId — held locally until the server confirms it.',
        tag: _tag,
      );
      return record;
    } catch (e, st) {
      LogService.error(
        'Could not secure a captured file — the caller still holds the only '
        'copy and must be told.',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
