import 'dart:io';

import 'package:app_template/core/platform/files/private_file_ingest_service.dart';
import 'package:app_template/modules/sync/data/attachment_file_store.dart';

class SyncPrivateFileIngestService implements PrivateFileIngestService {
  const SyncPrivateFileIngestService(this._store);

  final AttachmentFileStore _store;

  @override
  Future<PrivateFileIngestResult> ingest(File source) async {
    final stored = await _store.ingestLocalFile(source);
    return PrivateFileIngestResult(
      file: stored.file,
      checksum: stored.checksum,
    );
  }
}
