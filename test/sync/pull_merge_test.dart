import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/sync/automation/sync_feature_contract.dart';
import 'package:app_template/modules/sync/config/sync_mode.dart';
import 'package:app_template/modules/sync/config/sync_settings.dart';
import 'package:app_template/modules/sync/config/sync_settings_store.dart';
import 'package:app_template/modules/sync/data/sync_cursor_store.dart';
import 'package:app_template/modules/sync/data/sync_database.dart';
import 'package:app_template/modules/sync/data/sync_operations_log.dart';
import 'package:app_template/modules/sync/domain/sync_entity_record.dart';
import 'package:app_template/modules/sync/domain/sync_entity_store.dart';
import 'package:app_template/modules/sync/domain/sync_queue_job.dart';
import 'package:app_template/modules/sync/domain/sync_queue_repository.dart';
import 'package:app_template/modules/sync/domain/sync_status.dart';
import 'package:app_template/modules/sync/engine/sync_backoff_policy.dart';
import 'package:app_template/modules/sync/engine/sync_conflict_resolver.dart';
import 'package:app_template/modules/sync/engine/sync_engine.dart';
import 'package:app_template/modules/sync/engine/sync_pull_executor.dart';
import 'package:app_template/modules/sync/integration/sync_lock.dart';
import 'package:app_template/modules/sync/validation/sync_contract_migrator.dart';
import 'package:app_template/modules/sync/validation/sync_contract_validator.dart';

/// Guards the pull phase against overwriting a local row the server has not
/// seen — **S10-1**.
///
/// ## The defect
///
/// `_mergePulled` skipped a local row only when `syncStatus.isPending`, which
/// covers the four `pending*` states and neither terminal one. A row left
/// `failed` by an exhausted push, or `conflicted` by a 409 awaiting a person,
/// fell through and was replaced by the server's copy and stamped `synced`.
/// The last remaining record of that edit was destroyed by a routine refresh,
/// with no exception and no log line naming it.
///
/// ## Why terminal states are protected, from the architecture and not taste
///
/// * `sync_status.dart` — `conflicted` "Awaits [SyncConflictResolver] or user
///   action"; `failed` "Requires manual intervention or full re-bootstrap".
/// * `SyncConflictStrategy.manual` — "The user resolves in the conflict UI —
///   **no automatic resolution**". A pull that replaces the row is an
///   automatic resolution, and server-wins at that.
/// * `ARCHITECTURE.md` §10 — a conflict is «حالةٌ محلية دائمة بواجهة، لا حدثٌ
///   عابر»: a durable local state with a screen, settled from a list at the end
///   of the day. Hours must be able to pass without it being overwritten.
///
/// ## These tests run the real engine
///
/// `SyncEngine.runPendingJobs` → `_processPullPhase` → `_pullEntity` →
/// `_mergePulled`, with the queue empty so only the pull phase does work.
/// `SyncQueueRepository` and `SyncEntityStore` are interfaces;
/// `SyncCursorStore` and `SyncOperationsLog` are subclassed. No sqflite, no
/// platform channel, no new dependency.
void main() {
  late GetIt di;
  late _MemoryEntityStore entities;
  late _MemoryCursorStore cursors;

  setUp(() {
    LogService.setDelegate(const _SilentLog());
    di = GetIt.asNewInstance()..enableRegisteringMultipleInstancesOfOneType();
    di.registerSingleton<SyncFeatureContractBase>(const _NotesContract());
    entities = _MemoryEntityStore();
    cursors = _MemoryCursorStore();
  });

  tearDown(() async {
    LogService.setDelegate(const _SilentLog());
    await di.reset();
  });

  SyncEngine buildEngine(SyncPullExecutor pull) {
    di.registerSingleton<SyncPullExecutor>(pull);
    final queue = _EmptyQueue();
    final migrator = SyncContractMigrator(di);
    final settings = _ActiveSettings();
    return SyncEngine(
      settings,
      queue,
      entities,
      SyncBackoffPolicy(),
      di,
      migrator,
      SyncContractValidator(di, queue, migrator),
      SyncConflictResolver(),
      SyncLock(_MemoryStorage()),
      _SilentOpsLog(),
      cursors,
    );
  }

  /// The server's copy of `n1` — newer, and different in every field a test
  /// could confuse with the local one.
  Map<String, dynamic> serverRow({bool deleted = false}) => {
        'id': 'n1',
        'title': 'FROM SERVER',
        'version': 9,
        'updated_at': '2026-01-01T00:00:00.000Z',
        'is_deleted': deleted,
      };

  SyncEntityRecord localRow(SyncStatus status) => SyncEntityRecord(
        localId: 'n1',
        entityName: 'notes',
        serverId: 'n1',
        dataJson: jsonEncode({'id': 'n1', 'title': 'MINE', 'version': 1}),
        updatedAt: 1,
        version: 1,
        syncStatus: status,
        isDeleted: false,
      );

  Future<void> pullOnce({List<Map<String, dynamic>>? records}) async {
    final engine = buildEngine(
      _FixedPullExecutor(records ?? [serverRow()]),
    );
    await engine.runPendingJobs();
  }

  // ── 1–6: every state the server has not seen is protected ─────────────────

  for (final status in const [
    SyncStatus.failed, // 1
    SyncStatus.conflicted, // 2
    SyncStatus.pending, // 3
    SyncStatus.pendingCreate, // 4
    SyncStatus.pendingUpdate, // 5
    SyncStatus.pendingDelete, // 6
  ]) {
    test('a local "${status.name}" row survives a pull', () async {
      entities.put(localRow(status));

      await pullOnce();

      final after = entities.rows['n1']!;
      expect(
        jsonDecode(after.dataJson)['title'],
        'MINE',
        reason: '${status.name} was overwritten by the server copy — S10-1.',
      );
      expect(after.syncStatus, status, reason: 'The state itself must survive.');
      expect(after.version, 1);
      expect(entities.upsertedIds, isEmpty);
    });
  }

  // ── 7: synced rows are still refreshed ────────────────────────────────────

  test('a local "synced" row IS updated by the pulled server row', () async {
    entities.put(localRow(SyncStatus.synced));

    await pullOnce();

    final after = entities.rows['n1']!;
    expect(jsonDecode(after.dataJson)['title'], 'FROM SERVER');
    expect(after.version, 9);
    expect(after.syncStatus, SyncStatus.synced);
  });

  // ── 8: unknown rows still arrive ──────────────────────────────────────────

  test('a server row this device has never seen is inserted', () async {
    await pullOnce();

    expect(entities.rows.containsKey('n1'), isTrue);
    expect(jsonDecode(entities.rows['n1']!.dataJson)['title'], 'FROM SERVER');
  });

  test('a tombstone still lands on a synced row', () async {
    entities.put(localRow(SyncStatus.synced));

    await pullOnce(records: [serverRow(deleted: true)]);

    expect(entities.rows['n1']!.isDeleted, isTrue);
  });

  test('a tombstone does NOT land on a conflicted row', () async {
    // The delete-vs-edit case ARCHITECTURE.md §10 calls «manual دائماً، بلا
    // استثناء» — an automatic rule is wrong here in either direction.
    entities.put(localRow(SyncStatus.conflicted));

    await pullOnce(records: [serverRow(deleted: true)]);

    expect(entities.rows['n1']!.isDeleted, isFalse);
    expect(entities.rows['n1']!.syncStatus, SyncStatus.conflicted);
  });

  // ── 9: cursor behaviour is unchanged ──────────────────────────────────────

  test('the cursor advances to server_time when caught up', () async {
    entities.put(localRow(SyncStatus.failed));

    await pullOnce();

    expect(cursors.written, hasLength(1));
    expect(cursors.written.single.updatedSince, '2026-01-01T00:00:00.000Z');
    expect(cursors.written.single.afterId, isNull);
  });

  test('skipping a protected row does not stall or rewind paging', () async {
    entities.put(localRow(SyncStatus.conflicted));
    final engine = buildEngine(
      _PagingPullExecutor([
        // page 1 — carries the protected row, plus one that must land
        [serverRow(), {..._row('n2'), 'title': 'PAGE1'}],
        // page 2 — the tail
        [_row('n3')],
      ]),
    );

    await engine.runPendingJobs();

    expect(entities.rows['n1']!.syncStatus, SyncStatus.conflicted);
    expect(entities.rows.containsKey('n2'), isTrue);
    expect(entities.rows.containsKey('n3'), isTrue);
    // One cursor write per page: the intermediate keyset, then server_time.
    expect(cursors.written, hasLength(2));
    expect(cursors.written.first.afterId, 'n2');
    expect(cursors.written.last.updatedSince, '2026-01-01T00:00:00.000Z');
  });

  // ── The invariant itself, so a future state cannot slip through ───────────

  test('every state except synced is protected — exhaustively', () async {
    for (final status in SyncStatus.values) {
      entities = _MemoryEntityStore()..put(localRow(status));
      cursors = _MemoryCursorStore();
      await di.reset();
      di
        ..enableRegisteringMultipleInstancesOfOneType()
        ..registerSingleton<SyncFeatureContractBase>(const _NotesContract());

      await pullOnce();

      final title = jsonDecode(entities.rows['n1']!.dataJson)['title'];
      if (status == SyncStatus.synced) {
        expect(title, 'FROM SERVER', reason: 'synced must still refresh.');
      } else {
        expect(
          title,
          'MINE',
          reason: 'SyncStatus.${status.name} is not covered by the guard. '
              'A state was added to the enum without being classified as '
              'pending or terminal, and the pull will overwrite it.',
        );
      }
    }
  });
}

Map<String, dynamic> _row(String id) => {
      'id': id,
      'title': id,
      'version': 1,
      'updated_at': '2026-01-01T00:00:00.000Z',
      'is_deleted': false,
    };

// ── Doubles ──────────────────────────────────────────────────────────────────

class _FixedPullExecutor implements SyncPullExecutor {
  _FixedPullExecutor(this._records);
  final List<Map<String, dynamic>> _records;

  @override
  String get entityName => 'notes';

  @override
  Future<Either<Failure, SyncPullPage>> pull({
    required SyncCursor cursor,
    required bool includeDeleted,
    required int limit,
  }) async =>
      Right(
        SyncPullPage(
          records: _records,
          serverTime: '2026-01-01T00:00:00.000Z',
        ),
      );
}

class _PagingPullExecutor implements SyncPullExecutor {
  _PagingPullExecutor(this._pages);
  final List<List<Map<String, dynamic>>> _pages;
  int _index = 0;

  @override
  String get entityName => 'notes';

  @override
  Future<Either<Failure, SyncPullPage>> pull({
    required SyncCursor cursor,
    required bool includeDeleted,
    required int limit,
  }) async {
    final page = _pages[_index];
    final isLast = _index == _pages.length - 1;
    _index++;
    return Right(
      SyncPullPage(
        records: page,
        serverTime: '2026-01-01T00:00:00.000Z',
        nextCursor: isLast
            ? null
            : SyncCursor(
                updatedSince: '2026-01-01T00:00:00.000Z',
                afterId: page.last['id'] as String,
              ),
      ),
    );
  }
}

class _MemoryEntityStore implements SyncEntityStore {
  final Map<String, SyncEntityRecord> rows = {};
  final List<String> upsertedIds = [];

  void put(SyncEntityRecord r) => rows[r.localId] = r;

  @override
  Future<SyncEntityRecord?> getRecordByLocalId({
    required String entityName,
    required String localId,
  }) async =>
      rows[localId];

  @override
  Future<void> upsertRecords(
    List<SyncEntityRecord> records, {
    bool notify = true,
  }) async {
    for (final r in records) {
      upsertedIds.add(r.localId);
      rows[r.localId] = r;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('SyncEntityStore.${invocation.memberName} unexpected');
}

class _MemoryCursorStore extends SyncCursorStore {
  _MemoryCursorStore() : super(SyncDatabase());

  final List<SyncCursor> written = [];
  SyncCursor _current = const SyncCursor();

  @override
  Future<SyncCursor> read(String entityName) async => _current;

  @override
  Future<void> write(String entityName, SyncCursor cursor) async {
    written.add(cursor);
    _current = cursor;
  }
}

class _EmptyQueue implements SyncQueueRepository {
  @override
  Future<List<SyncQueueJob>> getDueJobs({
    required int nowMs,
    required int limit,
  }) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('SyncQueueRepository.${invocation.memberName} unexpected');
}

class _ActiveSettings implements SyncSettingsStore {
  @override
  Future<SyncSettings> getSettings() async => const SyncSettings(
        mode: SyncMode.active,
        syncEnabled: true,
        wifiOnly: false,
        periodicIntervalSeconds: 300,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) async {}
}

class _MemoryStorage implements StorageService {
  final Map<String, String> _values = {};

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> writeString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('StorageService.${invocation.memberName} unexpected');
}

class _SilentOpsLog extends SyncOperationsLog {
  _SilentOpsLog() : super(SyncDatabase());

  @override
  Future<void> log({
    required String entityName,
    required String entityId,
    required SyncLogOperation operation,
    String? jobId,
    String? serverId,
    String? errorCode,
    String? errorDetail,
    String? payloadSnapshot,
  }) async {}

  @override
  Future<void> trim() async {}
}

class _NotesContract extends SyncFeatureContractBase {
  const _NotesContract();

  @override
  String get entityName => 'notes';

  @override
  Type get repositoryContractType => Object;

  @override
  Object resolveRepository(GetIt di) => Object();
}

class _SilentLog implements LogDelegate {
  const _SilentLog();
  @override
  void warning(String message, {String? tag}) {}
  @override
  void info(String message, {String? tag}) {}
  @override
  void debug(String message, {String? tag}) {}
  @override
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {}
}
