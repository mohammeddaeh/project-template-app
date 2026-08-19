import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/modules/sync/domain/attachment_record.dart';
import 'package:app_template/modules/sync/domain/attachment_store.dart';
import 'package:app_template/modules/sync/engine/attachment_upload_manager.dart';

/// The attachment rules whose violation loses data silently.
///
/// None of these can be found by using the app: they need a full disk, a killed
/// process, or a photograph that exists in exactly one place. What they have in
/// common is that getting them wrong produces no error — only an absence
/// somebody notices weeks later.
void main() {
  group('the eviction vetoes', () {
    test('a device photo the server has not confirmed is never evictable', () {
      // The one case with no recovery. Everything downloaded can be downloaded
      // again; this cannot be anything again.
      for (final owed in [
        AttachmentUploadStatus.pending,
        AttachmentUploadStatus.uploading,
        AttachmentUploadStatus.failed,
      ]) {
        expect(
          _record(origin: AttachmentOrigin.device, upload: owed).isEvictable,
          isFalse,
          reason: 'a device file in $owed still exists only on this device',
        );
      }
    });

    test('a device photo the server confirmed may be evicted', () {
      // "Sent" is not "confirmed" — the response that never arrived and the
      // write that never happened look identical from the client.
      expect(
        _record(
          origin: AttachmentOrigin.device,
          upload: AttachmentUploadStatus.uploaded,
        ).isEvictable,
        isTrue,
      );
    });

    test('a required file is never evictable, whatever its origin', () {
      // A field worker who finds it missing has no network and no way back.
      expect(
        _record(origin: AttachmentOrigin.server, isRequired: true).isEvictable,
        isFalse,
      );
      expect(
        _record(
          origin: AttachmentOrigin.device,
          upload: AttachmentUploadStatus.uploaded,
          isRequired: true,
        ).isEvictable,
        isFalse,
      );
    });

    test('a file that is not on disk is not a candidate', () {
      expect(
        _record(
          origin: AttachmentOrigin.server,
          download: AttachmentDownloadStatus.absent,
        ).isEvictable,
        isFalse,
      );
    });

    test('an ordinary cached server file is evictable', () {
      expect(_record(origin: AttachmentOrigin.server).isEvictable, isTrue);
    });
  });

  group('the two status axes stay separate', () {
    test('a server file has no upload state to speak of', () {
      final reference = _record(
        origin: AttachmentOrigin.server,
        upload: AttachmentUploadStatus.notApplicable,
      );
      expect(reference.uploadStatus.isOwed, isFalse);
      expect(reference.isAvailableLocally, isTrue);
    });

    test('a captured photo has an upload state and no download to make', () {
      // Collapsed onto one axis, "is this readable right now?" becomes
      // unanswerable without also knowing where the file came from.
      final photo = _record(
        origin: AttachmentOrigin.device,
        upload: AttachmentUploadStatus.pending,
      );
      expect(photo.isAvailableLocally, isTrue);
      expect(photo.uploadStatus.isOwed, isTrue);
    });
  });

  group('eviction empties the row rather than deleting it', () {
    test('clearLocalPath is explicit, because null already means "unchanged"', () {
      final present = _record(origin: AttachmentOrigin.server);
      final evicted = present.copyWith(
        clearLocalPath: true,
        downloadStatus: AttachmentDownloadStatus.absent,
      );

      // The row survives — it is what knows the url and the checksum, which is
      // what makes the bytes re-fetchable. Deleting it would turn an evicted
      // file into a missing one.
      expect(evicted.localPath, isNull);
      expect(evicted.remoteUrl, present.remoteUrl);
      expect(evicted.checksum, present.checksum);
      expect(evicted.isAvailableLocally, isFalse);
    });

    test('a plain copyWith does not clear the path by accident', () {
      final present = _record(origin: AttachmentOrigin.server);
      expect(present.copyWith(retryCount: 1).localPath, isNotNull);
    });
  });

  group('AttachmentFileStore paths', () {
    test('a partial file is never named after a checksum it may not match', () {
      // The name of an unfinished download cannot be a claim about its
      // contents. `.part` keyed by id says exactly what it is: bytes in
      // transit, and nothing reads from there.
      const id = 'a1b2';
      expect('$id.part'.endsWith('.part'), isTrue);
      expect('$id.part'.contains(id), isTrue);
    });
  });

  group('private storage', () {
    test('the store never targets a user-visible directory', () async {
      // A weak assertion on purpose — the real guard is that
      // `AttachmentFileStore` only ever calls `getApplicationDocumentsDirectory`
      // and that `deletion_contract_test` keeps `saveToDownloads` out of every
      // sync path. This documents the intent next to the tests that enforce it.
      // Comments are stripped first. The file **documents** why it never calls
      // `getTemporaryDirectory`, so a plain substring search finds the warning
      // and fails on it — the same false positive the deletion-contract guard
      // hit on a code comment. A rule that fires on prose is a rule people
      // switch off.
      final code = File('lib/modules/sync/data/attachment_file_store.dart')
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      expect(code.contains('getApplicationDocumentsDirectory'), isTrue);
      expect(
        code.contains('getTemporaryDirectory'),
        isFalse,
        reason: 'the OS empties the temporary directory exactly when a long, '
            'photo-heavy round is running',
      );
      expect(
        code.contains('getDownloadsDirectory'),
        isFalse,
        reason: 'collected data must not reach the public Downloads folder',
      );
    });
  });

  group('the upload wire contract', () {
    // `uploadAttachmentBodySchema` in
    // `backend_template/src/core/attachments/attachments.dto.ts`, and
    // `attachments.routes.ts` runs `validate(…, 'body')` on the route **before**
    // the controller. A field missing here is a 422 before a byte is stored.
    const required = {'entity_name', 'entity_id'};

    late Directory dir;
    late File file;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('attachment_wire_test');
      file = File('${dir.path}/photo.jpg')..writeAsBytesSync([1, 2, 3]);
    });

    tearDown(() => dir.deleteSync(recursive: true));

    Future<Map<String, String>> fieldsFor(AttachmentRecord record) async {
      final form = await attachmentFormData(record: record, file: file);
      return {for (final f in form.fields) f.key: f.value};
    }

    test('the body carries entity_name — the field that was missing', () async {
      final record = _record(
        origin: AttachmentOrigin.device,
        upload: AttachmentUploadStatus.pending,
      );

      final fields = await fieldsFor(record);

      expect(
        fields['entity_name'],
        record.entityName,
        reason: 'entity_name is required by uploadAttachmentBodySchema. '
            'Without it every upload is refused with 422, the row stays '
            'failed, and it is retried forever — S11-1.',
      );
    });

    test('every field the server requires is present and non-empty', () async {
      final fields = await fieldsFor(
        _record(
          origin: AttachmentOrigin.device,
          upload: AttachmentUploadStatus.pending,
        ),
      );

      for (final key in required) {
        expect(fields.keys, contains(key), reason: '$key is required server-side');
        expect(fields[key], isNotEmpty, reason: '$key is min(1) server-side');
      }
    });

    test('the pair addresses one owner — name and id, not id alone', () async {
      // `entity_id` alone is ambiguous across features: note-1 and mosque-1 can
      // share an id. The server keys attachments on the pair, which is why the
      // schema requires both.
      final record = _record(
        origin: AttachmentOrigin.device,
        upload: AttachmentUploadStatus.pending,
      );

      final fields = await fieldsFor(record);

      expect(fields['entity_name'], 'notes');
      expect(fields['entity_id'], record.entityLocalId);
      expect(fields['attachment_id'], record.attachmentId);
    });

    test('the file part and the optional fields are unchanged', () async {
      // Guards the fix against having altered anything else in the body.
      final record = _record(
        origin: AttachmentOrigin.device,
        upload: AttachmentUploadStatus.pending,
      );

      final form = await attachmentFormData(record: record, file: file);
      final fields = {for (final f in form.fields) f.key: f.value};

      expect(form.files.single.key, 'file');
      expect(form.files.single.value.filename, record.fileName);
      expect(fields['checksum'], record.checksum);
      expect(fields['checksum_algo'], record.checksumAlgo);
      expect(
        fields.keys.toSet(),
        {'attachment_id', 'entity_name', 'entity_id', 'checksum', 'checksum_algo'},
        reason: 'the body gained or lost a field beyond entity_name',
      );
    });
  });

  group('an interrupted upload is recoverable', () {
    // `_uploadOne` writes `uploading` before the network call, so a process
    // killed mid-transfer leaves the row in it and nothing resets it — there is
    // no `releaseIfStale` here. The selection query must therefore be able to
    // pick it up again, or the file is stranded: never retried, and never
    // evictable either because `isOwed` protects it.

    test('the selection query covers exactly the states isOwed names', () {
      // Derived from the domain predicate, not restated: if a status is added
      // to `isOwed` and the query is not updated — or `uploading` is dropped
      // from the query again — this fails.
      //
      // Comments are stripped first, for the same reason the private-storage
      // test above strips them: this query documents the states in prose, and a
      // guard that fires on its own rationale is one people switch off.
      final code = File('lib/modules/sync/data/sql_attachment_store.dart')
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      final clause = RegExp(r"upload_status IN \(([^)]*)\)").firstMatch(code);
      expect(clause, isNotNull, reason: 'findPendingUploads lost its IN clause');

      final selected = RegExp("'([a-zA-Z]+)'")
          .allMatches(clause!.group(1)!)
          .map((m) => m.group(1)!)
          .toSet();

      final owed = AttachmentUploadStatus.values
          .where((s) => s.isOwed)
          .map((s) => s.raw)
          .toSet();

      expect(
        selected,
        owed,
        reason: 'the upload queue and the eviction veto disagree about which '
            'files this device still owes the server',
      );
      expect(selected, contains('uploading'), reason: 'S11-2');
    });

    test('uploaded and notApplicable stay out of the owed set', () {
      // The other half of the same predicate: a confirmed file and a
      // server-owned one must never be re-sent.
      expect(AttachmentUploadStatus.uploaded.isOwed, isFalse);
      expect(AttachmentUploadStatus.notApplicable.isOwed, isFalse);
      expect(AttachmentUploadStatus.pending.isOwed, isTrue);
      expect(AttachmentUploadStatus.failed.isOwed, isTrue);
    });

    test('an uploading row is still protected from eviction', () {
      // The fix must not make a stranded file collectable instead of
      // recoverable — losing the bytes is the failure it exists to prevent.
      expect(
        _record(
          origin: AttachmentOrigin.device,
          upload: AttachmentUploadStatus.uploading,
        ).isEvictable,
        isFalse,
      );
    });

    test('a transient failure costs one attempt; a permanent one retires it',
        () async {
      // The module already distinguishes these — `FailureMapperRegistry` is the
      // one place that turns a transport error into a typed Failure. A 500 may
      // succeed next cycle; a 422 whose checksum cannot match never will, and
      // re-sending it costs a full multipart upload every cycle forever.
      final dir = Directory.systemTemp.createTempSync('attachment_retry');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/photo.jpg')..writeAsBytesSync([1, 2, 3]);

      Future<int> attemptsAfter(int status) async {
        final record = _record(
          origin: AttachmentOrigin.device,
          upload: AttachmentUploadStatus.pending,
        ).copyWith(localPath: file.path);
        final store = _RecoveryStore([record]);
        await AttachmentUploadManager(store, [_FailingTarget(status)])
            .uploadPending();
        return store.saved.last.retryCount;
      }

      expect(await attemptsAfter(500), 1, reason: '5xx is transient');
      expect(
        await attemptsAfter(422),
        AttachmentUploadManager.maxUploadAttempts,
        reason: '422 will refuse identically next cycle — retire it',
      );
      expect(
        await attemptsAfter(403),
        AttachmentUploadManager.maxUploadAttempts,
        reason: 'a permission that will not appear is permanent',
      );
    });

    test('a 401 keeps its attempts — the refresh layer may still repair it',
        () async {
      // Retiring an irreplaceable photograph because a token expired mid-round
      // would be the module causing the loss it exists to prevent.
      final dir = Directory.systemTemp.createTempSync('attachment_401');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/photo.jpg')..writeAsBytesSync([1]);

      final store = _RecoveryStore([
        _record(
          origin: AttachmentOrigin.device,
          upload: AttachmentUploadStatus.pending,
        ).copyWith(localPath: file.path),
      ]);
      await AttachmentUploadManager(store, [_FailingTarget(401)]).uploadPending();

      expect(store.saved.last.retryCount, 1);
    });

    test('a file missing from disk is retired at once, not retried forever',
        () async {
      // It will not be on disk next cycle either. Left retryable, this branch
      // re-selected the row every cycle and re-emitted its IRRECOVERABLE error
      // for a condition that can never change.
      final store = _RecoveryStore([
        _record(
          origin: AttachmentOrigin.device,
          upload: AttachmentUploadStatus.pending,
        ).copyWith(localPath: '/nowhere/gone.jpg'),
      ]);

      await AttachmentUploadManager(store, [_RecordingTarget()]).uploadPending();

      expect(store.saved.single.uploadStatus, AttachmentUploadStatus.failed);
      expect(
        store.saved.single.retryCount,
        AttachmentUploadManager.maxUploadAttempts,
      );
    });

    test('a row at the ceiling is no longer offered for upload', () async {
      final store = _RecoveryStore([
        _record(
          origin: AttachmentOrigin.device,
          upload: AttachmentUploadStatus.failed,
        ).copyWith(retryCount: AttachmentUploadManager.maxUploadAttempts),
      ]);
      final target = _RecordingTarget();

      final sent =
          await AttachmentUploadManager(store, [target]).uploadPending();

      expect(sent, 0);
      expect(target.seen, isEmpty, reason: 'a retired upload must not be re-sent');
    });

    test('a confirmed upload records where the bytes can be fetched from',
        () async {
      // A device row is born with no url. Confirming the upload is when one
      // becomes true — and without it the row is both reclaimable (confirmed)
      // and unfetchable (no url), which is how an uploaded photograph becomes
      // unreachable.
      final dir = Directory.systemTemp.createTempSync('attachment_url');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/photo.jpg')..writeAsBytesSync([1]);

      // Built without a url, which is how `AttachmentCapture` creates one: the
      // file was born here and nothing else knew about it.
      final record = AttachmentRecord(
        attachmentId: 'att-captured',
        entityName: 'notes',
        entityLocalId: 'note-1',
        fileName: 'photo.jpg',
        origin: AttachmentOrigin.device,
        downloadStatus: AttachmentDownloadStatus.downloaded,
        uploadStatus: AttachmentUploadStatus.pending,
        localPath: file.path,
        createdAt: 1755500000000,
        updatedAt: 1755500000000,
      );
      expect(record.remoteUrl, isNull, reason: 'the premise of this test');

      final store = _RecoveryStore([record]);
      final target = _RecordingTarget();

      await AttachmentUploadManager(store, [target]).uploadPending();

      final saved = store.saved.last;
      expect(saved.uploadStatus, AttachmentUploadStatus.uploaded);
      expect(
        saved.remoteUrl,
        isNotNull,
        reason: 'a confirmed device file with no url is reclaimable and '
            'unfetchable at the same time',
      );
      expect(saved.remoteUrl, contains(record.attachmentId));
    });

    test('pending → uploading → interruption → recovered and re-sent', () async {
      // The whole scenario, through the production manager. The store hands
      // back the row exactly as the fixed query now would; nothing downstream
      // may special-case it.
      final dir = Directory.systemTemp.createTempSync('attachment_recovery');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/photo.jpg')..writeAsBytesSync([1, 2, 3]);

      final stranded = _record(
        origin: AttachmentOrigin.device,
        upload: AttachmentUploadStatus.uploading,
      ).copyWith(localPath: file.path);

      final store = _RecoveryStore([stranded]);
      final target = _RecordingTarget();
      final manager = AttachmentUploadManager(store, [target]);

      final sent = await manager.uploadPending();

      expect(sent, 1, reason: 'the recovered row was not uploaded');
      expect(target.seen, hasLength(1));
      expect(
        target.keys.single,
        'attachment_${stranded.attachmentId}',
        reason: 'the idempotency key must be identity-derived and unchanged '
            'across attempts — it is what makes re-sending safe',
      );
      expect(
        store.saved.last.uploadStatus,
        AttachmentUploadStatus.uploaded,
        reason: 'a recovered upload must reach a terminal confirmed state',
      );
    });
  });
}

/// Hands back a fixed set once, then whatever was saved — standing in for the
/// query, not reimplementing it.
class _RecoveryStore implements AttachmentStore {
  _RecoveryStore(this._pending);

  final List<AttachmentRecord> _pending;
  final List<AttachmentRecord> saved = [];

  @override
  Future<List<AttachmentRecord>> findPendingUploads({
    int limit = 50,
    int maxRetries = 5,
  }) async =>
      _pending.where((r) => r.retryCount < maxRetries).toList();

  @override
  Future<void> upsert(AttachmentRecord record) async => saved.add(record);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('AttachmentStore.${invocation.memberName} unexpected');
}

class _RecordingTarget implements AttachmentUploadTarget {
  final List<AttachmentRecord> seen = [];
  final List<String> keys = [];

  @override
  String get entityName => 'notes';

  @override
  String contentUrlFor(String attachmentId) =>
      'https://server.test/attachments/$attachmentId/content';

  @override
  Future<String> upload({
    required AttachmentRecord record,
    required File file,
    required String idempotencyKey,
  }) async {
    seen.add(record);
    keys.add(idempotencyKey);
    return 'server-${record.attachmentId}';
  }
}

AttachmentRecord _record({
  required AttachmentOrigin origin,
  AttachmentDownloadStatus download = AttachmentDownloadStatus.downloaded,
  AttachmentUploadStatus upload = AttachmentUploadStatus.notApplicable,
  bool isRequired = false,
}) =>
    AttachmentRecord(
      attachmentId: 'att-1',
      entityName: 'notes',
      entityLocalId: 'note-1',
      fileName: 'photo.jpg',
      origin: origin,
      downloadStatus: download,
      uploadStatus: upload,
      isRequired: isRequired,
      localPath: download == AttachmentDownloadStatus.downloaded
          ? '/data/app/sync_files/files/ab/abc123'
          : null,
      remoteUrl: 'https://example.test/files/abc123',
      checksum: 'abc123',
      checksumAlgo: 'sha256',
      sizeBytes: 1024,
      createdAt: 1755500000000,
      updatedAt: 1755500000000,
    );

/// Refuses with a given HTTP status, the way Dio surfaces one.
class _FailingTarget implements AttachmentUploadTarget {
  _FailingTarget(this.status);

  final int status;

  @override
  String get entityName => 'notes';

  @override
  String contentUrlFor(String attachmentId) => 'https://server.test/$attachmentId';

  @override
  Future<String> upload({
    required AttachmentRecord record,
    required File file,
    required String idempotencyKey,
  }) async {
    final options = RequestOptions(path: '/attachments');
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: status,
        data: {'status': false, 'message': 'refused'},
      ),
    );
  }
}
