import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:app_template/core/platform/logging/log_service.dart';

import '../engine/sync_pull_executor.dart';
import 'sync_database.dart';

/// Where each entity's delta pull resumes from — **one cursor per entity**.
///
/// ## This gives `sync_meta` its first consumer
///
/// The table has existed since schema v1 with no reader and no writer, while
/// the cursor it was built for sat in `core/platform/storage/persistence_keys.dart`
/// as `syncLastDownloadAt` — documented as "the `updated_since` cursor for the
/// next sync" and referenced by nothing at all.
///
/// Moving it here does three things at once:
///
/// 1. **`sync_meta` stops being scaffolding** and starts holding what it was
///    made for.
/// 2. **`core/` stops holding a module's key.** A module writing into the
///    composition core is the dependency direction `CLAUDE.md` forbids, and it
///    is how a deleted module leaves orphans behind in the heart of the app.
/// 3. **The cursor becomes per entity**, which the single global key could
///    never be. With one shared cursor, an entity whose pull fails still has
///    the cursor advanced by whichever entity succeeded after it — and every
///    change it missed in that window is skipped forever, silently, because a
///    cursor only moves forward.
class SyncCursorStore {
  const SyncCursorStore(this._database);

  final SyncDatabase _database;

  static const _table = 'sync_meta';
  static const _prefix = 'cursor:';
  static const _tag = 'SYNC';

  /// The cursor for [entityName], or a beginning cursor when this device has
  /// never pulled it.
  Future<SyncCursor> read(String entityName) async {
    final db = await _database.database;
    final rows = await db.query(
      _table,
      where: 'meta_key = ?',
      whereArgs: ['$_prefix$entityName'],
      limit: 1,
    );
    if (rows.isEmpty) return const SyncCursor();

    try {
      return SyncCursor.fromJson(
        jsonDecode(rows.first['meta_value']! as String) as Map<String, dynamic>,
      );
    } catch (e) {
      // A fallback path logs. Treating an unreadable cursor as "start over" is
      // the safe direction — a full re-pull is slow, whereas guessing a
      // position would skip whatever lies between here and the guess.
      LogService.warning(
        'Unreadable sync cursor for "$entityName" — pulling from the beginning: $e',
        tag: _tag,
      );
      return const SyncCursor();
    }
  }

  /// Advances the cursor for [entityName].
  ///
  /// Called **only after a page has been merged**, never before. A cursor saved
  /// ahead of the write it describes is a window of changes that were requested,
  /// dropped, and never offered again.
  Future<void> write(String entityName, SyncCursor cursor) async {
    final db = await _database.database;
    await db.insert(
      _table,
      {
        'meta_key': '$_prefix$entityName',
        'meta_value': jsonEncode(cursor.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Forgets every cursor — the next sync re-pulls everything.
  ///
  /// For account switches and "reset local data": leaving cursors behind would
  /// let a new account inherit a position in another account's timeline and
  /// receive only what changed *since then*, which is a silently partial copy.
  Future<void> clearAll() async {
    final db = await _database.database;
    await db.delete(_table, where: 'meta_key LIKE ?', whereArgs: ['$_prefix%']);
  }
}
