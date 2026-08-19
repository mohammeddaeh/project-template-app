/// Where a file came from — **and the single most consequential column in the
/// attachments table.**
///
/// Everything a device downloaded can be downloaded again. A photo the device
/// captured and has not uploaded exists **nowhere else in the world**.
///
/// Without this distinction, "the file is missing, re-fetch it" and "the file
/// is missing, it is gone forever" are the same line of code — and the cache
/// manager, whose entire job is deleting files, cannot tell which one it is
/// about to do.
enum AttachmentOrigin {
  /// Came from the server. Evictable, and re-downloadable on demand.
  server,

  /// Created on this device. **Irreplaceable until uploaded.**
  device;

  static AttachmentOrigin fromRaw(String raw) =>
      raw == 'device' ? AttachmentOrigin.device : AttachmentOrigin.server;

  String get raw => name;
}

/// Whether the bytes are on this device.
///
/// Separate from [AttachmentUploadStatus] on purpose: a captured photo has an
/// upload state and no download state, a reference PDF has the reverse, and
/// collapsing them onto one axis makes "is this file readable right now?"
/// unanswerable without also knowing where it came from.
enum AttachmentDownloadStatus {
  /// Known to exist on the server; not on this device.
  ///
  /// Also the state an **evicted** file returns to — which is why eviction
  /// empties `local_path` rather than deleting the row. The row is what knows
  /// how to fetch the bytes back.
  absent,

  queued,
  downloading,

  /// On disk **and checksum-verified**. Nothing reaches this state unverified:
  /// a partially written file that reports success is worse than a missing one,
  /// because the app renders it and the user believes it.
  downloaded,

  /// Retries exhausted. Distinct from [absent] so a screen can say "could not
  /// be fetched" rather than silently trying forever.
  failed;

  static AttachmentDownloadStatus fromRaw(String raw) =>
      AttachmentDownloadStatus.values.firstWhere(
        (v) => v.name == raw,
        orElse: () => AttachmentDownloadStatus.absent,
      );

  String get raw => name;

  bool get isLocallyAvailable => this == AttachmentDownloadStatus.downloaded;
}

/// Whether the server has the bytes.
enum AttachmentUploadStatus {
  /// A server-owned file. There is nothing to upload, ever.
  notApplicable,

  pending,
  uploading,

  /// **Confirmed by the server**, not merely sent. The distinction is what
  /// makes it safe to free the local copy: a response that never arrived and a
  /// write that never happened look identical from here.
  uploaded,

  failed;

  static AttachmentUploadStatus fromRaw(String raw) =>
      AttachmentUploadStatus.values.firstWhere(
        (v) => v.name == raw,
        orElse: () => AttachmentUploadStatus.notApplicable,
      );

  String get raw => name;

  /// True while the device still owes these bytes to the server — the condition
  /// that makes a file untouchable by the cache manager.
  bool get isOwed =>
      this == AttachmentUploadStatus.pending ||
      this == AttachmentUploadStatus.uploading ||
      this == AttachmentUploadStatus.failed;
}

/// One file belonging to one entity.
///
/// The bytes are **never** here — they live in the app's private documents
/// directory and this row records where, how big, and how to prove they are
/// intact. See `ARCHITECTURE.md` §5 for why a BLOB column would be a mistake at
/// every size that matters.
class AttachmentRecord {
  const AttachmentRecord({
    required this.attachmentId,
    required this.entityName,
    required this.entityLocalId,
    required this.fileName,
    required this.origin,
    required this.downloadStatus,
    required this.uploadStatus,
    required this.createdAt,
    required this.updatedAt,
    this.role,
    this.remoteUrl,
    this.localPath,
    this.mimeType,
    this.sizeBytes,
    this.checksum,
    this.checksumAlgo,
    this.bytesReceived = 0,
    this.isRequired = false,
    this.lastAccessedAt,
    this.retryCount = 0,
    this.lastError,
  });

  final String attachmentId;

  /// Matches `synced_entities(entity_name, local_id)` rather than inventing a
  /// second way to name a row — two conventions for one reference drift.
  final String entityName;
  final String entityLocalId;

  final String fileName;
  final String? role;
  final String? remoteUrl;

  /// Absolute path on this device, or `null` when the bytes are not here —
  /// never downloaded, or evicted to reclaim space.
  final String? localPath;

  final String? mimeType;
  final int? sizeBytes;

  final String? checksum;

  /// Stored **beside** the checksum, because an algorithm upgrade two years
  /// from now turns every stored value into a string nobody can interpret —
  /// with no way to tell "different content" from "different function".
  final String? checksumAlgo;

  /// Bytes already on disk in the `.part` file, for `Range` resumption.
  final int bytesReceived;

  final AttachmentOrigin origin;
  final AttachmentDownloadStatus downloadStatus;
  final AttachmentUploadStatus uploadStatus;

  /// Guaranteed present before a bundle may be declared ready.
  ///
  /// This flag carries the whole tiering strategy: required files are fetched
  /// up front, optional ones on demand. Without it a project either downloads
  /// every gigabyte it might need, or leaves a field worker standing in front
  /// of a form they cannot open.
  final bool isRequired;

  /// Drives LRU eviction. Updated on read, not on write.
  final int? lastAccessedAt;

  final int retryCount;
  final String? lastError;
  final int createdAt;
  final int updatedAt;

  /// True when the bytes can be read right now.
  bool get isAvailableLocally =>
      downloadStatus.isLocallyAvailable && localPath != null;

  /// **The cache manager's veto.**
  ///
  /// Three conditions, and each one alone is enough. The first is the one that
  /// loses data permanently; the other two lose a field round.
  bool get isEvictable {
    if (origin == AttachmentOrigin.device && uploadStatus.isOwed) return false;
    if (isRequired) return false;
    return downloadStatus.isLocallyAvailable;
  }

  AttachmentRecord copyWith({
    String? localPath,
    bool clearLocalPath = false,
    String? checksum,
    String? checksumAlgo,
    int? sizeBytes,
    int? bytesReceived,
    AttachmentDownloadStatus? downloadStatus,
    AttachmentUploadStatus? uploadStatus,
    int? lastAccessedAt,
    int? retryCount,
    String? lastError,
    bool clearLastError = false,
    int? updatedAt,
  }) {
    return AttachmentRecord(
      attachmentId: attachmentId,
      entityName: entityName,
      entityLocalId: entityLocalId,
      fileName: fileName,
      role: role,
      remoteUrl: remoteUrl,
      // An explicit flag, because `null` already means "leave it alone" in
      // copyWith — and eviction's whole job is to set this back to null.
      localPath: clearLocalPath ? null : (localPath ?? this.localPath),
      mimeType: mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksum: checksum ?? this.checksum,
      checksumAlgo: checksumAlgo ?? this.checksumAlgo,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      origin: origin,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      isRequired: isRequired,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
