import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/Features/notes/data/datasources/notes_remote_datasource.dart';
import 'package:app_template/Features/notes/data/sync/notes_sync_pull_executor.dart';
import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/core/foundation/contracts/auth_network_gateway.dart';
import 'package:app_template/modules/sync/config/sync_mode.dart';
import 'package:app_template/modules/sync/config/sync_settings.dart';
import 'package:app_template/modules/sync/config/sync_settings_store.dart';
import 'package:app_template/modules/sync/engine/sync_pull_executor.dart';
import 'package:app_template/modules/sync/integration/sync_gate.dart';

/// The pull path's silent failure modes.
///
/// Every assertion here is a defect that reports success on both sides while
/// data quietly goes missing on one device — a cursor that skips, a clock that
/// runs fast, a tombstone read as a row. None of them raise anything, none of
/// them log, and none can be found by using the app: they need a second device,
/// a specific interleaving, and someone counting rows afterwards.
void main() {
  group('SyncCursor', () {
    test('a device that never synced starts at the beginning', () {
      expect(const SyncCursor().isBeginning, isTrue);
      expect(const SyncCursor(updatedSince: '2026-08-18T10:00:00.000Z').isBeginning,
          isFalse);
    });

    test('survives the round trip through sync_meta', () {
      const original = SyncCursor(
        updatedSince: '2026-08-18T10:00:00.000Z',
        afterId: '3f2a7c14-9b1e-4d5a-8c60-2e1f4a6b8d09',
      );
      final restored = SyncCursor.fromJson(original.toJson());

      // Losing `afterId` across a restart is not a crash — it is a batch
      // boundary that lands inside a group of same-millisecond rows and either
      // skips the rest of that group forever or re-sends it every cycle.
      expect(restored.updatedSince, original.updatedSince);
      expect(restored.afterId, original.afterId);
    });

    test('omits absent halves rather than writing nulls', () {
      expect(const SyncCursor().toJson(), isEmpty);
    });
  });

  group('notes pull executor', () {
    test('parses a page and keeps paging while a cursor is returned', () async {
      final executor = NotesSyncPullExecutor(_FakeDataSource(_page(
        records: [_note('a'), _note('b')],
        nextCursor: {
          'updated_since': '2026-08-18T10:00:00.000Z',
          'after_id': 'b',
        },
      )));

      final result = await executor.pull(
        cursor: const SyncCursor(),
        includeDeleted: true,
        limit: 200,
      );

      final page = result.getOrElse(() => throw StateError('expected a page'));
      expect(page.records, hasLength(2));
      expect(page.nextCursor, isNotNull);
      expect(page.serverTime, isNotEmpty);
    });

    test('a null next_cursor is what ends the loop — not an empty page', () async {
      // A full page whose rows all share one timestamp is not the end of the
      // changes. Stopping on `records.isEmpty` would truncate the pull at
      // exactly the boundary a busy second matters most.
      final executor = NotesSyncPullExecutor(_FakeDataSource(_page(
        records: [_note('a')],
        nextCursor: null,
      )));

      final result = await executor.pull(
        cursor: const SyncCursor(),
        includeDeleted: true,
        limit: 200,
      );

      expect(result.getOrElse(() => throw StateError('x')).nextCursor, isNull);
    });

    test('a page with no server_time fails rather than guessing', () async {
      // Falling back to the device's clock is the trap: a phone two minutes
      // fast skips every row written in those two minutes, permanently,
      // because the cursor only moves forward — and both sides report success.
      final executor = NotesSyncPullExecutor(_FakeDataSource(
        ApiResponse<Map<String, dynamic>>(
          status: 'success',
          message: '',
          data: const {'data': <dynamic>[], 'next_cursor': null},
          error: null,
        ),
      ));

      final result = await executor.pull(
        cursor: const SyncCursor(),
        includeDeleted: true,
        limit: 200,
      );

      expect(result.isLeft(), isTrue);
    });

    test('tombstones arrive as records, flagged', () async {
      final executor = NotesSyncPullExecutor(_FakeDataSource(_page(
        records: [_note('gone', isDeleted: true)],
        nextCursor: null,
      )));

      final page = (await executor.pull(
        cursor: const SyncCursor(),
        includeDeleted: true,
        limit: 200,
      ))
          .getOrElse(() => throw StateError('x'));

      // Read as an absence instead, a deleted note comes back to life on every
      // device that already had it.
      expect(page.records.single['is_deleted'], isTrue);
    });

    test('a refusal keeps the cursor by failing the page', () async {
      final executor = NotesSyncPullExecutor(_FakeDataSource(
        ApiResponse<Map<String, dynamic>>(
          status: 'error',
          message: 'nope',
          data: null,
          error: const ApiError(code: 500, message: 'nope'),
        ),
      ));

      final result = await executor.pull(
        cursor: const SyncCursor(updatedSince: '2026-08-18T10:00:00.000Z'),
        includeDeleted: true,
        limit: 200,
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('SyncGate', () {
    test('no session blocks the cycle before any request is made', () async {
      // Running without a credential means every job in the queue takes a 401,
      // every `retry_count` climbs, and perfectly valid writes approach the
      // dead-letter state for a reason that has nothing to do with them.
      final gate = SyncGate(
        _FakeSettings(const SyncSettings(mode: SyncMode.active, syncEnabled: true, wifiOnly: false, periodicIntervalSeconds: null)),
        _UnusedConnectivity(),
        _FakeSession(null),
      );

      expect(await gate.check(), SyncBlockReason.noSession);
    });

    test('a disabled module blocks before the session is even read', () async {
      final gate = SyncGate(
        _FakeSettings(
          const SyncSettings(mode: SyncMode.active, syncEnabled: false, wifiOnly: false, periodicIntervalSeconds: null),
        ),
        _UnusedConnectivity(),
        _FakeSession(null),
      );

      expect(await gate.check(), SyncBlockReason.disabled);
    });

    test('passive mode is not a sync mode', () async {
      final gate = SyncGate(
        _FakeSettings(const SyncSettings(mode: SyncMode.passive, syncEnabled: true, wifiOnly: false, periodicIntervalSeconds: null)),
        _UnusedConnectivity(),
        _FakeSession('token'),
      );

      expect(await gate.check(), SyncBlockReason.disabled);
    });
  });
}

// ── Fixtures ─────────────────────────────────────────────────────────────────

Map<String, dynamic> _note(String id, {bool isDeleted = false}) => {
      'id': id,
      'title': 'Note $id',
      'body': null,
      'created_at': '2026-08-18T09:00:00.000Z',
      'updated_at': '2026-08-18T10:00:00.000Z',
      'version': 1,
      'is_deleted': isDeleted,
    };

ApiResponse<Map<String, dynamic>> _page({
  required List<Map<String, dynamic>> records,
  required Map<String, dynamic>? nextCursor,
}) =>
    ApiResponse<Map<String, dynamic>>(
      status: 'success',
      message: '',
      data: {
        'data': records,
        'next_cursor': nextCursor,
        'server_time': '2026-08-18T10:00:01.000Z',
      },
      error: null,
    );

class _FakeDataSource implements NotesRemoteDataSource {
  _FakeDataSource(this.response);

  final ApiResponse<Map<String, dynamic>> response;

  @override
  Future<ApiResponse<Map<String, dynamic>>> delta({
    String? updatedSince,
    String? afterId,
    required bool includeDeleted,
    required int limit,
  }) async =>
      response;

  /// The pull executor must never touch the other four — reads belong to the
  /// repository, and an executor with a second read path is a second opinion
  /// about what is current. `noSuchMethod` throwing is the assertion.
  @override
  noSuchMethod(Invocation invocation) => throw StateError(
        'A pull executor called ${invocation.memberName} — executors must not '
        'read outside their own delta endpoint.',
      );
}

class _FakeSettings implements SyncSettingsStore {
  _FakeSettings(this._settings);

  final SyncSettings _settings;

  @override
  Future<SyncSettings> getSettings() async => _settings;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSession implements AuthNetworkGateway {
  _FakeSession(this._token);

  final String? _token;

  @override
  String? getToken() => _token;

  @override
  void clearSession() {}
}

/// Never reached: every case here is decided before connectivity is consulted.
/// That ordering is deliberate — the cheap, certain checks come first.
class _UnusedConnectivity implements Connectivity {
  @override
  noSuchMethod(Invocation invocation) =>
      throw StateError('connectivity must not be consulted in these cases');
}
