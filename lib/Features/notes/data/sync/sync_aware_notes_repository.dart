import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import 'package:app_template/Features/notes/data/models/note_model.dart';
import 'package:app_template/Features/notes/domain/entities/note.dart';
import 'package:app_template/Features/notes/domain/params/note_params.dart';
import 'package:app_template/Features/notes/domain/repositories/notes_repository.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';

/// [NotesRepository] that keeps working when the network does not.
///
/// Wraps the online repository rather than replacing it: the network path is
/// unchanged and still the source of truth whenever it answers. What this adds
/// is a local copy underneath it, and a queue in front of every write.
///
/// Installed at runtime by `NotesSyncRepositoryDecorator`, so a build with
/// `AppFeatures.offlineSync = false` never constructs it and the feature
/// behaves exactly as it did before the sync module existed.
///
/// ## Extending [SyncableRepository] is not decoration
///
/// `SyncContractValidator.validatePostDecoration` refuses to start the engine
/// unless the bound repository is one. A repository that queues writes without
/// declaring it is the shape of a feature that looks synced and is not.
class SyncAwareNotesRepository extends SyncableRepository
    implements NotesRepository {
  SyncAwareNotesRepository(
    this._inner,
    this._entityStore,
    SyncWriteGateway gateway,
    this._uuid,
    this._contract,
  ) : super(gateway);

  final NotesRepository _inner;
  final SyncEntityStore _entityStore;
  final Uuid _uuid;
  final SyncFeatureContract<Note> _contract;

  static const _entityName = 'notes';
  static const _contractVersion = 1;
  static const _tag = 'SYNC-NOTES';

  /// Cursor of the last row of each page served locally.
  ///
  /// Keyset paging needs the previous page's tail, and `PaginationCubit` asks
  /// for page numbers — so the translation is kept here. Pages arrive in order
  /// in practice; a gap (after a refresh reset the list, say) falls back to
  /// `OFFSET` with a log rather than silently returning the wrong window.
  final Map<int, SyncPageCursor> _pageCursors = {};

  @override
  Stream<void> watch() => _entityStore.watch(_entityName);

  // ── Reads ──────────────────────────────────────────────────────────────────

  /// Server first, local as the fallback — **and the server's answer is cached
  /// on the way past.**
  ///
  /// ## Why not local-first, which is what offline-first usually means
  ///
  /// Because there is no pull path yet (P3 in `lib/modules/sync/PLAN.md`).
  /// Nothing fills the local store from the server, so a local-first read on a
  /// fresh device returns an empty list and the screen would show "no notes" to
  /// an account that has hundreds.
  ///
  /// Caching each page as it is fetched is the honest stopgap: whatever the
  /// user has actually looked at is readable offline afterwards. **Its limits
  /// are real and should not be papered over** — a page never visited is not
  /// there, a note deleted on another device stays until something refetches
  /// that page, and there are no tombstones. All three close with P3.
  ///
  /// Local rows that have never reached the server are merged on top, because
  /// they are invisible to the server by definition and would otherwise vanish
  /// from the list the moment it refreshed.
  @override
  Future<Either<Failure, PaginationDataEntity<Note>>> list(
    ListNotesParams params,
  ) async {
    final remote = await _inner.list(params);

    return remote.fold(
      (failure) => _listFromLocal(params, becauseOf: failure),
      (page) async {
        await _cache(page.data);
        return Right(
          PaginationDataEntity<Note>(
            data: await _withLocalPending(page.data, params),
            paginationInfo: page.paginationInfo,
          ),
        );
      },
    );
  }

  /// Everything this device knows, for when the network answered nothing.
  Future<Either<Failure, PaginationDataEntity<Note>>> _listFromLocal(
    ListNotesParams params, {
    required Failure becauseOf,
  }) async {
    final page = params.paginationQuery.page;
    final limit = params.paginationQuery.perPage;

    try {
      if (page > 1 && !_pageCursors.containsKey(page - 1)) {
        // The previous page was never served locally, so there is no position
        // to resume from. Said out loud rather than silently returning the
        // newest rows again, which would look like a list that repeats itself.
        LogService.warning(
          'No local cursor for page ${page - 1}; page $page cannot be paged '
          'offline. Returning empty rather than the wrong window.',
          tag: _tag,
        );
        return Right(
          PaginationDataEntity<Note>(
            data: const [],
            paginationInfo: const PaginationInfo(
              isFirstPage: false,
              isLastPage: true,
            ),
          ),
        );
      }

      // Parsed by the contract, not by hand: `SyncFeatureContract.fromJson`
      // exists for exactly this and went unused for the module's whole life.
      final localPage = await _entityStore.readTyped<Note>(
        contract: _contract,
        limit: limit,
        cursor: page == 1 ? null : _pageCursors[page - 1],
      );

      // Remember where this page ended, so the next one resumes from it rather
      // than counting past it.
      if (localPage.nextCursor != null) {
        _pageCursors[page] = localPage.nextCursor!;
      }

      LogService.info(
        'Serving ${localPage.items.length} note(s) from the local store — the '
        'network answered ${becauseOf.runtimeType}.',
        tag: _tag,
      );

      return Right(
        PaginationDataEntity<Note>(
          data: localPage.items,
          paginationInfo: PaginationInfo(
            isFirstPage: page == 1,
            // Nothing local knows how many pages the server has. Claiming "last
            // page" stops the list asking for more, which is the correct
            // behaviour while offline and the wrong one to guess at otherwise.
            isLastPage: !localPage.hasMore,
          ),
        ),
      );
    } catch (e) {
      // The local read failed too. Report the *network* failure, not this one:
      // it is the one the user can act on, and burying it under a storage error
      // would send them looking in the wrong place.
      LogService.error(
        'Local note store unreadable — surfacing the network failure instead.',
        tag: _tag,
        error: e,
      );
      return Left(becauseOf);
    }
  }

  /// Adds rows the server has not seen to a page it just returned.
  Future<List<Note>> _withLocalPending(
    List<Note> fromServer,
    ListNotesParams params,
  ) async {
    // Only the first page — a pending row belongs at the top, and inserting it
    // into page four would put it where nobody looks.
    if (params.paginationQuery.page != 1) return fromServer;

    try {
      final local = await _entityStore.getRecordsByEntity(
        entityName: _entityName,
        page: 1,
        limit: params.paginationQuery.perPage,
      );

      final serverIds = fromServer.map((n) => n.id).toSet();
      final pending = local
          .where((r) => r.syncStatus.isPending && !serverIds.contains(r.localId))
          .map(_toEntity)
          .whereType<Note>()
          .toList();

      if (pending.isEmpty) return fromServer;
      return [...pending, ...fromServer];
    } catch (e) {
      LogService.error(
        'Could not merge pending notes into the page — they will reappear on '
        'the next refresh, but are missing from this one.',
        tag: _tag,
        error: e,
      );
      return fromServer;
    }
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Writes locally and queues the push — **and returns before the network is
  /// consulted at all.**
  ///
  /// This is the whole difference offline-first makes at the call site: the
  /// screen gets its note back immediately, in or out of coverage, and the
  /// queue deals with the server on its own schedule.
  @override
  Future<Either<Failure, Note>> save(SaveNoteParams params) async {
    final isCreate = params.id == null;
    final now = DateTime.now();

    // A create gets its identity here, on the device, before anything is sent.
    // That is what lets it be displayed, edited and deleted while offline.
    final id = params.id ?? _uuid.v4();
    final existing = isCreate ? null : await _localRecord(id);

    final note = Note(
      id: id,
      title: params.title,
      body: params.body,
      // Preserved from the stored copy — an update must not reset the creation
      // date to the moment the user pressed save. `SyncEntityRecord` carries
      // only `updatedAt`, so the original comes from the payload itself.
      createdAt: existing == null ? now : (_toEntity(existing)?.createdAt ?? now),
      updatedAt: now,
      // The version the server last confirmed — sent back so the write is
      // conditional. A create has none.
      version: existing?.version ?? 1,
    );

    final json = jsonEncode(NoteModel.fromEntity(note).toJson());

    try {
      await syncWrite(
        SyncWriteCommand(
          entityName: _entityName,
          localId: id,
          serverId: existing?.serverId,
          dataJson: json,
          updatedAt: now.millisecondsSinceEpoch,
          version: note.version,
          isDeleted: false,
          jobType: isCreate ? SyncJobType.create : SyncJobType.update,
          jobPayloadJson: json,
          contractVersion: _contractVersion,
        ),
      );
      return Right(note);
    } catch (e) {
      LogService.error('Could not queue note save', tag: _tag, error: e);
      return Left(StorageFailure(
        operation: StorageOperation.write,
        key: id,
        message: e.toString(),
      ));
    }
  }

  /// Marks the note deleted locally and queues the delete.
  ///
  /// The row is flagged rather than removed, for the same reason the server
  /// soft-deletes: until the delete is acknowledged, "deleted here" and "never
  /// existed" have to stay distinguishable — the queue still has to push it.
  @override
  Future<Either<Failure, void>> delete(DeleteNoteParams params) async {
    final existing = await _localRecord(params.id);
    final now = DateTime.now();

    // Nothing local to flag: fall through to the online path rather than
    // queueing a delete for a row this device has never seen.
    if (existing == null) return _inner.delete(params);

    final tombstone = jsonDecode(existing.dataJson) as Map<String, dynamic>
      ..['is_deleted'] = true
      ..['updated_at'] = now.toIso8601String();
    final json = jsonEncode(tombstone);

    try {
      await syncWrite(
        SyncWriteCommand(
          entityName: _entityName,
          localId: params.id,
          serverId: existing.serverId,
          dataJson: json,
          updatedAt: now.millisecondsSinceEpoch,
          version: existing.version,
          isDeleted: true,
          jobType: SyncJobType.delete,
          jobPayloadJson: json,
          contractVersion: _contractVersion,
        ),
      );
      return const Right(null);
    } catch (e) {
      LogService.error('Could not queue note delete', tag: _tag, error: e);
      return Left(StorageFailure(
        operation: StorageOperation.write,
        key: params.id,
        message: e.toString(),
      ));
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<SyncEntityRecord?> _localRecord(String id) =>
      _entityStore.getRecordByLocalId(entityName: _entityName, localId: id);

  /// Writes a page the server returned into the local store, marked `synced`.
  ///
  /// Never overwrites a row that is still pending: those hold edits the server
  /// has not seen, and replacing them with the server's older copy would
  /// discard the user's work in the middle of a list refresh — silently, and
  /// with no failure anywhere.
  Future<void> _cache(List<Note> notes) async {
    if (notes.isEmpty) return;
    try {
      final fresh = <SyncEntityRecord>[];
      for (final note in notes) {
        final existing = await _localRecord(note.id);
        if (existing != null && existing.syncStatus.isPending) continue;
        fresh.add(
          SyncEntityRecord(
            localId: note.id,
            entityName: _entityName,
            serverId: note.id,
            dataJson: jsonEncode(NoteModel.fromEntity(note).toJson()),
            updatedAt: note.updatedAt.millisecondsSinceEpoch,
            version: note.version,
            syncStatus: SyncStatus.synced,
            isDeleted: note.isDeleted,
            lastSyncedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
      if (fresh.isNotEmpty) await _entityStore.upsertRecords(fresh);
    } catch (e) {
      // Caching is an optimisation; failing it must not fail the read the user
      // asked for. It is logged because a cache that never fills looks exactly
      // like one that is working.
      LogService.error('Could not cache notes page', tag: _tag, error: e);
    }
  }

  Note? _toEntity(SyncEntityRecord record) {
    if (record.isDeleted) return null;
    try {
      return NoteModel.fromJson(
        jsonDecode(record.dataJson) as Map<String, dynamic>,
      ).toEntity();
    } catch (e) {
      LogService.error(
        'Unreadable local note ${record.localId} — skipped.',
        tag: _tag,
        error: e,
      );
      return null;
    }
  }
}
