import 'package:dio/dio.dart';

import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

import '../domain/attachment_record.dart';
import '../domain/attachment_store.dart';

/// Learns which files the server holds for an entity — **the step without
/// which the download manager has nothing to download.**
///
/// Rows arrive [AttachmentDownloadStatus.absent]: known to exist, not here yet.
/// That is the state the whole lazy path is built on, and it is also where an
/// evicted file returns to, which is why the two are the same value.
///
/// ## Metadata is cheap; bytes are not
///
/// A hundred attachments is a few kilobytes of JSON and possibly a gigabyte of
/// content. Syncing the list eagerly and the content on demand is what lets a
/// device show "3 photos, tap to load" without having downloaded any of them —
/// and lets it show the same thing offline, truthfully, instead of pretending
/// the entity has no files.
class AttachmentMetadataSync {
  const AttachmentMetadataSync(this._dio, this._store);

  final Dio _dio;
  final AttachmentStore _store;

  static const _tag = 'SYNC-FILES';

  /// Refreshes the attachment list for one entity.
  ///
  /// Returns the number of rows now known locally, or `null` when the server
  /// could not be reached — which is **not** an error: a device offline simply
  /// keeps the list it already had, and the caller shows that.
  Future<int?> refreshForEntity({
    required String entityName,
    required String entityLocalId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '${Env.baseUrl}/attachments',
        queryParameters: {
          'entity_name': entityName,
          'entity_id': entityLocalId,
        },
      );

      final json = response.data as Map<String, dynamic>;
      if (json['status'] != true) return null;

      final rows = (json['data'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();

      final now = DateTime.now().millisecondsSinceEpoch;
      final incoming = <AttachmentRecord>[];

      for (final row in rows) {
        final id = row['id'] as String?;
        if (id == null) continue;

        final existing = await _store.findById(id);

        // A row we already hold locally keeps its download state and its file.
        // Overwriting it with `absent` because the server described it would
        // discard a file that is sitting on disk — and worse, would discard the
        // upload state of a photograph this device captured and has not sent.
        if (existing != null) continue;

        incoming.add(
          AttachmentRecord(
            attachmentId: id,
            entityName: entityName,
            entityLocalId: entityLocalId,
            fileName: row['file_name'] as String? ?? 'file',
            role: row['role'] as String?,
            mimeType: row['mime_type'] as String?,
            sizeBytes: row['size_bytes'] as int?,
            checksum: row['checksum'] as String?,
            checksumAlgo: row['checksum_algo'] as String?,
            remoteUrl: '${Env.baseUrl}/attachments/$id/content',
            // Known to exist; not here. The lazy path starts from this.
            downloadStatus: AttachmentDownloadStatus.absent,
            // Server-owned: there is nothing to upload, ever. Which is exactly
            // what makes it safe for the cache manager to reclaim later.
            uploadStatus: AttachmentUploadStatus.notApplicable,
            origin: AttachmentOrigin.server,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (incoming.isNotEmpty) await _store.upsertAll(incoming);

      final total = rows.length;
      LogService.debug(
        'Attachment metadata for $entityName/$entityLocalId: $total known, '
        '${incoming.length} new.',
        tag: _tag,
      );
      return total;
    } catch (e) {
      // Not an error path. The device keeps whatever list it already has, and
      // the caller renders that — which is the correct behaviour offline and
      // the reason this returns null rather than throwing.
      LogService.debug(
        'Could not refresh attachment metadata for $entityName/$entityLocalId '
        '— keeping the local list: $e',
        tag: _tag,
      );
      return null;
    }
  }
}
