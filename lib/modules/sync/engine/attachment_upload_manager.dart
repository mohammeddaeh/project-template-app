import 'dart:io';

import 'package:dio/dio.dart';

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/errors/failure_mapper_registry.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

import '../domain/attachment_record.dart';
import '../domain/attachment_store.dart';

/// Where a feature's attachment uploads go.
///
/// Declared per entity, like [SyncExecutor], because the url and the field
/// names are the feature's business and the retry, ordering and confirmation
/// rules are the module's.
abstract class AttachmentUploadTarget {
  String get entityName;

  /// Where the server serves an uploaded attachment's bytes from.
  ///
  /// Declared beside [upload] because only the feature knows its own base url,
  /// and derived from the id so the shape matches what `AttachmentMetadataSync`
  /// records for server-owned rows — one form of the url, not two that could
  /// drift.
  String contentUrlFor(String attachmentId);

  /// Sends [file] and returns the server's identifier for it.
  ///
  /// Returning an id **is** the confirmation: a client cannot distinguish a
  /// response that never arrived from a write that never happened, so nothing
  /// short of the server naming the object counts as uploaded.
  Future<String> upload({
    required AttachmentRecord record,
    required File file,
    required String idempotencyKey,
  });
}

/// Sends the files the device owes the server — **irreplaceable ones first.**
class AttachmentUploadManager {
  AttachmentUploadManager(this._store, this._targets);

  final AttachmentStore _store;
  final List<AttachmentUploadTarget> _targets;

  static const _tag = 'SYNC-FILES';

  /// Drains pending uploads.
  ///
  /// The ordering comes from the query — device-origin first — and it only ever
  /// matters when bandwidth is scarce, which is the only time it matters at
  /// all: a server file that fails can be fetched again from where it came, and
  /// a photograph taken in the field cannot be fetched from anywhere.
  /// Attempts a file gets before it is left alone.
  ///
  /// Five, because that is what the rest of the module already means by "enough
  /// tries": `sync_queue.max_retries` defaults to 5, `SyncQueueJob.maxRetries`
  /// defaults to 5, and `download_queue.max_retries` — the attachments' own
  /// sibling table — defaults to 5. The number is not chosen here, only named.
  ///
  /// The row is **kept** at the ceiling, never deleted: it holds the payload
  /// path and the last error, which is what makes a dead upload diagnosable.
  static const int maxUploadAttempts = 5;

  Future<int> uploadPending({int batchSize = 10}) async {
    final pending = await _store.findPendingUploads(
      limit: batchSize,
      maxRetries: maxUploadAttempts,
    );
    if (pending.isEmpty) return 0;

    var uploaded = 0;
    for (final record in pending) {
      if (await _uploadOne(record)) uploaded++;
    }
    return uploaded;
  }

  Future<bool> _uploadOne(AttachmentRecord record) async {
    final target = _targetFor(record.entityName);
    if (target == null) {
      LogService.error(
        'No upload target registered for "${record.entityName}" — '
        '${record.attachmentId} cannot be sent by anything.',
        tag: _tag,
      );
      return false;
    }

    final path = record.localPath;
    if (path == null || !File(path).existsSync()) {
      // The bytes are gone before they were ever sent. For a device-origin file
      // this is **permanent data loss**, and it is the one failure in this
      // module that no retry, no reconnection and no server can undo — so it is
      // reported as an error rather than counted as a failed attempt.
      //
      // It is also retired immediately rather than retried: a file that is not
      // on disk will not be on disk next cycle either. Left retryable, this
      // branch re-selected the row every cycle and emitted the IRRECOVERABLE
      // error below forever, for a condition that can never change.
      if (record.origin == AttachmentOrigin.device) {
        LogService.error(
          'IRRECOVERABLE: device file "${record.fileName}" '
          '(${record.attachmentId}) is missing from disk and was never '
          'uploaded. It existed only here.',
          tag: _tag,
        );
      }
      await _store.upsert(record.copyWith(
        uploadStatus: AttachmentUploadStatus.failed,
        retryCount: maxUploadAttempts,
        lastError: 'local file missing',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      return false;
    }

    await _store.upsert(record.copyWith(
      uploadStatus: AttachmentUploadStatus.uploading,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));

    try {
      final serverId = await target.upload(
        record: record,
        file: File(path),
        // Derived from the attachment's own identity and stable across every
        // attempt. A key regenerated per try protects nothing: the failure it
        // exists to prevent is a request that committed and whose response was
        // lost, and that one looks exactly like a request that never landed.
        idempotencyKey: 'attachment_${record.attachmentId}',
      );

      await _store.upsert(record.copyWith(
        // Only now. "Sent" is not "stored", and treating it as such is what
        // makes it safe to free the local copy — which it is not.
        uploadStatus: AttachmentUploadStatus.uploaded,
        // **Recorded at the moment the file stops existing only here.**
        //
        // A device-captured row is born with no url, and confirming the upload
        // is exactly when one becomes true. Without it the row was confirmed
        // (so the cache manager may reclaim it) and unfetchable (so
        // `AttachmentDownloadManager.access` answers `fetchFailed`) — the two
        // states that must never be reachable together.
        remoteUrl: record.remoteUrl ?? target.contentUrlFor(serverId),
        retryCount: 0,
        clearLastError: true,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));

      LogService.info(
        'Uploaded ${record.fileName} → $serverId. The local copy stays until '
        'the cache manager decides otherwise.',
        tag: _tag,
      );
      return true;
    } catch (e) {
      // **Not every failure deserves another attempt**, and the template
      // already knows which is which: `FailureMapperRegistry` is the one place
      // that turns a transport error into a typed `Failure`. Reusing it keeps
      // this manager free of any knowledge of Dio and keeps the classification
      // identical to the push path's.
      //
      // A refusal the server will repeat — a 422 whose checksum will not match
      // any better next time, a 409 reusing an id for different content, a 403 —
      // is retired at once. Retrying it costs a full multipart upload per cycle
      // and can never succeed. Transient trouble (timeout, 5xx, a dropped
      // connection, a 401 the refresh layer may yet fix) keeps its attempts.
      final failure = FailureMapperRegistry.map(e, source: 'attachment_upload');
      final permanent = _isPermanent(failure);
      final attempts =
          permanent ? maxUploadAttempts : record.retryCount + 1;

      await _store.upsert(record.copyWith(
        uploadStatus: AttachmentUploadStatus.failed,
        retryCount: attempts,
        lastError: e.toString(),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      LogService.warning(
        'Upload of ${record.attachmentId} failed (attempt '
        '$attempts/$maxUploadAttempts, ${permanent ? 'permanent' : 'transient'}) '
        '— the file is untouched: $e',
        tag: _tag,
      );
      return false;
    }
  }

  /// Whether the server has told us something that will still be true next
  /// cycle.
  ///
  /// Deliberately a short allow-list rather than "anything 4xx": the classes
  /// named here are the ones whose cause lives in the request itself — a
  /// checksum that will not match, an id already holding other content, a
  /// permission that will not appear. `UnauthorizedFailure` is **excluded** on
  /// purpose: a 401 is what the token-refresh layer exists to repair, and
  /// retiring an irreplaceable photograph because a token expired mid-round
  /// would be the module causing the loss it exists to prevent.
  bool _isPermanent(Failure failure) =>
      failure is ValidationFailure ||
      failure is ConflictFailure ||
      failure is ForbiddenFailure ||
      (failure is BusinessFailure &&
          failure.statusCode >= 400 &&
          failure.statusCode < 500);

  AttachmentUploadTarget? _targetFor(String entityName) {
    for (final target in _targets) {
      if (target.entityName == entityName) return target;
    }
    return null;
  }
}

/// Builds the multipart body for an attachment upload.
///
/// Shared so every feature sends the same shape — a field name that differs by
/// one character between two features is a 422 nobody can read.
///
/// ## The pair `entity_name` + `entity_id` is what addresses the owner
///
/// `entity_name` was missing here, and its absence was invisible from this
/// side: `uploadAttachmentBodySchema` requires it
/// (`backend_template/src/core/attachments/attachments.dto.ts`), and
/// `validate(uploadAttachmentBodySchema, 'body')` runs on the route before the
/// controller — so **every** upload was refused with 422 before a byte was
/// stored. Nothing here could see it. `dart analyze` cannot type-check a map
/// key against a zod schema in another repository, and the failure surfaced
/// only as an attachment that stayed `failed` and was retried forever.
///
/// This is the wire-contract rule in `CLAUDE.md` §⛓️ in its exact shape: a key
/// is a contract with `backend_template`, and the two halves have to move
/// together.
Future<FormData> attachmentFormData({
  required AttachmentRecord record,
  required File file,
  String fileField = 'file',
}) async {
  return FormData.fromMap({
    fileField: await MultipartFile.fromFile(
      file.path,
      filename: record.fileName,
    ),
    'attachment_id': record.attachmentId,
    'entity_name': record.entityName,
    'entity_id': record.entityLocalId,
    if (record.role != null) 'role': record.role,
    // Sent so the **server** can verify what it received, rather than trusting
    // that a stream that ended is a stream that arrived intact.
    if (record.checksum != null) 'checksum': record.checksum,
    if (record.checksumAlgo != null) 'checksum_algo': record.checksumAlgo,
  });
}
