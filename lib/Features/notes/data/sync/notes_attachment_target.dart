import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';

/// Sends a note's files to `POST /api/v1/attachments`.
///
/// ## The whole cost of giving a feature attachments
///
/// One class, and its only feature-specific knowledge is the string `'notes'`.
/// The server side is the same story: `core/attachments/` is mounted once and
/// serves every resource, so a feature adds no route, no controller and no
/// table there either.
///
/// That symmetry is deliberate. Attachments are the same problem in every
/// feature — bytes, an owner, a checksum — and the third implementation of it
/// is where the differences start being accidental rather than meaningful.
@LazySingleton(as: AttachmentUploadTarget)
class NotesAttachmentUploadTarget implements AttachmentUploadTarget {
  const NotesAttachmentUploadTarget(this._dio);

  final Dio _dio;

  @override
  String get entityName => 'notes';

  @override
  Future<String> upload({
    required AttachmentRecord record,
    required File file,
    required String idempotencyKey,
  }) async {
    final response = await _dio.post<dynamic>(
      '${Env.baseUrl}/attachments',
      data: await attachmentFormData(record: record, file: file),
      options: Options(
        // Stable across every retry of this file. The failure it guards against
        // is a request that committed and whose response was lost — which is
        // indistinguishable, from here, from one that never arrived.
        headers: {'Idempotency-Key': idempotencyKey},
      ),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['status'] != true) {
      throw StateError(
        'Attachment upload refused: ${json['message'] ?? 'unknown reason'}',
      );
    }

    final data = json['data'] as Map<String, dynamic>?;
    final serverId = data?['id'] as String?;
    if (serverId == null) {
      // No id means no confirmation, and without confirmation the local copy
      // must stay untouchable. Treated as a failure rather than a quiet success
      // for exactly that reason: the alternative frees bytes the server may not
      // have.
      throw StateError('Attachment upload returned no id — treating as unsent.');
    }
    return serverId;
  }
}
