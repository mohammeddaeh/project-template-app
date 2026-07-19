import 'dart:io';

import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SyncDatabase {
  static const String dbName = 'app_sync.db';
  static const int dbVersion = 3;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, dbName);

    // Integrity check before opening — wipe and re-bootstrap if corrupted.
    await _checkIntegrity(dbPath);

    return openDatabase(
      dbPath,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        await db.execute('PRAGMA journal_mode = WAL;');
      },
    );
  }

  Future<void> _checkIntegrity(String dbPath) async {
    if (!File(dbPath).existsSync()) return;
    Database? probe;
    try {
      probe = await openDatabase(dbPath, readOnly: true);
      final result = await probe.rawQuery('PRAGMA integrity_check;');
      if (result.isEmpty || result.first.values.first != 'ok') {
        LogService.warning(
          'SQLite integrity check failed — wiping sync database for clean re-bootstrap.',
          tag: 'SYNC',
        );
        await probe.close();
        probe = null;
        await File(dbPath).delete();
      }
    } catch (_) {
      await probe?.close();
      probe = null;
      try {
        await File(dbPath).delete();
        LogService.warning('Corrupt sync DB deleted — will re-bootstrap.', tag: 'SYNC');
      } catch (_) {}
    } finally {
      await probe?.close();
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createV3Schema(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE sync_queue ADD COLUMN contract_version INTEGER NOT NULL DEFAULT 1;',
      );
    }
    if (oldVersion < 3) {
      // Add priority + idempotency_key to sync_queue
      await db.execute(
        'ALTER TABLE sync_queue ADD COLUMN priority INTEGER NOT NULL DEFAULT 10;',
      );
      await db.execute(
        'ALTER TABLE sync_queue ADD COLUMN idempotency_key TEXT NULL;',
      );
      // Add last_synced_at to synced_entities
      await db.execute(
        'ALTER TABLE synced_entities ADD COLUMN last_synced_at INTEGER NULL;',
      );
      // Recreate index with priority
      await db.execute('DROP INDEX IF EXISTS idx_sync_queue_due;');
      await db.execute(
        'CREATE INDEX idx_sync_queue_due ON sync_queue(priority ASC, next_retry_at ASC, created_at ASC);',
      );
    }
  }

  Future<void> _createV3Schema(Database db) async {
    await db.execute('''
      CREATE TABLE synced_entities(
        local_id       TEXT PRIMARY KEY,
        entity_name    TEXT NOT NULL,
        server_id      TEXT NULL,
        data_json      TEXT NOT NULL,
        updated_at     INTEGER NOT NULL,
        version        INTEGER NOT NULL DEFAULT 1,
        sync_status    TEXT NOT NULL DEFAULT 'synced',
        is_deleted     INTEGER NOT NULL DEFAULT 0,
        last_synced_at INTEGER NULL,
        last_error     TEXT NULL
      );
    ''');

    await db.execute(
      'CREATE INDEX idx_synced_entities_name_updated ON synced_entities(entity_name, updated_at DESC);',
    );
    await db.execute(
      'CREATE INDEX idx_synced_entities_name_server ON synced_entities(entity_name, server_id);',
    );
    await db.execute(
      'CREATE INDEX idx_synced_entities_pending ON synced_entities(sync_status) WHERE sync_status NOT IN (\'synced\', \'failed\');',
    );

    await db.execute('''
      CREATE TABLE sync_queue(
        job_id            TEXT PRIMARY KEY,
        type              TEXT NOT NULL,
        entity_name       TEXT NOT NULL,
        entity_id         TEXT NOT NULL,
        payload_json      TEXT NOT NULL,
        contract_version  INTEGER NOT NULL DEFAULT 1,
        idempotency_key   TEXT NULL,
        priority          INTEGER NOT NULL DEFAULT 10,
        retry_count       INTEGER NOT NULL DEFAULT 0,
        max_retries       INTEGER NOT NULL DEFAULT 5,
        next_retry_at     INTEGER NOT NULL,
        created_at        INTEGER NOT NULL,
        last_error        TEXT NULL
      );
    ''');

    await db.execute(
      'CREATE INDEX idx_sync_queue_due ON sync_queue(priority ASC, next_retry_at ASC, created_at ASC);',
    );
    await db.execute(
      'CREATE INDEX idx_sync_queue_entity ON sync_queue(entity_name, entity_id);',
    );

    await db.execute('''
      CREATE TABLE sync_meta(
        meta_key   TEXT PRIMARY KEY,
        meta_value TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE sync_operations_log(
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_name      TEXT NOT NULL,
        entity_id        TEXT NOT NULL,
        job_id           TEXT NULL,
        operation        TEXT NOT NULL,
        occurred_at      INTEGER NOT NULL,
        server_id        TEXT NULL,
        error_code       TEXT NULL,
        error_detail     TEXT NULL,
        payload_snapshot TEXT NULL
      );
    ''');

    await db.execute(
      'CREATE INDEX idx_ops_log_entity ON sync_operations_log(entity_name, entity_id, occurred_at DESC);',
    );
    await db.execute(
      'CREATE INDEX idx_ops_log_time ON sync_operations_log(occurred_at DESC);',
    );
  }
}
