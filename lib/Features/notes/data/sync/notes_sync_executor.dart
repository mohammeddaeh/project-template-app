import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:app_template/core/infra/errors/failure_mapper_registry.dart';

import 'package:app_template/Features/notes/data/datasources/notes_remote_datasource.dart';
import 'package:app_template/Features/notes/data/dtos/note_request_dto.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';

/// Sends one queued note write to the server. **Push only — never a GET.**
///
/// ## Why an executor may not read
///
/// Reads belong to the repository, which decides between the local store and
/// the network and is the only thing the UI talks to. An executor that fetched
/// would create a second, invisible read path with its own idea of what is
/// current — and the two would disagree exactly when it matters, which is while
/// the queue is draining.
///
/// ## Every attempt carries the same idempotency key
///
/// [SyncQueueJob.effectiveIdempotencyKey] is derived at insert time and stays
/// fixed across every retry of that write. That fixedness is the entire
/// mechanism: a key regenerated per attempt protects nothing while looking
/// exactly like protection, and the defect it fails to prevent — a request that
/// committed but whose response was lost — is invisible on the server, where
/// both writes were valid and both succeeded.
///
/// ## The version travels in the payload
///
/// A create sends none: nothing exists to conflict with. An update and a delete
/// send the version the device last saw, so a write built on a stale base is
/// refused with a 409 carrying both sides rather than overwriting an edit
/// nobody saw. `SyncConflictResolver` then decides by the entity's strategy —
/// see `notes_feature_contract.dart`.
@SyncExecutorFor('notes')
@LazySingleton(as: SyncExecutor)
class NotesSyncExecutor implements SyncExecutor {
  const NotesSyncExecutor(this._dataSource);

  final NotesRemoteDataSource _dataSource;

  @override
  String get entityName => 'notes';

  @override
  Set<int> get supportedContractVersions => {1};

  @override
  Future<Either<Failure, SyncExecutionResult>> execute(
    SyncQueueJob job,
    int contractVersion,
  ) async {
    final payload = jsonDecode(job.payloadJson) as Map<String, dynamic>;
    final key = job.effectiveIdempotencyKey;

    // **`await`, and inside a `try`** — both halves matter.
    //
    // Dio's default `validateStatus` accepts only 2xx, so every 409, 422, 404
    // and 500 arrives as a thrown `DioException`, never as the `res.error`
    // envelope `_failure` was written to read. The conflict path below was
    // therefore unreachable: a real 409 threw past it, past the engine, and
    // took the whole sync cycle with it.
    //
    // Returning the `switch` unawaited would have kept it unreachable — the
    // future escapes the `try` before it completes and the `catch` never sees
    // it.
    try {
      return await switch (job.type) {
        SyncJobType.create => _create(job, payload, key),
        SyncJobType.update => _update(job, payload, key),
        SyncJobType.delete => _delete(job, payload, key),
      // Bytes are not this executor's business: they need multipart, resumption
      // and a checksum, none of which belong beside a JSON PATCH. A dedicated
      // file executor owns them.
      //
      // Refused loudly rather than ignored — a file job silently reported as
      // successful here would be dropped from the queue, and the photograph it
      // carried would never be sent by anything.
        SyncJobType.fileUpload => Future.value(
            Left(
              BusinessFailure(
                statusCode: 500,
                serverMessage:
                    'A fileUpload job reached NotesSyncExecutor. File jobs '
                    'belong to the attachment upload executor.',
              ),
            ),
          ),
      };
    } on DioException catch (e) {
      return Left(_failureFromDio(e));
    }
  }

  /// Turns a thrown [DioException] into the same failure the envelope path
  /// produces, so the engine branches on one shape whichever way the server
  /// answered.
  ///
  /// The refusal body is read from **`data`**, because that is where the server
  /// puts it: `{status, message, data: {server_version, client_version,
  /// conflict_fields}}` — see `notes.int.test.ts` in `backend_template`, which
  /// asserts `conflict.body.data.server_version`.
  ///
  /// Anything without that envelope — a timeout, a dropped connection, an HTML
  /// error page from a proxy — is handed to [FailureMapperRegistry], the
  /// template's single place that knows what a transport error means. None of
  /// those paths can produce a success, which is the property that matters: a
  /// 422 or a 500 must never look like a write that landed.
  Failure _failureFromDio(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;

    if (status != null && body is Map<String, dynamic>) {
      return _failureFrom(
        code: status,
        message: (body['message'] as String?) ?? '',
        data: body['data'] as Map<String, dynamic>?,
      );
    }

    return FailureMapperRegistry.map(e, source: 'notes_sync_executor');
  }

  Future<Either<Failure, SyncExecutionResult>> _create(
    SyncQueueJob job,
    Map<String, dynamic> payload,
    String key,
  ) async {
    final res = await _dataSource.create(
      NoteRequestDto(
        // The id the device already gave this note. Sending it is what makes a
        // replayed create resolvable: the server recognises the row instead of
        // writing a second one.
        id: payload['id'] as String?,
        title: payload['title'] as String?,
        body: payload['body'] as String?,
      ),
      idempotencyKey: key,
    );

    if (res.error != null) return Left(_failure(res));
    return Right(
      SyncExecutionResult(localId: job.entityId, serverId: res.data?.id),
    );
  }

  Future<Either<Failure, SyncExecutionResult>> _update(
    SyncQueueJob job,
    Map<String, dynamic> payload,
    String key,
  ) async {
    final res = await _dataSource.update(
      job.entityId,
      NoteRequestDto(
        title: payload['title'] as String?,
        body: payload['body'] as String?,
        version: payload['version'] as int?,
      ),
      idempotencyKey: key,
    );

    if (res.error != null) return Left(_failure(res));
    return Right(
      SyncExecutionResult(localId: job.entityId, serverId: res.data?.id),
    );
  }

  Future<Either<Failure, SyncExecutionResult>> _delete(
    SyncQueueJob job,
    Map<String, dynamic> payload,
    String key,
  ) async {
    final res = await _dataSource.delete(
      job.entityId,
      version: payload['version'] as int?,
      idempotencyKey: key,
    );

    if (res.error != null) return Left(_failure(res));
    return Right(SyncExecutionResult(localId: job.entityId));
  }

  /// Turns a refusal into the failure type the engine branches on.
  ///
  /// **409 must become [ConflictFailure] and nothing else.** The engine's whole
  /// conflict path — resolver, strategy, rebase, the `conflicted` state a user
  /// eventually sees — hangs off that one type. Mapping it to a generic failure
  /// instead would send a conflict down the retry path, where it would be
  /// re-sent unchanged until the job dead-letters: a lost edit reported as a
  /// server error.
  Failure _failure(dynamic res) => _failureFrom(
        code: (res.error?.code as int?) ?? 400,
        message: (res.message as String?) ?? '',
        data: res.error?.data as Map<String, dynamic>?,
      );

  /// The one place a refusal becomes a failure, whether it arrived as an
  /// envelope on a 2xx or as a thrown [DioException] — shared so the two
  /// cannot drift into disagreeing about what a 409 is.
  Failure _failureFrom({
    required int code,
    required String message,
    Map<String, dynamic>? data,
  }) {
    if (code == 409) {
      return ConflictFailure(
        serverVersion: data?['server_version'] as Map<String, dynamic>?,
        clientVersion: data?['client_version'] as Map<String, dynamic>?,
        conflictFields:
            (data?['conflict_fields'] as List<dynamic>?)?.cast<String>() ??
                const <String>[],
      );
    }

    return BusinessFailure(
      statusCode: code,
      serverMessage: message.isNotEmpty ? message : null,
    );
  }
}
