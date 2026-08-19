import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:app_template/core/platform/logging/log_service.dart';

/// Owns the bytes on disk — **and the only place in the app allowed to decide
/// where an attachment lives.**
///
/// ```
/// <appDocuments>/sync_files/
/// ├── files/<sha[0:2]>/<sha256>     ← verified content, named by its own hash
/// └── tmp/<attachmentId>.part       ← partial, and nothing reads from here
/// ```
///
/// ## Private storage is a privacy requirement, not a convenience
///
/// `getApplicationDocumentsDirectory()` is not visible to the gallery, to a
/// file manager, or to another app. Two consequences follow, and both are
/// deliberate:
///
/// - **Never `getTemporaryDirectory()`.** The OS empties it whenever space runs
///   short — which is exactly when a long field round is running and exactly
///   the file that cannot be re-created. `MediaService.pickFromCamera` writes
///   there today, which is why capture must copy into this store immediately.
/// - **Never `FileService.saveToDownloads()`.** It is the one path in this
///   codebase that reaches the public Downloads folder, and collected data must
///   not land there.
///
/// ## Content addressing
///
/// A verified file is named by its own SHA-256. The same reference image
/// attached to fifty locations is **one file on disk**, and a file's name is a
/// proof of its contents rather than a label someone chose.
class AttachmentFileStore {
  AttachmentFileStore();

  static const _rootDirName = 'sync_files';
  static const _tag = 'SYNC-FILES';

  Directory? _root;

  Future<Directory> _rootDir() async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _rootDirName));
    if (!dir.existsSync()) await dir.create(recursive: true);
    _root = dir;
    return dir;
  }

  /// Where a partial download accumulates.
  ///
  /// Keyed by attachment id, not by checksum: the checksum of a file that has
  /// not finished arriving is not known yet, and naming it after a hash it may
  /// not match is how a corrupt file ends up indistinguishable from a good one.
  Future<File> partialFileFor(String attachmentId) async {
    final root = await _rootDir();
    final tmp = Directory(p.join(root.path, 'tmp'));
    if (!tmp.existsSync()) await tmp.create(recursive: true);
    return File(p.join(tmp.path, '$attachmentId.part'));
  }

  /// The final resting place for content with this [checksum].
  Future<File> contentFileFor(String checksum) async {
    final root = await _rootDir();
    // Two-character shard: some filesystems slow down badly with tens of
    // thousands of entries in a single directory, and a field round produces
    // exactly that.
    final shard = checksum.length >= 2 ? checksum.substring(0, 2) : '00';
    final dir = Directory(p.join(root.path, 'files', shard));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return File(p.join(dir.path, checksum));
  }

  /// Streams [bytes] onto the end of the partial file.
  ///
  /// Append rather than rewrite, because that is what makes an HTTP `Range`
  /// resumption worth requesting at all.
  Future<int> appendToPartial(String attachmentId, List<int> bytes) async {
    final file = await partialFileFor(attachmentId);
    await file.writeAsBytes(bytes, mode: FileMode.append, flush: true);
    return file.lengthSync();
  }

  /// How much of [attachmentId] is already on disk — the `Range` offset.
  Future<int> partialLength(String attachmentId) async {
    final file = await partialFileFor(attachmentId);
    return file.existsSync() ? file.lengthSync() : 0;
  }

  Future<void> discardPartial(String attachmentId) async {
    final file = await partialFileFor(attachmentId);
    if (file.existsSync()) await file.delete();
  }

  /// Hashes the partial file **without loading it into memory**.
  ///
  /// `readAsBytes` on a 200 MB document is 200 MB of RAM on a device that has
  /// little of it; the streaming digest holds one chunk at a time regardless of
  /// size.
  Future<String> checksumOfPartial(String attachmentId) async {
    final file = await partialFileFor(attachmentId);
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  /// Verifies the partial file and, only then, publishes it.
  ///
  /// ## The rename is the entire integrity guarantee
  ///
  /// Until this succeeds, the bytes live under `.part` and **nothing reads
  /// them**. A rename within one filesystem is atomic, so a file either does
  /// not exist or exists complete — there is no observable middle state, not
  /// even if the process dies between the two lines.
  ///
  /// Writing to the final name and verifying afterwards would invert that: a
  /// kill at the wrong moment leaves a truncated PDF under a name that promises
  /// a whole one, and the app renders it and the user believes it. A file that
  /// is missing announces itself; a file that is quietly incomplete does not.
  ///
  /// Returns the published file, or `null` when the content did not match
  /// [expectedChecksum] — in which case the partial is discarded so the retry
  /// starts clean rather than resuming onto corrupt bytes.
  Future<File?> verifyAndPublish({
    required String attachmentId,
    required String expectedChecksum,
  }) async {
    final actual = await checksumOfPartial(attachmentId);
    if (actual != expectedChecksum) {
      LogService.warning(
        'Checksum mismatch for "$attachmentId" — expected $expectedChecksum, '
        'got $actual. Discarding the partial file; the retry starts from zero '
        'rather than resuming onto bytes we already know are wrong.',
        tag: _tag,
      );
      await discardPartial(attachmentId);
      return null;
    }

    final partial = await partialFileFor(attachmentId);
    final target = await contentFileFor(expectedChecksum);

    // Already published by another attachment carrying identical content — the
    // deduplication that content addressing gives for free.
    if (target.existsSync()) {
      await partial.delete();
      return target;
    }

    return partial.rename(target.path);
  }

  /// Ingests a file the device just produced — a photo, a signature, a recording.
  ///
  /// **Called at capture time, before anything is queued.** `image_picker`
  /// hands back a path in the temporary directory, and the OS empties that
  /// whenever storage runs short: precisely during a long, photo-heavy round,
  /// and precisely for the image that cannot be taken again. The queued job
  /// would then point at a file that no longer exists, and the only record of
  /// a location nobody will revisit is gone.
  ///
  /// Returns the published file and its checksum.
  Future<({File file, String checksum})> ingestLocalFile(File source) async {
    final digest = await sha256.bind(source.openRead()).first;
    final checksum = digest.toString();
    final target = await contentFileFor(checksum);

    if (!target.existsSync()) await source.copy(target.path);
    return (file: target, checksum: checksum);
  }

  /// Deletes published content. **Never call this without consulting
  /// `AttachmentRecord.isEvictable` first** — see `ARCHITECTURE.md` §8-د.
  Future<void> deleteContent(String checksum) async {
    final file = await contentFileFor(checksum);
    if (file.existsSync()) await file.delete();
  }

  /// Total bytes held under the store — what the cache manager measures.
  Future<int> totalBytes() async {
    final root = await _rootDir();
    if (!root.existsSync()) return 0;
    var total = 0;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Removes every byte this store owns.
  ///
  /// For account switches: leaving one user's photographs on a device the next
  /// user signs into is a data leak, and filtering by owner is not good enough
  /// when the filter is one forgotten `WHERE` clause away from failing.
  Future<void> deleteAll() async {
    final root = await _rootDir();
    if (root.existsSync()) await root.delete(recursive: true);
    _root = null;
  }
}
