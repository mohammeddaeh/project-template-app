import 'dart:io';

class PrivateFileIngestResult {
  const PrivateFileIngestResult({required this.file, required this.checksum});

  final File file;
  final String checksum;
}

/// Copies irreplaceable field data from picker-owned temporary storage into
/// durable application-private storage before a form keeps a reference to it.
abstract interface class PrivateFileIngestService {
  Future<PrivateFileIngestResult> ingest(File source);
}
