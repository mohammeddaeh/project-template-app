import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:app_template/core/platform/logging/log_service.dart';

import '../data/attachment_file_store.dart';
import '../domain/attachment_record.dart';
import '../domain/attachment_store.dart';

/// Why a file is not on the device.
enum AttachmentUnavailability {
  /// No network, and the bytes are not here. **Not an error** — an optional
  /// file evicted yesterday on a device out of coverage today is a system
  /// working as designed. Rendering it as a failure teaches the user that the
  /// app is broken, and then they stop reporting the failures that are real.
  offline,

  /// The server was reached and the file could not be fetched.
  fetchFailed,

  /// Fetched, and the bytes did not match their checksum.
  corrupt,
}

/// Result of asking for a file.
sealed class AttachmentAccess {
  const AttachmentAccess();
}

final class AttachmentReady extends AttachmentAccess {
  const AttachmentReady(this.file);
  final File file;
}

final class AttachmentUnavailable extends AttachmentAccess {
  const AttachmentUnavailable(this.reason);
  final AttachmentUnavailability reason;
}

/// Fetches attachment bytes — resumably, verifiably, and one at a time per file.
///
/// ## The access path
///
/// ```
/// on disk?         → serve it, and mark it read (LRU)
/// no + online      → download → verify → publish → serve
/// no + offline     → AttachmentUnavailable(offline)
/// ```
///
/// ## Resumption is the difference between usable and not
///
/// A 200 MB document over a field connection will be interrupted. Restarting
/// from zero each time means it never completes — not "completes slowly".
/// `Range` plus a `.part` file means every attempt keeps the ground the last
/// one took.
class AttachmentDownloadManager {
  AttachmentDownloadManager(this._dio, this._store, this._files);

  final Dio _dio;
  final AttachmentStore _store;
  final AttachmentFileStore _files;

  static const _tag = 'SYNC-FILES';

  /// In-flight downloads, keyed by attachment id.
  ///
  /// Two screens showing the same reference image must produce **one** request.
  /// Without this the second call opens a second connection writing to the same
  /// `.part` file — and two appenders on one file produce a length that matches
  /// nothing and a checksum that fails on both.
  final Map<String, Future<AttachmentAccess>> _inFlight = {};

  /// Serves [attachmentId], fetching it if needed and if possible.
  Future<AttachmentAccess> access(
    String attachmentId, {
    required bool isOnline,
  }) async {
    final record = await _store.findById(attachmentId);
    if (record == null) {
      return const AttachmentUnavailable(AttachmentUnavailability.fetchFailed);
    }

    if (record.isAvailableLocally) {
      final file = File(record.localPath!);
      if (file.existsSync()) {
        // LRU: read time, not write time. The cache manager evicts what nobody
        // has opened, and a file downloaded months ago but read this morning is
        // the last thing that should go.
        unawaited(_store.touch(attachmentId));
        return AttachmentReady(file);
      }
      // The row says present and the disk disagrees — the file was removed
      // outside the app. Fall through and re-fetch rather than handing back a
      // path that fails to open somewhere further away from the cause.
      LogService.warning(
        'Attachment "$attachmentId" is recorded as downloaded but its file is '
        'gone. Re-fetching.',
        tag: _tag,
      );
    }

    if (!isOnline) {
      return const AttachmentUnavailable(AttachmentUnavailability.offline);
    }

    return _inFlight.putIfAbsent(
      attachmentId,
      () => _download(record).whenComplete(() => _inFlight.remove(attachmentId)),
    );
  }

  Future<AttachmentAccess> _download(AttachmentRecord record) async {
    final url = record.remoteUrl;
    if (url == null || url.isEmpty) {
      return const AttachmentUnavailable(AttachmentUnavailability.fetchFailed);
    }

    await _store.upsert(record.copyWith(
      downloadStatus: AttachmentDownloadStatus.downloading,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));

    try {
      final alreadyHave = await _files.partialLength(record.attachmentId);

      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(
          // A stream, not bytes: the alternative holds the whole file in memory,
          // which is survivable for a CSV and fatal for a 200 MB document on a
          // 2 GB device.
          responseType: ResponseType.stream,
          headers: alreadyHave > 0 ? {'Range': 'bytes=$alreadyHave-'} : null,
          validateStatus: (s) => s != null && s >= 200 && s < 400,
        ),
      );

      // 200 to a Range request means the server ignored it and is sending the
      // whole file again. Appending would corrupt what we already have.
      if (alreadyHave > 0 && response.statusCode == 200) {
        LogService.info(
          'Server ignored Range for "${record.attachmentId}" — restarting the '
          'partial file rather than appending a second copy onto the first.',
          tag: _tag,
        );
        await _files.discardPartial(record.attachmentId);
      }

      var received = 0;
      await for (final chunk in response.data!.stream) {
        received = await _files.appendToPartial(record.attachmentId, chunk);
      }

      final expected = record.checksum;
      if (expected == null) {
        // Nothing to verify against. Publishing an unverified file would put it
        // on the same footing as a verified one, so this is refused: a server
        // that does not declare checksums has not implemented the contract.
        LogService.error(
          'Attachment "${record.attachmentId}" arrived with no expected '
          'checksum — refusing to publish it. See SETUP.md §6.',
          tag: _tag,
        );
        await _files.discardPartial(record.attachmentId);
        return _fail(record, AttachmentUnavailability.corrupt, 'no checksum');
      }

      final published = await _files.verifyAndPublish(
        attachmentId: record.attachmentId,
        expectedChecksum: expected,
      );

      if (published == null) {
        return _fail(record, AttachmentUnavailability.corrupt, 'checksum mismatch');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await _store.upsert(record.copyWith(
        localPath: published.path,
        sizeBytes: published.lengthSync(),
        bytesReceived: received,
        downloadStatus: AttachmentDownloadStatus.downloaded,
        lastAccessedAt: now,
        retryCount: 0,
        clearLastError: true,
        updatedAt: now,
      ));

      return AttachmentReady(published);
    } catch (e) {
      // The partial file is **kept**: whatever arrived is ground the next
      // attempt does not have to cover again. Only a checksum failure discards
      // it, because those bytes are known to be wrong.
      LogService.warning(
        'Download of "${record.attachmentId}" interrupted — keeping the partial '
        'file so the retry resumes: $e',
        tag: _tag,
      );
      return _fail(record, AttachmentUnavailability.fetchFailed, e.toString());
    }
  }

  Future<AttachmentAccess> _fail(
    AttachmentRecord record,
    AttachmentUnavailability reason,
    String error,
  ) async {
    await _store.upsert(record.copyWith(
      downloadStatus: AttachmentDownloadStatus.failed,
      retryCount: record.retryCount + 1,
      lastError: error,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    return AttachmentUnavailable(reason);
  }
}
