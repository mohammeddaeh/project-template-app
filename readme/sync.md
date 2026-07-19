# Offline-First Sync System — Authoritative Engineering Reference

> **Classification:** Engineering Mandate
> **Authority:** This document overrides all other references for sync behavior.
> **Audience:** All engineers. Reading this document is required before touching any sync-related code.
> **Module:** `lib/modules/sync/`
> **Last audited:** 2026-06-18
>
> **Quick start for new developers:** Read [`lib/modules/sync/SETUP.md`](../lib/modules/sync/SETUP.md) first, then return here for the full reference.

---

> ## ✅ IMPLEMENTATION STATUS: COMPLETE — BACKEND INTEGRATION REQUIRED
>
> All five confirmed defects have been fixed in the codebase (see [Section 3](#3-critical-fixes)).
> The module is structurally production-ready. **Backend contract compliance is the only remaining blocker.**
> See [SETUP.md](../lib/modules/sync/SETUP.md) → "Roadmap checklist" before deployment.

---

## Table of Contents

0. [Template Integration Contract](#0-template-integration-contract) ← **Start here**
1. [System Philosophy](#1-system-philosophy)
2. [Current State Analysis](#2-current-state-analysis)
3. [Critical Fixes](#3-critical-fixes)
4. [Sync Lifecycle](#4-sync-lifecycle)
5. [Queue System Design](#5-queue-system-design)
6. [Conflict Resolution System](#6-conflict-resolution-system)
7. [Data Model Contract](#7-data-model-contract)
8. [Backend API Contract](#8-backend-api-contract)
9. [Large Data Strategy](#9-large-data-strategy)
10. [Relationships — Many-to-Many](#10-relationships)
11. [Offline UX](#11-offline-ux)
12. [Orchestrator — SyncManagerCubit](#12-orchestrator)
13. [Failure Modes](#13-failure-modes)
14. [Observability and Debugging](#14-observability)
15. [Module Boundaries](#15-module-boundaries)
16. [Data Request Strategy](#16-data-request-strategy)
17. [Things That Break in Production](#17-things-that-break-in-production)
18. [Strict Do / Don't Rules](#18-strict-rules)
19. [Per-App Entity Configuration](#19-per-app-entity-configuration)
20. [Roadmap](#20-roadmap)

---

## 1. System Philosophy

> **Before reading this section:** Start with [Section 0 — Template Integration Contract](#0-template-integration-contract) which defines required changes to `foundation/errors/`, `AppFeatures`, `StorageService`, and `ConnectivityService` before any implementation.

### 1.1 Source of Truth

The system operates with a **split-authority model**:

| Authority | Owns | Role |
|-----------|------|------|
| **Local SQLite** | What the user sees | Immediate source of truth for all UI reads |
| **Server** | Canonical record of what happened | Final authority for conflict resolution and eventual state |

These two sources are temporarily divergent during offline periods and must converge through the sync cycle. The UI must **never wait for the server to render data**. Every UI read is from local DB. Every server response is written to local DB first, then the UI reacts.

**Why this matters:** In systems that read from the server directly, going offline means the app breaks. In offline-first systems, going offline is a first-class state — the app continues to function, writes are queued, and convergence happens automatically when connectivity restores.

### 1.2 Consistency Model

**Eventual consistency with deterministic conflict resolution.**

- The system does not guarantee that all devices see the same data at the same time.
- The system **does** guarantee that all devices will eventually converge to the same state.
- Conflicts (when two devices edit the same record independently) are resolved deterministically using pluggable strategies — not randomly.

**Convergence conditions:**

1. Device goes online
2. Sync cycle completes (push → pull)
3. All queued jobs reach `synced` state
4. No unresolved `conflicted` entities remain

### 1.3 Design Principles

These principles govern every design decision. Deviations require explicit documented justification.

**Principle 1 — Offline-First, Not Remote-First**

> The system must function completely without a network connection. A network is an optimization, not a requirement.

Remote-first: `UI → API → DB` — breaks offline.
Offline-first: `UI → Local DB ← (Sync) ← API` — works always.

**Principle 2 — Idempotency-First**

> Every write operation must be safe to execute multiple times. The outcome of N executions of the same operation must equal the outcome of one execution.

This is not optional. Networks drop. Processes crash. Retries happen. Without idempotency, retries corrupt data. Period.

**Principle 3 — Deterministic Sync**

> Given the same local state and server state, the sync outcome must always be the same, regardless of timing, device, or network conditions.

Non-determinism (e.g., "retry and see what happens") is not acceptable in production data systems.

**Principle 4 — Push Before Pull**

> Local changes must reach the server before the server's state is downloaded.

Violating this means a Pull can overwrite locally-queued changes, silently discarding user work.

**Principle 5 — Single Sync Execution**

> At most one sync cycle runs at any point in time, enforced by a persistent lock.

Concurrent cycles produce duplicate jobs, duplicate server writes, and corrupted queue state.

**Principle 6 — Fail Loudly, Recover Automatically**

> Failures must be logged, classified, and handled. Silent failures are defects. The system must recover without user intervention whenever possible.

---

## 0. Template Integration Contract

This section defines exactly how the sync module plugs into the template's core systems. Read this before any implementation. Every item here is a hard requirement — not a suggestion.

### 0.1 Required Changes to `foundation/errors/failure.dart`

`ConflictFailure` does not exist in the template's sealed `Failure` hierarchy. It **must be added** before implementing Fix 4 (Section 3).

**Step 1 — Add to `lib/core/foundation/errors/failure.dart`:**

```dart
// Add after BusinessFailure:

/// HTTP 409 — the server rejected a write because of a version conflict.
///
/// [serverVersion] and [clientVersion] are the full entity snapshots from
/// the 409 response body. [conflictFields] lists only the differing fields.
/// All three are for conflict resolution logic only — NOT for display.
final class ConflictFailure extends Failure {
  const ConflictFailure({
    this.serverVersion,
    this.clientVersion,
    this.conflictFields = const [],
  });

  final Map<String, dynamic>? serverVersion;
  final Map<String, dynamic>? clientVersion;
  final List<String> conflictFields;

  @override
  String? get diagnosticMessage =>
      'conflict on fields: ${conflictFields.join(', ')}';
}
```

**Step 2 — Add to `lib/presentation/error/failure_ui_mapper.dart`:**

```dart
// ConflictFailure is a sync-internal failure.
// The UI should never display a raw conflict error — the SyncConflictResolver
// handles it transparently (serverWins/clientWins) or emits a ConflictDetected
// event for manual resolution. Map to Silent() so no toast appears.
case ConflictFailure(): return const Silent();
```

**Step 3 — Update `lib/core/infra/errors/dio_failure_mapper.dart`:**

```dart
// In _fromBadResponse(), add before the final BusinessFailure return:
if (status == 409) {
  final body = error.response?.data;
  final map = body is Map<String, dynamic> ? body : null;
  return ConflictFailure(
    serverVersion: map?['server_version'] as Map<String, dynamic>?,
    clientVersion: map?['client_version'] as Map<String, dynamic>?,
    conflictFields: (map?['conflict_fields'] as List?)
        ?.map((e) => e.toString())
        .toList() ?? [],
  );
}
```

> After these changes, run `dart analyze lib` to confirm exhaustive switch compliance.

---

### 0.2 Required Change to `AppFeatures`

Add the `offlineSync` flag to `lib/core/platform/features/app_features.dart`:

```dart
abstract final class AppFeatures {
  // ... existing flags ...

  // ── Optional modules ──────────────────────────────────────────────────────
  /// Enable offline-first sync engine.
  /// When false: SyncSDK.initialize() exits immediately — no DI overhead.
  static const offlineSync = false;  // ← set to true when using the sync module
}
```

Then in `main.dart`:

```dart
await SyncSDK.initialize(
  SyncSdkConfig(
    enabled: AppFeatures.offlineSync,  // ← guarded by the flag
    mode: SyncMode.active,
    syncEnabled: true,
  ),
  getIt,
);
```

---

### 0.3 `SyncLock` — Use `StorageService`, Not `SharedPreferences` Directly

Template policy: all local storage goes through `StorageService` (from `core/platform/storage/`) and keys are declared in `PersistenceKeys`. Direct `SharedPreferences` imports in `modules/` violate the storage abstraction layer.

```dart
// lib/core/platform/storage/persistence_keys.dart — ADD:
static const String syncLockAcquiredAt = 'sync_lock_acquired_at_ms';

// lib/modules/sync/integration/sync_lock.dart — CORRECT implementation:
class SyncLock {
  SyncLock(this._storage);           // ← inject StorageService, not SharedPreferences

  final StorageService _storage;
  static const _ttl = Duration(minutes: 10);

  Future<bool> acquire() async {
    final raw = await _storage.getString(PersistenceKeys.syncLockAcquiredAt);
    if (raw != null) {
      final age = DateTime.now().millisecondsSinceEpoch - (int.tryParse(raw) ?? 0);
      if (age < _ttl.inMilliseconds) return false;
      LogService.warning('Overriding stale sync lock (age: ${age}ms)', tag: 'SYNC');
    }
    await _storage.setString(
      PersistenceKeys.syncLockAcquiredAt,
      '${DateTime.now().millisecondsSinceEpoch}',
    );
    return true;
  }

  Future<void> release() =>
      _storage.remove(PersistenceKeys.syncLockAcquiredAt);

  Future<void> releaseIfStale() async {
    final raw = await _storage.getString(PersistenceKeys.syncLockAcquiredAt);
    if (raw == null) return;
    final age = DateTime.now().millisecondsSinceEpoch - (int.tryParse(raw) ?? 0);
    if (age >= _ttl.inMilliseconds) {
      LogService.warning('Releasing stale startup lock (age: ${age}ms)', tag: 'SYNC');
      await release();
    }
  }
}
```

---

### 0.4 `SyncController` — Use `ConnectivityService`, Not Raw Packages

Template provides `ConnectivityService` in `core/platform/connectivity/`. `modules/` code must use it instead of importing `connectivity_plus` or `internet_connection_checker` directly.

```dart
// WRONG — direct package import in modules/:
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

// CORRECT — use the template's abstraction:
import 'package:app_template/core/platform/connectivity/connectivity_service.dart';

class SyncController {
  SyncController(this._settingsStore, this._connectivity, this._syncEngine);

  final ConnectivityService _connectivity;  // ← platform abstraction

  Future<bool> _canSyncNow() async {
    final settings = await _settingsStore.getSettings();
    if (settings.mode != SyncMode.active || !settings.syncEnabled) return false;
    return await _connectivity.hasConnection;  // ← single call, no raw packages
  }
}
```

---

### 0.5 Cubit Error Pattern — Template Convention

Every Cubit in this system (including `SyncManagerCubit` and `OfflineUxCubit`) must handle failures using the template's canonical pattern:

```dart
// CORRECT — template convention (from core-architecture.mdc):
result.fold(
  (failure) {
    switch (FailureUiMapper.toAction(failure)) {
      case ShowError(:final message):
        // show error toast or set error state
        break;
      case NavigateToLogin():
        AuthEventBus.instance.emit(AuthEvent.sessionExpired);
        break;
      case Silent():
        // ConflictFailure, CancelledFailure → handled internally, no user toast
        break;
    }
  },
  (data) => /* success handling */,
);
```

**Key rule for sync:** `ConflictFailure` maps to `Silent()` — it is consumed internally by `SyncConflictResolver`. The Cubit must never show a "conflict" toast from `FailureUiMapper` — that is the resolver's job.

---

### 0.5 Required Enum Expansions

Two enums in `lib/modules/sync/domain/sync_status.dart` must be expanded before Phase 2 implementation.

**`SyncStatus` — add missing states:**

```dart
enum SyncStatus {
  // ── Current (v2) ─────────────────────────────────
  pending,   // ← any queued, unprocessed change
  synced,    // ← server confirmed
  failed,    // ← max retries exceeded

  // ── Add for v3 ───────────────────────────────────
  pendingCreate,   // entity created locally, not yet on server
  pendingUpdate,   // entity updated locally, not yet pushed
  pendingDelete,   // entity marked for deletion, not yet pushed
  conflicted,      // server returned 409 — awaits ConflictResolver or user action
}
```

**Why the distinction matters:** `pending` alone cannot answer "is this a new entity or an update?" The UI needs `pendingCreate`/`pendingUpdate` to show the right icon. `conflicted` must be distinct from `failed` — `failed` means "give up," `conflicted` means "needs resolution."

**`SyncConflictStrategy` — add missing strategies:**

```dart
enum SyncConflictStrategy {
  serverWins,    // ← current — discard local, apply server version (default)
  clientWins,    // ← current — re-push local version with X-Force-Override

  // ── Add for pluggable conflict resolution ────────
  lastWriteWins, // compare updated_at — newer wins (peer data)
  merge,         // apply per-field merge function (rich documents)
  manual,        // mark as conflicted, emit ConflictDetected — user resolves
}
```

**`SyncFeatureContractBase` — add the strategy declaration:**

```dart
abstract class SyncFeatureContractBase {
  // ... existing fields ...

  /// Conflict strategy for this entity type.
  /// Override in feature contracts where server authority is not appropriate.
  SyncConflictStrategy get conflictStrategy => SyncConflictStrategy.serverWins;
}
```

---

### 0.6 `UsersSyncExecutor` — Existing Implementation is Incorrect

The current `Features/users/data/sync/users_sync_executor.dart` calls `_api.getUsers()` — a **GET** request — inside a `SyncExecutor`. This is architecturally wrong.

**A `SyncExecutor` has one job: send local data TO the server (POST/PATCH/DELETE).**
It is a push mechanism, not a pull mechanism. Pulling data is the engine's `deltaDownload()` responsibility.

The current implementation would:
- Read `page` and `perPage` from `payloadJson` → fetches a list of users
- Return success with `serverId: job.entityId` (unchanged) — no server-side write at all

**This is the correct pattern:**

```dart
@SyncExecutorFor('users')
@LazySingleton(as: SyncExecutor)
class UsersSyncExecutor implements SyncExecutor {
  const UsersSyncExecutor(this._api);
  final UsersApiService _api;

  @override
  String get entityName => 'users';

  @override
  Set<int> get supportedContractVersions => {1};

  @override
  Future<Either<Failure, SyncExecutionResult>> execute(
    SyncQueueJob job,
    int contractVersion,
  ) async {
    try {
      final payload = jsonDecode(job.payloadJson) as Map<String, dynamic>;
      final opts = Options(headers: {'Idempotency-Key': job.idempotencyKey});

      return switch (job.type) {
        SyncJobType.create => _create(payload, opts, job),
        SyncJobType.update => _update(payload, opts, job),
        SyncJobType.delete => _delete(job.entityId, opts, job),
      };
    } catch (e) {
      return Left(FailureMapperRegistry.map(e, source: 'users-sync'));
    }
  }

  Future<Either<Failure, SyncExecutionResult>> _create(
    Map<String, dynamic> payload, Options opts, SyncQueueJob job,
  ) async {
    final res = await _api.createUser(UserCreateRequest.fromJson(payload), opts);
    if (res.error != null) {
      return Left(BusinessFailure(statusCode: res.error!.code ?? 400));
    }
    return Right(SyncExecutionResult(
      localId: job.entityId,
      serverId: res.data!.id,   // ← server-assigned ID
    ));
  }

  // _update, _delete follow the same pattern
}
```

**The key differences:**
1. Uses `job.type` to decide POST/PATCH/DELETE — not always GET
2. Sends the local payload to the server
3. Returns `serverId` from server response (for `pending_create` jobs where the server assigns the ID)
4. Sends `Idempotency-Key` header

> Every feature that uses the sync module must implement its `SyncExecutor` following this pattern. The `users` executor is the **reference implementation** — it must be correct.

---

### 0.7 Public API — `sync_plugin.dart`

The only file any code outside `modules/sync/` should import is `sync_plugin.dart`:

```dart
// lib/modules/sync/sync_plugin.dart — current exports:
export 'sdk/sync_sdk.dart' show SyncSDK;
export 'sdk/sync_sdk_config.dart' show SyncSdkConfig;
export 'engine/sync_job_executor.dart' show SyncExecutor, SyncExecutionResult;
export 'engine/sync_executor_for.dart' show SyncExecutorFor;
export 'domain/sync_write_gateway.dart' show SyncWriteGateway, SyncWriteCommand;
export 'domain/syncable_repository.dart' show SyncableRepository;
```

**Usage from `main.dart`:**

```dart
import 'package:app_template/modules/sync/sync_plugin.dart';

await SyncSDK.initialize(config, getIt);
```

**Usage from a Feature:**

```dart
// Features only touch SyncWriteGateway and SyncableRepository:
import 'package:app_template/modules/sync/sync_plugin.dart';
```

**Forbidden:** Importing any file from `modules/sync/engine/`, `modules/sync/data/`, or `modules/sync/integration/` outside of `SyncPlugin`. These are internal implementation details.

---

## 2. Current State Analysis

### 2.1 ✅ Implemented and Verified

| Component | Notes |
|-----------|-------|
| SQLite schema v2 (`synced_entities`, `sync_queue`, `sync_meta`) | Foreign keys ON. Indexes on primary access patterns. |
| `SyncEngine` — batch job processor | In-memory `_isRunning` guard. 30 jobs/batch. Correct backoff integration. |
| `SyncBackoffPolicy` — exponential backoff | `2^n × base`, configurable max. |
| `SyncConflictResolver` | Implemented. **Not wired into engine.** |
| `SyncController` — trigger orchestration | Connectivity events + periodic timer. No stability probe. |
| `SyncBootstrap` — DI registration | Registers all sync services. |
| `SyncQueueRepository` — coalescing | create+update→create, any+delete→delete. |
| `SyncEntityStore` — entity cache | Upsert + paginated reads. |
| `SyncWriteGateway` — atomic write | Entity upsert + optional queue enqueue in one transaction. |
| `SyncContractValidator` — DI graph check | Pre/post-init validation. |
| `SyncContractMigrator` — payload migration | Version-to-version migration. |
| `SyncSDK` — initialization entry point | Correct sequence. **Never called from `main.dart`.** |
| Users feature adapter | Contract + Executor + Decorator. Complete reference implementation. |
| Full DI configuration | All sync services wired in `injection.config.dart`. |

### 2.2 ⚠️ Partially Implemented

| Component | Gap |
|-----------|-----|
| `SyncConflictResolver` | Built but not invoked by engine — 409 treated as generic failure |
| `SyncEngine._isRunning` | In-memory lock only — does not survive process restart |
| `SyncController._canSyncNow()` | Does not use `NetworkStabilityProbe` — triggers on unstable connections |
| SQLite schema | Missing: `sync_state`, `last_synced_at`, `local_version`, `priority`, `idempotency_key` |

### 2.3 ❌ Missing — Grouped by Impact

**Data Corruption Risk (will cause corruption in production):**

- `SyncSDK.initialize()` not called — sync is completely disabled
- No persistent `SyncLock` — concurrent runs cause duplicate writes
- No `Idempotency-Key` — retries cause duplicate server writes
- HTTP 409 not handled — `ConflictFailure` type not yet in `foundation/errors/failure.dart`; conflicts exhaust retries → silent data loss
- Push-before-Pull not structurally enforced
- `UsersSyncExecutor` calls `getUsers()` (GET) instead of `createUser/updateUser/deleteUser` — push writes never reach server

**Enum Gaps (block feature implementation):**

- `SyncStatus` missing: `pendingCreate`, `pendingUpdate`, `pendingDelete`, `conflicted` (see Section 0.5)
- `SyncConflictStrategy` missing: `lastWriteWins`, `manual`, `merge` (see Section 0.5)

**Scale Risk (will fail at 10K+ records):**

- Delta sync not wired — every sync fetches 100% of all data
- No cursor-based pagination — page-based breaks under concurrent inserts

**Operational Risk (makes production issues undiagnosable):**

- No operation log — cannot audit what happened to a `failed` entity
- No sync metrics — cannot detect anomalies before users complain
- No `PRAGMA integrity_check` at startup — corrupted DB causes crash loop

**UX Risk:**

- No Offline UI layer — users are unaware of their offline state or pending changes
- No Optimistic UI — writes feel slow
- No conflict notification — users cannot resolve `conflicted` entities

---

## 3. Critical Fixes

These five fixes must be completed before any production deployment. Each represents a specific data corruption scenario.

---

### Fix 1 — Call `SyncSDK.initialize()`

**Corruption scenario:** The entire sync infrastructure exists in DI but nothing activates it. Every write the user makes goes only to the server. When offline, writes fail silently. The local SQLite database is never populated. Sync queue never processes.

```dart
// lib/app.dart or main.dart — add to startup sequence:
await SyncSDK.initialize(
  SyncSdkConfig(
    enabled: AppFeatures.offlineSync,
    mode: SyncMode.active,
    syncEnabled: true,
    wifiOnly: false,
    periodicIntervalSeconds: 43200, // 12 hours
  ),
  getIt,
);
```

---

### Fix 2 — Implement Persistent `SyncLock`

**Corruption scenario without this fix:**

```
t=0ms   Connectivity event fires → SyncController starts runPendingJobs()
t=50ms  Periodic timer fires     → SyncController starts runPendingJobs() again
t=100ms Both cycles read the same 30 jobs from the queue
t=200ms Both cycles send the same 30 HTTP requests to the server
t=300ms Both cycles call markJobSuccess() for the same 30 jobs
```

Result: 60 HTTP writes instead of 30. Without idempotency on the server: 60 server-side records created.

The current `_isRunning = true` flag in `SyncEngine` is in-memory. It resets on every app launch, cannot protect against two OS processes sharing the same database, and cannot detect a stale lock from a crash.

```dart
// lib/modules/sync/integration/sync_lock.dart
//
// Uses StorageService (core/platform/storage/) — NOT SharedPreferences directly.
// Key declared in PersistenceKeys (core/platform/storage/persistence_keys.dart).
// See Section 0.3 for full rationale and PersistenceKeys change.

class SyncLock {
  static const _ttl = Duration(minutes: 10);  // safe max for largest queue

  final StorageService _storage;  // ← injected via DI — no direct SharedPreferences
  SyncLock(this._storage);

  /// Returns true if lock was acquired.
  /// Returns false if an active lock is already held.
  Future<bool> acquire() async {
    final raw = await _storage.getString(PersistenceKeys.syncLockAcquiredAt);
    if (raw != null) {
      final age = DateTime.now().millisecondsSinceEpoch - (int.tryParse(raw) ?? 0);
      if (age < _ttl.inMilliseconds) {
        LogService.info('Sync lock held — skipping cycle', tag: 'SYNC');
        return false;
      }
      LogService.warning('Overriding stale sync lock (age: ${age}ms)', tag: 'SYNC');
    }
    await _storage.setString(
      PersistenceKeys.syncLockAcquiredAt,
      '${DateTime.now().millisecondsSinceEpoch}',
    );
    return true;
  }

  /// Must be called in a finally block — always.
  Future<void> release() =>
      _storage.remove(PersistenceKeys.syncLockAcquiredAt);

  /// Call at app startup to release locks left by previous crashes.
  Future<void> releaseIfStale() async {
    final raw = await _storage.getString(PersistenceKeys.syncLockAcquiredAt);
    if (raw == null) return;
    final age = DateTime.now().millisecondsSinceEpoch - (int.tryParse(raw) ?? 0);
    if (age >= _ttl.inMilliseconds) {
      LogService.warning('Releasing stale startup lock (age: ${age}ms)', tag: 'SYNC');
      await release();
    }
  }
}
```

**Use in `SyncSDK.initialize()`:**

```dart
await di<SyncLock>().releaseIfStale(); // before SyncController.init()
```

---

### Fix 3 — Implement Idempotency-Key on Every Write

**Corruption scenario without this fix:**

```
Client:  PUT /employees/uuid  → server receives, applies write, prepares 200 response
Network: TCP connection drops before 200 reaches client
Client:  receives timeout → treats as failure → retries
Server:  receives second request → applies write AGAIN
```

If the write is "add 1 to a counter" or "append to an array", the second application corrupts data. If the write is a record creation, a duplicate record is created.

**Key format:**

```dart
// Deterministic — same job always produces same key.
// Do NOT include retryCount — key must be stable across retries.
String buildIdempotencyKey(SyncQueueJob job) =>
  '${job.entityName}_${job.entityId}_${job.type.name}_${job.createdAt}';
```

**Required schema change:**

```sql
-- v3 migration:
ALTER TABLE sync_queue ADD COLUMN idempotency_key TEXT NULL;
-- Populate on insert: idempotency_key = entity_name + '_' + entity_id + '_' + type + '_' + created_at
```

**Required change in every SyncExecutor:**

```dart
@override
Future<Either<Failure, SyncExecutionResult>> execute(
  SyncQueueJob job,
  int contractVersion,
) async {
  final opts = Options(headers: {'Idempotency-Key': job.idempotencyKey});
  return handle(() => _api.createEmployee(payload, options: opts));
}
```

---

### Fix 4 — Handle HTTP 409 — Never Retry Conflicts

**Corruption scenario without this fix:**

```
Engine sends: PATCH /employees/uuid  (client version: 3)
Server returns: HTTP 409 — server has version 5
Engine: sees failure → retries (backoff 2s, 4s, 8s, 16s, 32s)
Each retry: same 409 response
After 5 retries: entity marked 'failed'
Result: user's change is silently discarded. No notification. No recovery.
```

**Required change in `DioFailureMapper`:**

```dart
if (response.statusCode == 409) {
  final body = response.data as Map<String, dynamic>?;
  return ConflictFailure(
    serverVersion: body?['server_version'] as Map<String, dynamic>?,
    clientVersion: body?['client_version'] as Map<String, dynamic>?,
  );
}
```

**Required change in `SyncEngine` — Left(failure) branch:**

```dart
final failure = result.left;
if (failure is ConflictFailure) {
  // NEVER retry a conflict — invoke the resolver instead
  await _conflictResolver.resolve(
    job: job,
    serverVersion: failure.serverVersion,
    strategy: _contractFor(job.entityName)?.conflictStrategy
               ?? SyncConflictStrategy.serverWins,
  );
  continue; // do not fall through to retry logic
}
// All other failures: backoff + retry
```

---

### Fix 5 — Enforce Push-Before-Pull

**Corruption scenario without this fix:**

```
Local queue contains: update employee.name = "Ahmad"
Pull executes first, downloads: employee.name = "Mohammed" (server's current state)
Pull writes to SQLite: employee.name = "Mohammed"
Push executes: sends employee.name = "Ahmad" (from original payload)
Server has "Ahmad" — but local DB shows "Mohammed" until next sync
```

The symptom: user sees their change "disappear" immediately after saving, then "reappear" after the next sync. This is visible to the user and destroys trust.

**Required in `SyncEngine.runSyncCycle()`:**

```dart
// This ordering is enforced structurally — pull is never called
// until runPendingJobs() returns without exception.
await runPendingJobs();          // PUSH — must complete first
await resolveConflictedEntities(); // CONFLICTS — before pulling their state
await deltaDownload(since: ...);  // PULL — only after push is clean
```

---

## 4. Sync Lifecycle

### 4.1 Complete Flow with Failure Handling per Step

```
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: Acquire Lock                                        │
│                                                             │
│  await syncLock.acquire()                                   │
│  → returns false: another cycle running → exit              │
│  → stale lock (> 10 min): override → continue               │
│  → acquired: proceed                                        │
└─────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Push Queue (UPLOAD)                                 │
│                                                             │
│  await runPendingJobs()                                     │
│  Process jobs: ordered by priority ASC, created_at ASC      │
│                                                             │
│  Per job:                                                   │
│    HTTP 2xx:  markJobSuccess() → entity: synced             │
│    HTTP 409:  ConflictResolver (NOT retry) → see Step 3     │
│    HTTP 4xx:  if max_retries exceeded → entity: failed      │
│              else → markJobRetry(backoff.next())             │
│    Network:  markJobRetry(backoff.next()) — idempotent       │
│    No executor: markJobRetry(error: 'no executor')          │
└─────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: Resolve Conflicts                                   │
│                                                             │
│  await resolveConflictedEntities()                          │
│  For each entity with sync_state = 'conflicted':            │
│    apply strategy (serverWins / clientWins / manual)        │
│    → serverWins: upsert server version, mark synced         │
│    → clientWins: re-push with force flag                    │
│    → manual: emit ConflictEvent, await user resolution      │
└─────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: Pull Delta (DOWNLOAD)                               │
│                                                             │
│  since = timestamps.lastSuccessfulDownloadAt ?? epoch       │
│  await deltaDownload(since: since)                          │
│                                                             │
│  GET /resource?updated_since={since}&include_deleted=true   │
│    &cursor={cursor}&limit=500                               │
│                                                             │
│  Per page:                                                  │
│    db.transaction → entityStore.batchUpsert(records)        │
│    checkpoints.save(cursor)  ← resume on crash              │
│    if hasMore: fetch next page                              │
│                                                             │
│  On network failure: stop, do NOT update cursor             │
│  On completion: checkpoints.clear()                         │
└─────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 5: Update Sync Cursor                                  │
│                                                             │
│  ONLY written after successful download completion.          │
│  If written on partial download: missed records are         │
│  never re-fetched — silent data loss.                       │
│                                                             │
│  await timestamps.saveLastSuccessfulDownloadAt(now)         │
└─────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 6: Release Lock (ALWAYS — even on exception)          │
│                                                             │
│  } finally {                                                │
│    await syncLock.release();                                │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Full Pseudocode

```dart
Future<void> runSyncCycle() async {
  final locked = await syncLock.acquire();
  if (!locked) return;

  try {
    _metrics.recordCycleStart();

    await runPendingJobs();
    await resolveConflictedEntities();

    final since = await _timestamps.lastSuccessfulDownloadAt;
    await deltaDownload(since: since);
    await _timestamps.saveLastSuccessfulDownloadAt(DateTime.now().toUtc());

    _metrics.recordCycleSuccess();

  } on SyncAbortException {
    _metrics.recordCycleCancelled();
    LogService.info('Sync cycle cancelled intentionally', tag: 'SYNC');
    // Do NOT update cursor — will re-run from previous position
  } catch (e, st) {
    _metrics.recordCycleFailure(e.toString());
    LogService.error('Sync cycle failed', tag: 'SYNC', error: e, stackTrace: st);
    // Do NOT update cursor
    await scheduleBackoffRetry();
  } finally {
    await syncLock.release();
  }
}
```

### 4.3 Bootstrap (First Run)

```dart
Future<void> runBootstrap() async {
  final locked = await syncLock.acquire();
  if (!locked) return;

  try {
    // Fetch all entities in parallel (max 2 concurrent)
    await Future.wait(
      _contractRegistry.entityNames.map(_bootstrapEntity),
      eagerError: false,      // one entity failure does not abort others
    );
    await _timestamps.saveLastFullBootstrapAt(DateTime.now().toUtc());
  } finally {
    await syncLock.release();
  }
}

Future<void> _bootstrapEntity(String entityName) async {
  String? cursor = await _checkpoints.getCursor(entityName);

  do {
    if (_isCancelled) {
      await _checkpoints.saveCursor(entityName, cursor); // resume on restart
      return;
    }

    final page = await _api.getPage(entityName, cursor: cursor, limit: 500);

    await _db.transaction(() async {
      for (final record in page.data) {
        await _entityStore.upsert(record.toSyncEntityRecord());
      }
    });

    cursor = page.nextCursor;
    _progressStream.add(BootstrapProgress(entityName, page.hasMore));
  } while (page.hasMore);

  await _checkpoints.clearCursor(entityName);
}
```

---

## 5. Queue System Design

### 5.1 Schema (v3 — Required)

```sql
CREATE TABLE sync_queue (
  job_id            TEXT PRIMARY KEY,
  type              TEXT NOT NULL,         -- create | update | delete
  entity_name       TEXT NOT NULL,         -- matches SyncFeatureContract.entityName
  entity_id         TEXT NOT NULL,         -- synced_entities.local_id
  payload_json      TEXT NOT NULL,         -- validated by SyncContractValidator
  contract_version  INTEGER NOT NULL DEFAULT 1,
  idempotency_key   TEXT NOT NULL,         -- ⚠️ MISSING IN v2 — ADD IN v3 MIGRATION
  priority          INTEGER NOT NULL DEFAULT 50,  -- 10=CRUD, 50=relations, 90=files
  retry_count       INTEGER NOT NULL DEFAULT 0,
  max_retries       INTEGER NOT NULL DEFAULT 5,
  next_retry_at     INTEGER NOT NULL,      -- ms epoch
  created_at        INTEGER NOT NULL,      -- ms epoch — FIFO ordering basis
  last_error        TEXT NULL
);

-- Processing order: priority first, then FIFO within same priority:
CREATE INDEX idx_queue_processing
  ON sync_queue(priority ASC, next_retry_at ASC, created_at ASC);

-- Coalescing lookup:
CREATE INDEX idx_queue_entity
  ON sync_queue(entity_name, entity_id);
```

### 5.2 Coalescing Rules

When a new job arrives for an entity that already has a queued job, they are merged:

| Queued | Incoming | Result | Reason |
|--------|----------|--------|--------|
| `create` | `update` | `create` (latest payload) | Entity not on server yet — no point updating |
| `create` | `delete` | `delete` | Net result: entity never existed on server |
| `update` | `update` | `update` (latest payload) | Only latest state matters |
| `update` | `delete` | `delete` | Latest intent is deletion |
| `delete` | `create` | `create` | User deleted then recreated — treat as new |
| `delete` | `update` | `delete` | Cannot update a deleted entity |

### 5.3 Priority Levels

| Value | Priority | Job Types | Reason |
|-------|----------|-----------|--------|
| `10` | High | Entity CRUD (create/update/delete) | User-visible, must sync first |
| `50` | Medium | Relation changes (many-to-many) | Depends on entity existence |
| `90` | Low | Large file uploads | Can defer — no immediate UX impact |

### 5.4 Retry Schedule

```
nextRetryAtMs = nowMs + min(2^retryCount × baseDelaySeconds, maxDelaySeconds) × 1000
```

| Attempt | With base=2s | Delay | Queue state after |
|---------|-------------|-------|-------------------|
| 1 | 2s | 2s | pending — retrying |
| 2 | 2s | 4s | pending — retrying |
| 3 | 2s | 8s | pending — retrying |
| 4 | 2s | 16s | pending — retrying |
| 5 (max) | 2s | 32s | → `failed` after this |

After `max_retries`: entity → `failed`. No automatic retry. Requires manual intervention or full re-bootstrap.

### 5.5 Dead-Letter Handling

When a job reaches `failed` state:

```dart
// Options, configured per entity in SyncFeatureContractBase:
enum DeadLetterStrategy {
  markFailed,     // default — mark entity failed, notify user
  silentDrop,     // analytics events, logs — okay to lose
  escalate,       // emit event to crash reporting for manual review
}
```

Jobs in `failed` state are preserved in the queue until either:
- User manually triggers a retry from the conflict UI
- A full re-bootstrap wipes and repopulates all data

### 5.6 Operation Log (MANDATORY)

**Why mandatory:**

When an entity is stuck in `failed` or `conflicted` state in production, you need to answer:
- What operations were attempted?
- In what order did they execute?
- What exact errors occurred?
- Can we replay from a known-good point?

Without an operation log, these questions are unanswerable. Production debugging becomes guesswork.

```sql
CREATE TABLE sync_operations_log (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_name   TEXT NOT NULL,
  entity_id     TEXT NOT NULL,
  job_id        TEXT NULL,                    -- links to sync_queue.job_id
  operation     TEXT NOT NULL,
  -- push_queued | push_attempt | push_success | push_failure |
  -- conflict_detected | conflict_resolved |
  -- pull_received | pull_upserted |
  -- rollback
  occurred_at   INTEGER NOT NULL,             -- ms epoch
  server_id     TEXT NULL,
  error_code    TEXT NULL,
  error_detail  TEXT NULL,
  payload_snapshot TEXT NULL                  -- compact, no large files
);

CREATE INDEX idx_ops_log_entity
  ON sync_operations_log(entity_name, entity_id, occurred_at DESC);

CREATE INDEX idx_ops_log_time
  ON sync_operations_log(occurred_at DESC);
```

**Retention policy:** Last 1000 entries per entity. Entries older than 30 days deleted on startup.

**How to use for debugging:**

```sql
-- Reconstruct what happened to a specific entity:
SELECT operation, occurred_at, error_code, error_detail
FROM sync_operations_log
WHERE entity_name = 'employees' AND entity_id = 'uuid-here'
ORDER BY occurred_at DESC
LIMIT 50;

-- Find all entities that failed in the last 24 hours:
SELECT DISTINCT entity_name, entity_id, error_code
FROM sync_operations_log
WHERE operation = 'push_failure'
  AND occurred_at > (strftime('%s', 'now') - 86400) * 1000
ORDER BY occurred_at DESC;
```

**How to replay:**

```dart
// Re-enqueue all failed jobs for a specific entity:
Future<void> replayFailedJobs(String entityName, String entityId) async {
  final logs = await _opsLog.getJobIds(
    entityName: entityName, entityId: entityId,
    operations: ['push_failure'],
    since: DateTime.now().subtract(const Duration(hours: 24)),
  );
  // Re-queue with reset retry_count = 0
  for (final log in logs) {
    if (log.jobId != null) {
      await _queueRepository.resetJobForRetry(log.jobId!);
    }
  }
}
```

---

## 6. Conflict Resolution System

### 6.1 Why 409 Is Not a Failure

An HTTP 409 means the server received and understood the request but **rejected it because of a state mismatch** — not because of a network problem or server error. Retrying the same request will always produce the same 409. Treating it as a transient failure and retrying is the single most common source of "stuck entities" in offline-first systems.

### 6.2 Conflict Types

| Type | Trigger | Example |
|------|---------|---------|
| **Version conflict** | Client sends `version: 3`, server has `version: 5` | Two devices edited the same employee |
| **Delete conflict** | Client tries to update an entity the server already deleted | Entity deleted by admin while user was editing offline |
| **Relation conflict** | Client adds relation to an entity that no longer exists | Employee assigned to a mosque that was deleted |

### 6.3 Pluggable Strategies

Declared per entity in `SyncFeatureContractBase`:

```dart
abstract class SyncFeatureContractBase {
  // ... existing fields ...

  /// Conflict resolution strategy for this entity type.
  /// Override in feature contracts where server authority is not appropriate.
  SyncConflictStrategy get conflictStrategy => SyncConflictStrategy.serverWins;
}
```

| Strategy | Behavior | Appropriate For |
|----------|----------|-----------------|
| `serverWins` | Discard local change, store server version | Default. Server is authoritative (shared data). |
| `clientWins` | Re-push local version with version override | Client owns this data (local settings, preferences). |
| `lastWriteWins` | Compare `updated_at`; newer version wins | Peer data — neither is more authoritative. |
| `merge` | Apply a custom merge function per field | Rich documents with independent field ownership. |
| `manual` | Mark as `conflicted`, emit event, await user | High-stakes data requiring human decision. |

### 6.4 Resolution Flow

```dart
// In SyncConflictResolver:
Future<void> resolve({
  required SyncQueueJob job,
  required Map<String, dynamic>? serverVersion,
  required SyncConflictStrategy strategy,
}) async {
  switch (strategy) {

    case SyncConflictStrategy.serverWins:
      if (serverVersion != null) {
        await _entityStore.upsert(
          SyncEntityRecord.fromServerJson(job.entityName, serverVersion),
        );
      }
      // Discard the local job — it's been superseded
      await _queueRepository.markJobSuccess(jobId: job.jobId);
      await _opsLog.record(
        entityName: job.entityName, entityId: job.entityId,
        operation: 'conflict_resolved', detail: 'serverWins',
      );
      break;

    case SyncConflictStrategy.clientWins:
      // Re-push with a force header — backend must support this
      await _queueRepository.resetJobForRetry(
        job.jobId,
        additionalHeaders: {'X-Force-Override': 'true'},
      );
      break;

    case SyncConflictStrategy.manual:
      await _entityStore.setSyncState(job.entityId, SyncState.conflicted);
      await _queueRepository.markJobSuccess(jobId: job.jobId); // remove from retry
      _conflictEventBus.emit(ConflictDetected(
        entityName: job.entityName,
        entityId: job.entityId,
        serverVersion: serverVersion,
        clientPayload: job.payloadJson,
      ));
      break;
  }
}
```

### 6.5 Required HTTP 409 Response Format

The 409 body must include three top-level keys. Without `conflict_fields`, the client cannot implement `merge` strategy — it does not know which fields are in dispute.

```json
HTTP/1.1 409 Conflict
Content-Type: application/json

{
  "error": "conflict",
  "conflict_type": "version_mismatch",

  "conflict_fields": ["name", "role_id"],

  "server_version": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "version": 5,
    "updated_at": "2024-01-15T09:30:00.000Z",
    "name": "Ahmad Al-Mansouri",
    "role_id": "role-admin"
  },

  "client_version": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "version": 3,
    "updated_at": "2024-01-15T09:28:00.000Z",
    "name": "Mohammed Al-Mansouri",
    "role_id": "role-editor"
  }
}
```

**`conflict_fields` rules:**

- Must list **only the fields that differ** between `server_version` and `client_version`.
- Used by the `merge` strategy to apply non-conflicting fields from the client and conflicting fields from the server (or queue for manual review).
- Used by the UI to display a per-field conflict resolution screen.
- If backend cannot compute `conflict_fields`, it must return all mutable fields. Returning an empty array is forbidden — it disables field-level merge.

**`conflict_type` values:**

| Value | Meaning |
|-------|---------|
| `version_mismatch` | Client sent outdated `version` |
| `deleted_conflict` | Entity was soft-deleted on server |
| `relation_conflict` | A foreign key referenced by client no longer exists |

---

## 7. Data Model Contract

Every entity synchronized through this system — without exception — must include these fields.

### 7.1 Required Fields

| Field | Type | Required | Why |
|-------|------|----------|-----|
| `id` | UUID string | Yes | **Stable identity across devices.** Auto-increment integers are device-local. UUIDs enable client-side creation without a server roundtrip. |
| `created_at` | ISO 8601 UTC | Yes | **Bootstrap ordering and debugging.** Without creation timestamp, impossible to determine if a record predates or postdates the last sync. |
| `updated_at` | ISO 8601 UTC | Yes | **Delta sync cursor.** This is the clock for "what changed since X." Must be updated on every server-side write — including soft deletes. |
| `is_deleted` | boolean | Yes | **Soft delete.** Hard deletion makes delta sync impossible — the client can never discover a deletion. Server must set `is_deleted: true, updated_at: now`. The client must propagate this to local DB. |
| `version` | integer | Strongly recommended | **Conflict detection.** Without version, the only conflict signal is `updated_at` — which has millisecond resolution and can collide. Version is monotonically increasing and unambiguous. |

### 7.2 Why Hard Deletion Is Forbidden

If the backend hard-deletes a record after it has been synced to clients:

1. Client's local DB still has the record (no notification received)
2. Delta sync: `GET /employees?updated_since=T` — deleted records not included
3. Client's local DB retains the ghost record indefinitely
4. User sees data that no longer exists on the server
5. Any subsequent write attempts fail with 404

**The fix:** Backend sets `is_deleted: true, updated_at: now` and includes the record in delta responses. Client detects `is_deleted: true` and marks it locally.

### 7.3 `synced_entities` Table (v3)

```sql
CREATE TABLE synced_entities (
  local_id       TEXT PRIMARY KEY,
  entity_name    TEXT NOT NULL,
  server_id      TEXT NULL,
  data_json      TEXT NOT NULL,
  updated_at     INTEGER NOT NULL,        -- ms epoch
  version        INTEGER NOT NULL DEFAULT 1,
  sync_state     TEXT NOT NULL DEFAULT 'synced',
  -- pending_create | pending_update | pending_delete | synced | conflicted | failed
  last_synced_at INTEGER NULL,            -- ms epoch — when server last acknowledged
  local_version  INTEGER NOT NULL DEFAULT 1, -- incremented on every local mutation
  is_deleted     INTEGER NOT NULL DEFAULT 0,
  priority       INTEGER NOT NULL DEFAULT 50,
  last_error     TEXT NULL
);

CREATE INDEX idx_entities_name_updated  ON synced_entities(entity_name, updated_at DESC);
CREATE INDEX idx_entities_name_server   ON synced_entities(entity_name, server_id);
CREATE INDEX idx_entities_pending       ON synced_entities(sync_state)
  WHERE sync_state NOT IN ('synced', 'failed');
```

---

## 8. Backend API Contract

### 8.1 Client-Driven Principle

The backend must be shaped around what the **client needs for safe offline operation** — not what is convenient to implement on the server. Every API design decision must be evaluated against: "Does this enable deterministic sync with idempotency?"

### 8.2 Required Endpoints

| Method | Endpoint | Required | Purpose |
|--------|----------|----------|---------|
| `GET` | `/resource?updated_since=ISO&include_deleted=true&cursor=X&limit=500` | **Mandatory** | Delta sync |
| `GET` | `/resource/meta` | **Mandatory** | `{total_count}` for bootstrap progress |
| `POST` | `/resource` | **Mandatory** | Single create |
| `PATCH` | `/resource/{id}` | **Mandatory** | Single update |
| `DELETE` | `/resource/{id}` | **Mandatory** | Soft delete (sets `is_deleted: true`) |
| `POST` | `/resource/bulk` | Strongly recommended | Batch create — reduces round trips |
| `PATCH` | `/resource/bulk` | Strongly recommended | Batch update — must be atomic (all or nothing) |
| `POST` | `/upload/chunk` | For file entities | Per-chunk upload with resume |
| `POST` | `/upload/finalize` | For file entities | Complete chunked session |

### 8.3 Delta Sync Query

```
GET /employees?updated_since=2024-01-15T08:00:00.000Z&include_deleted=true&cursor=eyJpZCI6IjEwMCJ9&limit=500
```

**Why `include_deleted=true` is mandatory:**

Without it, soft-deleted records are never returned in delta queries. The client never learns about deletions and retains ghost records forever.

**Response format:**

```json
{
  "data": [...],
  "next_cursor": "eyJpZCI6IjYwMCJ9",
  "has_more": true,
  "total_count": 2847
}
```

### 8.4 Cursor-Based vs Page-Based Pagination

**Page-based (`?page=N`) is forbidden for large datasets:**

| Problem | Impact |
|---------|--------|
| New records inserted between pages → records skipped | Bootstrap misses recently-created entities |
| Deleted records → records appear on two pages | Duplicate entities in SQLite |
| `COUNT(*)` required for total_pages | O(n) server overhead at scale |
| No stable resume point after crash | Bootstrap must restart from page 1 |

**Cursor-based is required:**

```
GET /employees?cursor=&limit=500
Response: { data: [...], next_cursor: "eyJpZCI6IjUwMCJ9", has_more: true }

GET /employees?cursor=eyJpZCI6IjUwMCJ9&limit=500
Response: { data: [...], next_cursor: "eyJpZCI6IjEwMCJ9", has_more: false }
```

The cursor encodes the last seen record (typically by `id` or `updated_at + id` for delta queries). Stable under concurrent insertions and deletions.

### 8.5 Idempotency Header

```
POST /employees
Idempotency-Key: employees_uuid_create_1705312200000
Content-Type: application/json
```

**Backend behavior:**
1. First receipt: process write, store `(key → {status, response})` in `idempotency_keys` table
2. Duplicate receipt (same key): return stored response without re-processing
3. Key TTL: minimum 24 hours, recommended 72 hours

### 8.6 Sparse Field Selection (Performance Optimization)

Delta sync queries often only need a subset of fields to update local state:

```
GET /employees?updated_since=ISO&fields=id,name,updated_at,is_deleted
```

**Impact:** An employee record with embedded profile images in `data_json` could be 50 KB. With field selection, the delta query returns ~200 bytes per record. At 10,000 changed records, this is 500 MB vs 2 GB.

### 8.7 Bulk Endpoint Requirements

```json
POST /employees/bulk
[
  { "id": "uuid-1", "name": "Ahmad", ... },
  { "id": "uuid-2", "name": "Fatimah", ... }
]

Response 201:
[
  { "id": "uuid-1", "server_id": "srv-1", "version": 1, ... },
  { "id": "uuid-2", "server_id": "srv-2", "version": 1, ... }
]
```

**Atomicity requirement:** Bulk endpoints must be all-or-nothing. If 3 of 10 records fail validation, the entire batch is rejected with details. Partial success is indistinguishable from failure on the client side without per-record tracking.

---

## 9. Large Data Strategy

### 9.1 Storage Separation

| Data Type | Storage | Notes |
|-----------|---------|-------|
| Structured records | SQLite `synced_entities` | Queryable, indexed, transactional |
| Files > 200 KB | Application Documents Directory | SQLite BLOB degrades above 200 KB |
| File metadata | SQLite `data_json` | `{file_path, file_size_bytes, checksum, mime_type}` |

**File deletion rule — order matters:**

```dart
// 1. Mark entity deleted in SQLite first (sync_state: pending_delete)
// 2. Queue the delete job
// 3. Only delete the physical file AFTER server confirms deletion (2xx)
// Reason: if you delete the file first and the job fails, the file is gone
//         but the entity still points to it — broken reference.
```

### 9.2 Download — Bootstrap

```dart
Future<void> bootstrapEntity(String entityName) async {
  String? cursor = await _checkpoints.getCursor(entityName);

  do {
    if (_isCancelled) {
      await _checkpoints.saveCursor(entityName, cursor);
      return;                    // next launch resumes from this cursor
    }

    final page = await _api.getPage(entityName, cursor: cursor, limit: 500);

    // Single transaction per page — reduces SQLite write amplification
    await _db.transaction(() async {
      for (final r in page.data) {
        await _entityStore.upsert(r.toSyncEntityRecord());
        await _opsLog.record(entityName, r.id, 'pull_received');
      }
    });

    cursor = page.nextCursor;
    _progressStream.add(BootstrapProgress(entityName: entityName, cursor: cursor));
  } while (page.hasMore);

  await _checkpoints.clearCursor(entityName);
  await _timestamps.saveLastFullBootstrap(entityName, DateTime.now().toUtc());
}

// Parallel execution with concurrency limit:
// eagerError: false prevents one entity failure from cancelling others
await Future.wait(
  _contracts.entityNames.map(bootstrapEntity),
  eagerError: false,
);
```

### 9.3 Upload — Chunked Files

```dart
Future<void> uploadLargeFile({required String localPath, required String jobId}) async {
  final sessionId = 'upload_${jobId}';
  final chunks = await FileChunker.split(File(localPath), 5 * 1024 * 1024);

  // Resume from last completed chunk:
  final startChunk = await _checkpoints.getChunkProgress(sessionId) ?? 0;

  for (var i = startChunk; i < chunks.length; i++) {
    await _api.uploadChunk(
      sessionId: sessionId,
      chunkIndex: i,
      totalChunks: chunks.length,
      data: chunks[i],
      idempotencyKey: '${sessionId}_chunk_$i',  // per-chunk idempotency
    );
    await _checkpoints.saveChunkProgress(sessionId, i + 1);
  }

  await _api.finalizeUpload(sessionId);
  await _checkpoints.clearChunkProgress(sessionId);
}
```

### 9.4 Required Indexes

```sql
-- Without these, queries on 100K+ records will cause ANRs:

CREATE INDEX idx_entities_name_updated  ON synced_entities(entity_name, updated_at DESC);
CREATE INDEX idx_entities_name_server   ON synced_entities(entity_name, server_id);
CREATE INDEX idx_entities_pending       ON synced_entities(sync_state)
  WHERE sync_state NOT IN ('synced', 'failed');
CREATE INDEX idx_queue_processing       ON sync_queue(priority ASC, next_retry_at ASC, created_at ASC);
CREATE INDEX idx_queue_entity           ON sync_queue(entity_name, entity_id);
CREATE INDEX idx_ops_log_entity         ON sync_operations_log(entity_name, entity_id, occurred_at DESC);
```

---

## 10. Relationships — Many-to-Many

### 10.1 Fundamental Rule

**The server must never return joined data. The client must never request it.**

This rule is not a performance suggestion — it is an architectural requirement. Joined responses make independent delta sync impossible.

**Forbidden:**

```
GET /employees?include=mosques
→ { id, name, mosques: [{id, name}, ...] }
```

You cannot delta-sync this. If a mosque assignment changes, what `updated_at` do you query? The employee's? The mosque's? The assignment's? The answer is ambiguous.

**Required:**

```
GET /mosques?updated_since=ISO          → flat mosque records
GET /employees?updated_since=ISO        → flat employee records
GET /employee-mosques?updated_since=ISO → flat assignment records
```

Each endpoint is independently delta-syncable.

### 10.2 Required Schema for Relation Tables

Every relation table on both backend and local DB:

```sql
-- On the backend:
CREATE TABLE employee_mosques (
  id          UUID PRIMARY KEY,
  employee_id UUID NOT NULL REFERENCES employees(id),
  mosque_id   UUID NOT NULL REFERENCES mosques(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_deleted  BOOLEAN NOT NULL DEFAULT FALSE
);

-- updated_at must be indexed for delta sync:
CREATE INDEX ON employee_mosques(updated_at DESC);
```

The `id` field enables idempotent operations on the relationship itself. Without it, there is no stable way to update or delete a specific assignment.

### 10.3 Local Join Execution

```sql
-- All joins happen locally in SQLite:
SELECT
  json_extract(e.data_json, '$.name') AS employee_name,
  json_extract(m.data_json, '$.name') AS mosque_name,
  json_extract(em.data_json, '$.role') AS role
FROM synced_entities em
JOIN synced_entities e
  ON e.entity_name = 'employees'
  AND e.server_id = json_extract(em.data_json, '$.employee_id')
  AND e.is_deleted = 0
JOIN synced_entities m
  ON m.entity_name = 'mosques'
  AND m.server_id = json_extract(em.data_json, '$.mosque_id')
  AND m.is_deleted = 0
WHERE em.entity_name = 'employee_mosques'
  AND em.is_deleted = 0;
```

---

## 11. Offline UX

### 11.1 Why UX Is a Correctness Concern

In offline-first systems, the UX is not polish — it is part of the correctness contract. Users who do not know their changes are pending may close the app before the sync completes. Users who do not know they are offline may make contradictory changes on multiple devices. Users who do not know a conflict exists will never resolve it.

**An offline system with no offline UI is a data corruption risk.**

### 11.2 UI State Definitions

| State | Condition | Visual | Dismissible |
|-------|-----------|--------|-------------|
| `hidden` | Offline < 10s | None | — |
| `subtle` | Offline 10–30s | Small red dot (top-right) | No |
| `banner` | Offline > 30s | Full-width warning strip | No |
| `reconnecting` | Network restored, probing | Animated chip with countdown | No |
| `syncing` | Sync cycle running | Progress dialog | No — never |
| `pending` | Queue has unsynced jobs | Chip count on affected items | Tappable |
| `conflict` | Entity in `conflicted` state | Item-level warning badge | Yes (requires action) |
| `failed` | Entity in `failed` state | Item-level error badge | Yes (retry action) |
| `sync_complete` | Cycle finished successfully | Transient toast (2s) | Auto |

### 11.3 OfflineUxCubit — Architecture

The UI layer must be **strictly decoupled from the SyncEngine**. The cubit must not import anything from `engine/` or `data/`.

**Location:** `lib/presentation/shared/sync/offline_ux_cubit.dart` ← correct (Flutter dependency, cannot be in `modules/`)

```dart
class OfflineUxCubit extends Cubit<OfflineUxState> {
  // All inputs are signal methods — not direct state reads

  void onConnectionLost()            // ← ConnectivityCubit
  void onConnectionRestored()        // ← ConnectivityCubit
  void onStabilityConfirmed()        // ← NetworkStabilityProbe result
  void onSyncStarted()               // ← SyncManagerCubit
  void onSyncCompleted()             // ← SyncManagerCubit
  void onSyncFailed(String reason)   // ← SyncManagerCubit
  void onConflictDetected(String entityName, String entityId) // ← ConflictEventBus
}
```

**Failure handling follows template convention (core-architecture.mdc):**

```dart
// When a sync failure propagates through SyncManagerCubit to OfflineUxCubit:
void onFailure(Failure failure) {
  switch (FailureUiMapper.toAction(failure)) {
    case ShowError(:final message):
      emit(state.copyWith(phase: OfflineUxPhase.failed, errorMessage: message));
    case NavigateToLogin():
      // Session expired mid-sync — auth interceptor already fired
      // OfflineUxCubit resets silently; AuthEventBus handles navigation
      emit(OfflineUxState.initial());
    case Silent():
      // ConflictFailure → handled by SyncConflictResolver, not shown as error
      break;
  }
}
```

### 11.4 Pending Changes Indicator

```dart
// Show pending count badge on entity list screens:
StreamBuilder<int>(
  stream: entityStore.watchPendingCount(entityName: 'employees'),
  builder: (context, snapshot) {
    final count = snapshot.data ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Chip(
      label: Text(LocaleKeys.pendingChanges.tr(args: ['$count'])),
      backgroundColor: context.colors.statusWarningBg,
    );
  },
)
```

### 11.5 Optimistic UI Contract

```
User taps "Save" (offline or slow network)
    ↓
1. SyncWriteGateway.write(enqueue: true)
   → SQLite: entity updated, sync_state = pending_update
   → sync_queue: job inserted
    ↓
2. UI reads from SQLite immediately — shows updated data, no spinner
    ↓
3. Background: job processes when online
    ↓
4a. Success: sync_state → synced
    UI: silent update (no flicker, no reload)
    ↓
4b. Failure (max retries): rollback SQLite to previous snapshot
    UI: error notification with retry button
```

**The snapshot must be saved before the write:**

```dart
// In SyncWriteGateway.write():
final previousSnapshot = await entityStore.getRecord(command.entityId);
// ... perform write ...
// On rollback (if job reaches failed state):
await entityStore.upsert(previousSnapshot);
await conflictBus.emit(RollbackNotification(entityId: command.entityId));
```

---

## 12. Orchestrator — SyncManagerCubit

### 12.1 Layer Placement — Critical

`SyncManagerCubit` MUST live in `lib/presentation/shared/sync/sync_manager_cubit.dart` — NOT in `modules/sync/`.

**Why:** `Cubit` is from `flutter_bloc`, a Flutter dependency. Template rule (`.cursor/rules/core-architecture.mdc`):
```
modules → foundation + infra only ✅
modules → Flutter packages        ❌ NEVER
```

`OfflineUxCubit` is correctly placed in `presentation/shared/sync/offline_ux_cubit.dart`. `SyncManagerCubit` must be in the same folder.

```
lib/presentation/shared/sync/
├── sync_manager_cubit.dart   ← orchestrator (feeds SyncEngine + OfflineUxCubit)
├── sync_manager_state.dart
├── offline_ux_cubit.dart     ← UI phase controller
└── offline_ux_state.dart
```

`SyncController` (in `modules/`) remains valid — it has no Flutter dependencies (uses `ConnectivityService` interface). It delegates to `SyncManagerCubit` via a callback/event mechanism, not a direct import.

### 12.2 Why a Separate Orchestrator Is Required

`SyncController` (current implementation) handles only trigger decisions: "should I start a sync now?" It does not:

- Track offline duration for UX phase transitions
- Probe network stability before triggering sync
- Debounce rapid reconnection events (flappy networks)
- Manage reconnect countdown for the user
- Communicate sync progress to the UI layer

`SyncManagerCubit` fills this gap. It is the bridge between infrastructure events (connectivity, stability, timer) and both the engine (start/stop sync) and the UI layer (phase transitions).

### 12.3 State Model

```dart
class SyncManagerState {
  final SyncLifecyclePhase phase;
  final int offlineDurationMs;     // used to drive OfflineUxPhase
  final int? reconnectCountdownMs; // shown in ReconnectCountdownChip
  final bool isSyncing;
  final String? lastError;
  final int pendingJobCount;

  OfflineUxPhase get offlineUxPhase {
    if (offlineDurationMs < 10000) return OfflineUxPhase.hidden;
    if (offlineDurationMs < 30000) return OfflineUxPhase.subtle;
    return OfflineUxPhase.banner;
  }
}

enum SyncLifecyclePhase {
  idle,
  waitingForStability,
  reconnectCountdown,
  syncing,
  failed,
}
```

### 12.4 Reconnect Pipeline

```dart
// SyncManagerCubit — in lib/presentation/shared/sync/sync_manager_cubit.dart
//
// ConnectivityService is injected from core/platform/connectivity/.
// Never import connectivity_plus directly — use the template's abstraction.

// On link restored:
Future<void> onLinkRestored() async {
  // 1. Debounce — ignore flappy reconnections
  await Future.delayed(SyncPolicy.reconnectDebounceDuration); // 5s
  if (!await _connectivityService.hasConnection) return; // gone again

  // 2. Stability probe — real internet, not captive portal
  emit(state.copyWith(phase: SyncLifecyclePhase.waitingForStability));
  final stable = await NetworkStabilityProbe.verifyStableConnection();
  if (!stable) {
    // Schedule retry after stability delay
    await Future.delayed(SyncPolicy.stabilityRetryDelay);
    return onLinkRestored();
  }

  // 3. Countdown (UX — gives user awareness)
  emit(state.copyWith(
    phase: SyncLifecyclePhase.reconnectCountdown,
    reconnectCountdownMs: SyncPolicy.postStabilityDelay.inMilliseconds,
  ));
  await Future.delayed(SyncPolicy.postStabilityDelay); // 2s

  // 4. Trigger sync
  emit(state.copyWith(phase: SyncLifecyclePhase.syncing, isSyncing: true));
  try {
    await _syncEngine.runSyncCycle();
    emit(state.copyWith(phase: SyncLifecyclePhase.idle, isSyncing: false));
  } catch (e) {
    emit(state.copyWith(phase: SyncLifecyclePhase.failed, lastError: e.toString()));
    _offlineUxCubit.onSyncFailed(e.toString());
  }
}
```

### 12.5 SyncPolicy — Central Configuration

```dart
// lib/modules/sync/config/sync_policy.dart
abstract final class SyncPolicy {
  // Reconnect
  static const Duration reconnectDebounceDuration = Duration(seconds: 5);
  static const Duration postStabilityDelay        = Duration(seconds: 2);
  static const Duration stabilityRetryDelay       = Duration(seconds: 15);

  // Stability probe
  static const int      stabilityPingCount        = 3;
  static const Duration stabilityPingInterval     = Duration(seconds: 3);
  static const int      stabilityPingMinSuccesses  = 2;

  // Offline UX thresholds
  static const Duration offlineSilentMax           = Duration(seconds: 10);
  static const Duration offlineSubtleMax           = Duration(seconds: 30);

  // Backoff
  static const Duration backoffBase                = Duration(seconds: 2);
  static const Duration backoffMax                 = Duration(seconds: 120);

  // Cooldowns
  static const Duration reconnectDownloadCooldown  = Duration(minutes: 10);
  static const Duration backgroundPrefetchInterval = Duration(hours: 12);
  static const Duration syncSessionMaxDuration     = Duration(minutes: 12);
}
```

---

## 13. Failure Modes

### 13.1 Network Drop Mid-Request

**What happens:** Server processes write, sends 200. TCP ACK drops. Client sees timeout.

**Without fix:** Client retries → server processes twice → duplicate record or corrupted counter.

**With fix:** `Idempotency-Key` header. Server returns cached 200 on second request. Client marks job successful.

**Status:** ❌ Not implemented.

---

### 13.2 Request Succeeded, Client Unaware

This is identical to #1 but from a different cause (packet loss on response vs on ACK). The fix is the same: idempotency.

**Status:** ❌ Not implemented.

---

### 13.3 Duplicate Queue Jobs

**What happens:** User taps "Save" twice in rapid succession before first job completes.

**Without fix:** Two `create` jobs for same entity → two server-side records.

**With fix:** Coalescing logic in `sql_sync_queue_repository.dart` merges them.

**Status:** ✅ Implemented.

---

### 13.4 Out-of-Order Execution

**What happens:** `create` job is in backoff delay. `update` job becomes due first. Server receives `update` for entity that doesn't exist → 404.

**Current state:** FIFO by `created_at` reduces frequency but does not eliminate this for backoff scenarios.

**Required fix:** Per-entity ordering constraint:

```dart
// In getDueJobs() — exclude jobs for entities that have older pending creates:
WHERE job_id NOT IN (
  SELECT j2.job_id FROM sync_queue j2
  WHERE j2.entity_id = sync_queue.entity_id
    AND j2.type = 'create'
    AND j2.created_at < sync_queue.created_at
    AND j2.retry_count < j2.max_retries
)
```

**Status:** ⚠️ Partially mitigated. Fix required.

---

### 13.5 App Killed During Sync

**What happens:** Engine is mid-job. OS terminates process.

**State after kill:**
- Jobs not yet successful remain in `sync_queue` ✅
- `SyncLock` remains acquired in SharedPreferences

**Without lock fix:** Next launch — `SyncLock.releaseIfStale()` not called → sync never starts.

**With fix:** `releaseIfStale()` at startup releases locks older than 10 minutes.

**Status:** ✅ Queue recovery correct. ❌ Lock recovery not implemented.

---

### 13.6 Concurrent Sync Runs

**What happens:** Connectivity event + periodic timer fire simultaneously.

**Without fix:** Both cycles execute same jobs, cause duplicate server writes.

**In-memory `_isRunning` flag:** Prevents within same app lifecycle. Does not survive process restart.

**With fix:** Persistent `SyncLock` (Section 3, Fix 2).

**Status:** ⚠️ Partially mitigated.

---

### 13.7 HTTP 409 Conflict

**What happens:** Server rejects write because its version is newer.

**Without fix:** Job retried until `max_retries` → entity permanently `failed` → user's change silently discarded, no notification.

**With fix:** Detect `ConflictFailure`, invoke `SyncConflictResolver`, do NOT retry.

**Status:** ❌ Not handled.

---

### 13.8 Corrupted Local Database

**What happens:** Flash storage failure or abnormal write termination produces an invalid SQLite file.

**Without fix:** Every database operation throws `DatabaseException` → uncaught exception → app crash → repeat forever.

**With fix:**

```dart
// In SyncSDK.initialize(), first action:
final db = await syncDatabase.database;
final result = await db.rawQuery('PRAGMA integrity_check;');
if (result.first.values.first != 'ok') {
  await db.close();
  final dbPath = await _resolveDatabasePath();
  await File(dbPath).delete();
  await _timestamps.clearAll();
  await _checkpoints.clearAll();
  LogService.warning('SQLite database corrupted — wiped. Will re-bootstrap.', tag: 'SYNC');
}
```

**Status:** ❌ Not implemented.

---

### 13.9 Partial Batch Success

**What happens:** `POST /employees/bulk` with 50 records. Server applies 30 then crashes.

**Without fix:** Client marks all 50 successful OR all 50 failed — both wrong.

**Current design:** Jobs processed individually, not as bulk. Each job independently tracked. Partial failure automatically handled by per-job backoff.

**Status:** ✅ Safe — individual job processing prevents partial-batch ambiguity. Bulk endpoint adds efficiency but must be atomic.

---

## 14. Observability and Debugging

### 14.1 Log Taxonomy

Every log entry from sync code uses the `'SYNC'` tag and one of four levels:

```dart
LogService.info(   'Sync cycle started — ${jobs} pending jobs',  tag: 'SYNC');
LogService.info(   'Job succeeded: ${entityName}/${entityId}',    tag: 'SYNC');
LogService.warning('Stale lock detected — age: ${age}ms',        tag: 'SYNC');
LogService.warning('Conflict detected: ${entityName}/${entityId}', tag: 'SYNC');
LogService.error(  'Job failed: ${e.runtimeType} — ${e.message}', tag: 'SYNC', error: e, stackTrace: st);
LogService.error(  'Sync cycle failed',                           tag: 'SYNC', error: e, stackTrace: st);
```

Never use `print()` or `debugPrint()` in sync code.

### 14.2 Metrics Collection

```dart
abstract class SyncMetrics {
  void recordCycleStarted();
  void recordCycleCompleted({
    required Duration wallTime,
    required int jobsPushed,
    required int jobsFailed,
    required int conflictsResolved,
    required int recordsPulled,
  });
  void recordCycleFailed(String errorClass);
  void recordJobFailed(String entityName, String errorCode);
  void recordConflict(String entityName, String strategy);
  void recordQueueDepth(int count);
}
```

**Production alerts:**
- `sync.cycle.duration_ms > 30000` → investigate engine bottleneck
- `sync.queue.depth > 100` → user has large backlog, check connectivity patterns
- `sync.jobs.failed_rate > 5%` → investigate API errors or contract violations
- `sync.conflicts.count spike` → API version mismatch between client and server

### 14.3 Diagnosing a `failed` Entity

```sql
-- Step 1: What happened?
SELECT operation, occurred_at, error_code, error_detail, payload_snapshot
FROM sync_operations_log
WHERE entity_name = 'employees' AND entity_id = ?
ORDER BY occurred_at DESC
LIMIT 20;

-- Step 2: What is the current state?
SELECT sync_state, last_synced_at, local_version, last_error, data_json
FROM synced_entities
WHERE entity_name = 'employees' AND local_id = ?;

-- Step 3: Is there a queued job?
SELECT job_id, type, retry_count, last_error, idempotency_key, next_retry_at
FROM sync_queue
WHERE entity_name = 'employees' AND entity_id = ?;
```

**Common root causes by error pattern:**

| Error Code | Root Cause | Fix |
|------------|-----------|-----|
| `404` | Out-of-order: update before create | Per-entity ordering constraint (Section 13.4) |
| `409` | Conflict not handled | Fix 4 in Section 3 |
| `422` | Payload validation failure | Contract version mismatch — run migrator |
| `timeout repeated` | Idempotency missing | Fix 3 in Section 3 |
| `no executor registered` | Contract not registered in DI | Verify `@SyncExecutorFor('entityName')` annotation |

### 14.4 Enabling Debug Mode

```dart
// In SyncSdkConfig:
SyncSdkConfig(
  enabled: true,
  debugLogging: true,  // logs every job attempt, payload, response
)
```

---

## 15. Module Boundaries

Each module has a single, named owner. No module may import from another module except through its declared public interface.

### 15.1 Ownership Table

| Module | Location | Owns | Must NOT |
|--------|----------|------|----------|
| **SyncEngine** | `engine/sync_engine.dart` | Job processing loop, push/pull orchestration, backoff execution | Import UI, import feature APIs directly |
| **SyncQueue** | `data/sql_sync_queue_repository.dart` | Job CRUD, coalescing, due-job query, retry scheduling | Know about entities, network, or UI |
| **SyncEntityStore** | `data/sql_sync_entity_store.dart` | Entity upsert, state transitions, paginated reads | Know about jobs, network, or conflicts |
| **SyncWriteGateway** | `data/sql_sync_write_gateway.dart` | Atomic write: entity upsert + queue enqueue in one transaction | Implement business logic or validation |
| **SyncConflictResolver** | `engine/sync_conflict_resolver.dart` | Strategy dispatch, server-version application, conflict event emission | Reach into queue directly — only via SyncEngine |
| **SyncFeatureContract** | `validation/sync_contract_validator.dart` | DI graph validation, payload version declaration | Execute network requests |
| **SyncExecutor** (per entity) | `Features/<name>/data/sync/` | HTTP calls for that entity only | Reference other features or core engine internals |
| **SyncController** | `modules/sync/integration/sync_controller.dart` | Trigger decisions (connectivity check via `ConnectivityService`, periodic timer) | Import Flutter packages — use `ConnectivityService` abstraction |
| **SyncManagerCubit** | `presentation/shared/sync/sync_manager_cubit.dart` | Stability probe, debounce, reconnect countdown, cycle dispatch, UX signals | Import SyncQueue or EntityStore directly — signal-only coupling to engine |
| **OfflineUxCubit** | `presentation/shared/sync/offline_ux_cubit.dart` | UI phase transitions based on signals | Import any sync infrastructure class |
| **SyncSDK** | `modules/sync/sdk/sync_sdk.dart` | Bootstrap sequence, DI wiring, SyncLock stale release | Be imported anywhere except `main.dart` or `app.dart` |
| **OperationLog** | `data/sync_operations_log.dart` | Append-only audit log writes and retention cleanup | Be read by the engine during execution (write-only during sync) |

### 15.2 Dependency Graph

```
main.dart / app.dart
    │
    └─► SyncSDK.initialize()           [modules/sync/sdk/]
             │
             ├─► SyncLock.releaseIfStale()   (uses StorageService)
             └─► SyncController.init()       [modules/sync/integration/]
                      │ fires event/callback (no direct import of Cubit)
                      │
                      └─► SyncManagerCubit           [presentation/shared/sync/]
                                │
                                ├─► ConnectivityService   [core/platform/connectivity/]
                                ├─► NetworkStabilityProbe [core/platform/connectivity/]
                                ├─► SyncEngine.runSyncCycle()
                                │        │
                                │        ├─► SyncQueue         [modules/sync/data/]
                                │        ├─► SyncEntityStore   [modules/sync/data/]
                                │        ├─► SyncExecutor      [Features/<name>/data/sync/]
                                │        ├─► SyncConflictResolver [modules/sync/engine/]
                                │        └─► OperationLog      [modules/sync/data/]
                                └─► OfflineUxCubit (signals only) [presentation/shared/sync/]

SyncWriteGateway  ── used by Features (write path)  [modules/sync/domain/]
sync_plugin.dart  ── ONLY public API for external import
```

**Forbidden import paths — these are hard violations:**

```
❌  modules/sync/  → Features/          (no feature imports in modules)
❌  modules/sync/  → presentation/      (no Flutter/Cubit in modules)
❌  SyncEngine     → OfflineUxCubit     (engine must not know about UI)
❌  SyncEngine     → any Feature ApiService
❌  SyncExecutor   → SyncEngine         (executors are leaves, not orchestrators)
❌  SyncExecutor   → another feature's SyncExecutor
❌  OfflineUxCubit → SyncQueue / SyncEntityStore / SyncEngine
❌  core/          → Features/
❌  SyncSDK        → imported anywhere except main.dart or app.dart
❌  SyncController → flutter_bloc or any Flutter UI package
```

---

## 16. Data Request Strategy — Flat, Minimal, Efficient

### 16.1 Principle — The Client Dictates the Shape

The backend must not decide what data to return. The client must declare exactly what it needs. This prevents over-fetching, enables delta sync, and makes pagination deterministic.

### 16.2 Entity Separation (Non-Negotiable)

**Wrong — compound endpoint:**

```
GET /employees_with_mosques_and_roles_and_departments
→ { id, name, mosques: [{...}], role: {...}, department: {...} }
```

Problems: Cannot delta-sync independently. Cannot paginate relations. Response size is unpredictable. Backend must JOIN — O(n²) at scale.

**Correct — one endpoint per entity:**

```
GET /employees?updated_since=ISO&include_deleted=true&cursor=X&limit=500
GET /mosques?updated_since=ISO&include_deleted=true&cursor=X&limit=500
GET /employee_mosques?updated_since=ISO&include_deleted=true&cursor=X&limit=500
GET /roles?updated_since=ISO&include_deleted=true&cursor=X&limit=500
```

Each is independently paginated, independently delta-synced, independently cacheable. All joins happen locally in SQLite.

### 16.3 Field Projection

Request only the fields the client needs:

```
GET /employees?fields=id,name,updated_at,is_deleted,role_id
```

**When to use:**
- Delta sync: only `id`, `updated_at`, `is_deleted`, and the changed fields are needed to update the local record. Full field projection is only required at bootstrap.
- List views: often need only `id`, `name`, `avatar_url`, `updated_at`.
- Detail view: load remaining fields on demand from local DB (bootstrap already fetched them).

**Backend implementation requirement:** The `fields` parameter must never affect `id`, `updated_at`, `is_deleted`, or `version` — these four must always be returned regardless of projection. If the backend does not support projection, it must return all fields and the client filters in `SyncContractMigrator`.

### 16.4 Nesting Depth — Maximum One Level

```json
// ✅ ALLOWED — flat record with scalar foreign key:
{ "id": "emp-1", "name": "Ahmad", "mosque_id": "mos-5", "updated_at": "..." }

// ❌ FORBIDDEN — nested object:
{ "id": "emp-1", "name": "Ahmad", "mosque": { "id": "mos-5", "name": "..." }, ... }

// ❌ FORBIDDEN — nested array:
{ "id": "emp-1", "name": "Ahmad", "mosques": [{ "id": "mos-5" }, ...], ... }
```

Nested objects and arrays make delta sync impossible for the nested entity. They also make response size unpredictable and break `SyncContractValidator`.

### 16.5 Request Batching Rules

| Scenario | Strategy | Reason |
|----------|----------|--------|
| Bootstrap (first launch) | Parallel, max 2 entities simultaneously | Prevents memory spike; uses `eagerError: false` |
| Delta sync | Sequential by priority | Relations must sync after entities they reference |
| Write (single entity) | Individual job per entity | Enables independent retry |
| Write (bulk) | `POST /resource/bulk` max 50 per batch | Server atomicity limit; prevents timeout |
| File upload | Chunked serial | Chunked parallel causes server I/O contention |

### 16.6 What to Never Send Over the Wire

| Forbidden | Reason |
|-----------|--------|
| Binary blobs in JSON fields | Base64 in JSON increases size by 33%; use file system + URL |
| Computed/derived fields (`full_name`, `age`) | These change without a server write — break delta sync |
| Client-side UUIDs as foreign keys without server confirmation | Entity may not exist on server yet — defer relation job until entity job succeeds |
| Circular references (`employee.manager → employee`) | Causes infinite recursion in `SyncContractValidator` |

---

## 17. Things That Break in Production

These are not theoretical risks. Each scenario has happened in real offline-first systems. Each has a specific detection method and recovery path.

### 17.1 Duplicate Server Records (No Idempotency)

**Trigger:** Network drops after server writes but before client receives 200. Client retries.

**Symptom:** User sees duplicate employees in the list. Report exports have double entries. Aggregated counts are wrong.

**Detection:** Server-side uniqueness constraint violation errors start appearing in logs (after enough duplicates). Or users report it.

**Root cause in this system:** `Idempotency-Key` header not sent.

**Fix:** Section 3, Fix 3.

**Prevention at DB level:** Server must also enforce `UNIQUE(idempotency_key)` with TTL-based cleanup.

---

### 17.2 Pull Overwrites Unsynced Local Changes

**Trigger:** Pull executes before Push in the sync cycle.

**Symptom:** User saves a change. It appears to revert immediately. After next sync, it "comes back." Intermittent UX bug that is impossible to reproduce in testing because timing-dependent.

**Detection:** User reports data "disappearing after saving." Operations log shows `pull_received` timestamp earlier than `push_attempt` for the same entity.

**Root cause in this system:** Cycle ordering not structurally enforced.

**Fix:** Section 3, Fix 5.

---

### 17.3 Infinite Retry Loop on 409

**Trigger:** Server returns 409. Engine treats it as transient failure. Retries with exponential backoff. Gets 409 again. Repeats until `max_retries` exhausted.

**Symptom:** Queue shows a job at `retry_count: 5, last_error: "409"`. Entity is `failed`. User's change is silently gone.

**Worse variant:** If `max_retries` is set to a large value and retry delay is short, the engine retries a 409 hundreds of times in a few minutes, hammering the server with requests the server will always reject.

**Detection:** Operations log shows repeated `push_failure` with `error_code: 409` for the same job. `sync.conflicts.count` metric is zero (conflict resolver never invoked).

**Root cause in this system:** `ConflictFailure` not detected; 409 mapped to generic failure.

**Fix:** Section 3, Fix 4.

---

### 17.4 Large Sync Freezes the UI

**Trigger:** Bootstrap processes 50,000 records. Each `upsert()` call triggers a reactive stream update. The stream has 1 active subscriber (the list screen). Flutter rebuilds the list 50,000 times.

**Symptom:** App is unresponsive during bootstrap. ANR on Android. Black screen flash on iOS. User force-quits — partial bootstrap state permanently stale.

**Detection:** Frame rendering time > 16ms during sync. `flutter_frames` DevTool shows dropped frames. Profiler shows SQLite writes on main isolate.

**Root cause in this system:** No isolate separation, no batch transaction, reactive stream updated per-record.

**Required fixes (not yet in implementation):**

```dart
// 1. Batch per-page in one transaction (already specified in Section 4.3):
await _db.transaction(() async {
  for (final record in page.data) {
    await _entityStore.upsert(record);
  }
});
// Transaction: 1 disk fsync per page instead of 500 → 500x fewer I/O ops.

// 2. Run sync on background isolate:
// Use compute() or Isolate.spawn() for the bootstrap loop.
// Communicate progress via SendPort (no shared memory).

// 3. Debounce reactive stream:
// entityStore.watchCount(entityName)
//   .debounceTime(const Duration(milliseconds: 300))
//   .listen(...)
// Rebuilds UI at most once per 300ms regardless of write rate.
```

---

### 17.5 Memory Spike on Bulk Insert

**Trigger:** Bootstrap fetches 10,000 records into memory, deserializes all of them, then writes all to SQLite at once.

**Symptom:** OOM exception on low-memory devices (2 GB RAM). App killed by OS.

**Detection:** `dart:developer` memory timeline shows RSS spike during bootstrap. OOM crashes in crash reporting.

**Root cause:** Loading entire page into Dart memory before writing. Page size of 500 records × large payload (20 KB each) = 10 MB per page in memory.

**Required fix — stream, don't buffer:**

```dart
// BAD — loads entire page into memory:
final page = await api.getPage(cursor: cursor, limit: 500);
final allRecords = page.data.map(SyncEntityRecord.fromJson).toList(); // 10 MB
await entityStore.batchUpsert(allRecords);

// GOOD — process in chunks with bounded memory:
final page = await api.getPage(cursor: cursor, limit: 500);
const chunkSize = 50;
for (var i = 0; i < page.data.length; i += chunkSize) {
  final chunk = page.data.sublist(i, min(i + chunkSize, page.data.length));
  await _db.transaction(() async {
    for (final r in chunk) {
      await entityStore.upsert(SyncEntityRecord.fromJson(r));
    }
  });
  // Allow GC between chunks:
  await Future.delayed(Duration.zero);
}
```

---

### 17.6 Stale Lock After Crash

**Trigger:** Sync cycle acquires lock. App is killed by OS (OOM, user force-quit). Lock remains set in SharedPreferences. Next launch never releases it. `SyncLock.acquire()` returns `false` forever. Sync is permanently disabled.

**Symptom:** Queue accumulates jobs. Nothing ever processes. User's data never reaches the server. No error displayed.

**Detection:** `sync.cycle.started` metric never increments after a known app restart. Lock `acquired_at_ms` is hours in the past.

**Fix:** `SyncLock.releaseIfStale()` in `SyncSDK.initialize()`. Section 3, Fix 2.

---

### 17.7 DB Corruption Crash Loop

**Trigger:** Flash storage write interrupted mid-journal (power loss, kernel panic). SQLite WAL file corrupted. Every database operation throws `DatabaseException: file is not a database`.

**Symptom:** App crashes immediately on launch. Every relaunch crashes at the same point. No user action can recover this.

**Detection:** Crash reporter shows 100% crash rate for affected users. Stack trace points to SQLite open call.

**Fix:** `PRAGMA integrity_check` at `SyncSDK.initialize()`. If result is not `ok`, delete DB files and all stored cursors. App re-bootstraps from scratch. Section 3, Fix 5 (listed as PRAGMA fix in roadmap).

---

### 17.8 Relation Job Before Entity Job

**Trigger:** User creates an employee (local UUID) and immediately assigns them to a mosque. Two jobs enter the queue: `create employee` and `create employee_mosque`. By timing, the mosque assignment job fires before the employee job.

**Symptom:** Server returns 404 on the relation job (employee doesn't exist yet). Relation job fails. After `max_retries`, the assignment is permanently lost even though the employee synced successfully.

**Detection:** Operations log: `push_failure 404` on `employee_mosques` job. Subsequent operations log: `push_success` on `employees` job. The ordering was wrong.

**Fix:** Per-entity ordering constraint in `getDueJobs()`. Also: relation jobs must use `priority: 50` and entity jobs `priority: 10`. Queue processes all priority-10 jobs before priority-50. Section 13.4.

---

### 17.9 Delta Sync Cursor Saved Before Download Completes

**Trigger:** Download starts with 3 pages. After page 1, network drops. Engine catches the exception, saves the cursor (page 1's `next_cursor`), and exits. Next sync starts from page 2. Pages 2 and 3 are never downloaded.

**Symptom:** Records from pages 2 and 3 are permanently missing from the local DB. Users report missing data. The data exists on the server but is never synced.

**Detection:** Total record count in SQLite does not match `total_count` from `/resource/meta` endpoint. Operations log shows gap in `pull_received` sequence.

**Fix (already in Section 4.1):** Cursor is updated **only** after `has_more: false` is received AND all pages are written. Per-page checkpoints are saved only for crash resume, not as the sync cursor.

---

## 18. Strict Do / Don't Rules

These rules are non-negotiable. Violations require a written exception approved by the tech lead and documented in this README.

### 18.1 Sync Engine Rules

| # | Rule | Why |
|---|------|-----|
| E1 | MUST acquire `SyncLock` before any job processing | Concurrent runs produce duplicate server records |
| E2 | MUST release `SyncLock` in a `finally` block — always | Exception before `release()` permanently disables sync |
| E3 | MUST push queue before pulling delta | Pull before push silently discards local changes |
| E4 | MUST NOT retry a `ConflictFailure` (409) | Retry loop exhausts retries and permanently loses user data |
| E5 | MUST invoke `SyncConflictResolver` on every 409 response | Unresolved conflicts produce `failed` entities |
| E6 | MUST save sync cursor ONLY after full download completion | Premature cursor causes permanent data gaps |
| E7 | MUST run sync on a background isolate for 1000+ records | Main-thread sync freezes UI and triggers ANR |
| E8 | MUST process per-page writes in a single SQLite transaction | Per-record transactions are 100–500x slower at scale |

### 18.2 Queue Rules

| # | Rule | Why |
|---|------|-----|
| Q1 | Every job MUST carry a deterministic `idempotency_key` | Retries without idempotency create duplicate server records |
| Q2 | `idempotency_key` MUST be stable across retries | Changing key on retry defeats idempotency |
| Q3 | MUST coalesce incoming jobs against existing queued jobs | Multiple pending jobs per entity cause contradictory server state |
| Q4 | Priority-10 (entity) jobs MUST process before priority-50 (relation) jobs | Relations reference entities — wrong order causes 404 |
| Q5 | MUST NOT allow `max_retries = 0` | Transient network errors would immediately fail and lose jobs |
| Q6 | Dead-letter jobs MUST be preserved, not silently dropped | Silent drops are data loss; always log and surface to user |

### 18.3 Data Model Rules

| # | Rule | Why |
|---|------|-----|
| D1 | Every entity MUST have `id` (UUID), `created_at`, `updated_at`, `is_deleted` | Without these, delta sync and soft-delete propagation are impossible |
| D2 | IDs MUST be UUID strings — never auto-increment integers | Auto-increment IDs are device-local and collide across devices |
| D3 | `updated_at` MUST be updated on every server-side mutation including soft-delete | Delta sync cursor is `updated_since`; stale `updated_at` causes missed records |
| D4 | Backend MUST use soft delete — NEVER hard delete | Hard deletion causes permanent ghost records on all client devices |
| D5 | Relation tables MUST have their own `id`, `updated_at`, and `is_deleted` | Without these, relation changes are invisible to delta sync |

### 18.4 API Contract Rules

| # | Rule | Why |
|---|------|-----|
| A1 | Backend MUST NOT return nested objects or arrays | Nested responses make independent delta sync impossible |
| A2 | All write endpoints MUST support `Idempotency-Key` header | Retries without server-side idempotency corrupt data |
| A3 | Delta endpoints MUST support `include_deleted=true` | Without it, soft-deleted records are never propagated to clients |
| A4 | Pagination MUST be cursor-based — page-number pagination is forbidden | Page-based skips records under concurrent inserts and cannot be checkpointed |
| A5 | HTTP 409 MUST return `server_version`, `client_version`, `conflict_fields` | Without `conflict_fields`, field-level merge and manual resolution are impossible |
| A6 | Bulk endpoints MUST be all-or-nothing (atomic) | Partial success is indistinguishable from failure without per-record tracking |

### 18.5 Storage Rules

| # | Rule | Why |
|---|------|-----|
| S1 | Files > 200 KB MUST be stored in the filesystem — NOT as SQLite BLOBs | SQLite degrades significantly above 200 KB per BLOB |
| S2 | `data_json` in `synced_entities` MUST contain only scalar values and foreign-key strings | No embedded objects, no base64, no binary |
| S3 | `PRAGMA integrity_check` MUST run at every app startup | Corrupted DB undetected until first query — then crash loop |
| S4 | All required SQLite indexes MUST be created on first open (Section 9.4) | Missing indexes cause full table scans — ANR on 100K+ records |

### 18.6 Code Quality Rules

| # | Rule | Why |
|---|------|-----|
| C1 | NEVER use `getIt<T>()` inside a `SyncExecutor` method body | Service locator pattern breaks testability and creates implicit dependencies |
| C2 | NEVER import `SyncEngine` or `SyncQueue` from `OfflineUxCubit` | UX layer must be decoupled from infrastructure to be unit-testable |
| C3 | NEVER `print()` or `debugPrint()` in sync code | Use `LogService` with tag `'SYNC'` — enables production log filtering |
| C4 | NEVER suppress exceptions in sync code without logging and re-throwing or recording to operation log | Silent failures make production debugging impossible |
| C5 | Every `SyncFeatureContract` MUST be registered in DI and verified by `SyncContractValidator` | Unregistered contracts cause runtime `no executor registered` failures |

---

## 19. Per-App Entity Configuration — How to Use This Module in Any App

### 19.1 The Fundamental Design — Entity-Agnostic Framework

The sync module knows nothing about "users", "mosques", "students", or any specific entity.

Every reference to `users` in this document is a **reference implementation only** — it demonstrates the pattern. The actual entities are declared entirely by the consuming app.

```
sync module  ──  framework only, no knowledge of your entities
     │
     │  registration
     ├── MosqueSyncExecutor      ← mosque management app
     ├── EmployeeSyncExecutor    ← HR app
     ├── StudentSyncExecutor     ← school app
     └── (any entity you need)
```

If an entity has no registered executor, the engine silently skips it. Zero breaking changes. Zero configuration in the sync module itself.

---

### 19.2 Three App Scenarios

#### Scenario A — Mosque Management App

Sync only mosques and their related data. Users/auth data is server-side only (admin system, no offline needed).

```dart
// lib/Features/mosques/data/sync/mosques_sync_executor.dart
@SyncExecutorFor('mosques')
@LazySingleton(as: SyncExecutor)
class MosquesSyncExecutor implements SyncExecutor { ... }

// lib/Features/mosque_employees/data/sync/mosque_employees_sync_executor.dart
@SyncExecutorFor('mosque_employees')
@LazySingleton(as: SyncExecutor)
class MosqueEmployeesSyncExecutor implements SyncExecutor { ... }

// RESULT: only mosques + mosque_employees are synced.
// No users executor → users never enter the queue.
```

#### Scenario B — School Management App

Sync students and teachers. Grades stay server-side (no offline grade editing allowed by policy).

```dart
@SyncExecutorFor('students')   class StudentsSyncExecutor implements SyncExecutor { ... }
@SyncExecutorFor('teachers')   class TeachersSyncExecutor implements SyncExecutor { ... }
// No GradesSyncExecutor → grades are never queued, never synced offline.
```

#### Scenario C — Mixed App (some entities offline, some not)

```dart
// These entities support offline editing:
@SyncExecutorFor('attendance')  class AttendanceSyncExecutor implements SyncExecutor { ... }
@SyncExecutorFor('schedules')   class SchedulesSyncExecutor implements SyncExecutor { ... }

// These are read-only or admin-only → no executor needed:
// reports, system_settings, audit_logs → always fetch live from server
```

---

### 19.3 How to Add a New Entity to Sync (Step-by-Step)

When you start a new app from this template, follow these steps for each entity that needs offline support:

**Step 1 — Declare the contract** in `Features/<name>/data/sync/<name>_feature_contract.dart`:

```dart
// lib/Features/mosques/data/sync/mosques_feature_contract.dart

@LazySingleton()
@Named('sync_feature_contracts')
class MosquesFeatureContract extends SyncFeatureContract<Mosque> {
  const MosquesFeatureContract();

  @override
  String get entityName => 'mosques';   // ← must match SyncExecutorFor annotation

  @override
  Type get repositoryContractType => MosquesRepository;

  @override
  Object resolveRepository(GetIt di) => di<MosquesRepository>();

  @override
  int get contractVersion => 1;

  // Override for non-default conflict behavior:
  // @override
  // SyncConflictStrategy get conflictStrategy => SyncConflictStrategy.lastWriteWins;

  @override
  Map<String, dynamic> toJson(Mosque entity) => entity.toJson();

  @override
  Mosque fromJson(Map<String, dynamic> json) => Mosque.fromJson(json);

  @override
  String localIdOf(Mosque entity) => entity.id;
}
```

**Step 2 — Implement the executor** in `Features/<name>/data/sync/<name>_sync_executor.dart`:

```dart
// lib/Features/mosques/data/sync/mosques_sync_executor.dart

@SyncExecutorFor('mosques')
@LazySingleton(as: SyncExecutor)
class MosquesSyncExecutor implements SyncExecutor {
  const MosquesSyncExecutor(this._api);

  final MosquesApiService _api;  // ← your Retrofit service, injected normally

  @override
  String get entityName => 'mosques';

  @override
  Set<int> get supportedContractVersions => {1};

  @override
  Future<Either<Failure, SyncExecutionResult>> execute(
    SyncQueueJob job,
    int contractVersion,
  ) async {
    try {
      final payload = jsonDecode(job.payloadJson) as Map<String, dynamic>;
      final opts = Options(headers: {'Idempotency-Key': job.idempotencyKey});

      return switch (job.type) {
        SyncJobType.create => _create(payload, opts, job),
        SyncJobType.update => _update(job.entityId, payload, opts, job),
        SyncJobType.delete => _delete(job.entityId, opts, job),
      };
    } catch (e) {
      return Left(FailureMapperRegistry.map(e, source: 'mosques-sync'));
    }
  }

  Future<Either<Failure, SyncExecutionResult>> _create(
    Map<String, dynamic> payload, Options opts, SyncQueueJob job,
  ) async {
    final res = await _api.createMosque(MosqueCreateRequest.fromJson(payload), opts);
    if (res.error != null) return Left(BusinessFailure(statusCode: res.error!.code ?? 400));
    return Right(SyncExecutionResult(localId: job.entityId, serverId: res.data!.id));
  }

  Future<Either<Failure, SyncExecutionResult>> _update(
    String id, Map<String, dynamic> payload, Options opts, SyncQueueJob job,
  ) async {
    final res = await _api.updateMosque(id, MosqueUpdateRequest.fromJson(payload), opts);
    if (res.error != null) return Left(BusinessFailure(statusCode: res.error!.code ?? 400));
    return Right(SyncExecutionResult(localId: job.entityId, serverId: id));
  }

  Future<Either<Failure, SyncExecutionResult>> _delete(
    String id, Options opts, SyncQueueJob job,
  ) async {
    final res = await _api.deleteMosque(id, opts);
    if (res.error != null) return Left(BusinessFailure(statusCode: res.error!.code ?? 400));
    return Right(SyncExecutionResult(localId: job.entityId, serverId: id));
  }
}
```

**Step 3 — Wire the write path** in `Features/<name>/data/repositories/<name>_repository_impl.dart`:

```dart
// When the user saves a mosque locally:
class MosquesRepositoryImpl extends SyncableRepository<Mosque>
    implements MosquesRepository {

  MosquesRepositoryImpl(this._syncWriteGateway, /* ... */);

  final SyncWriteGateway _syncWriteGateway;

  @override
  Future<Either<Failure, Mosque>> createMosque(Mosque mosque) async {
    // 1. Assign a local UUID — no server roundtrip needed
    final localMosque = mosque.copyWith(id: const Uuid().v4());

    // 2. Atomic: write to SQLite + enqueue job in one transaction
    await _syncWriteGateway.write(SyncWriteCommand(
      entityName: 'mosques',
      entityId: localMosque.id,
      type: SyncJobType.create,
      payloadJson: jsonEncode(localMosque.toJson()),
    ));

    // 3. Return immediately — no waiting for network
    return Right(localMosque);
  }
}
```

**Step 4 — Run build_runner:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Done. The mosque entity is now fully integrated into the sync pipeline.

---

### 19.4 How to Exclude an Entity from Sync (Keep It Server-Side Only)

If an entity should always be fetched live (reports, audit logs, system settings):

```dart
// Simply: do NOT create a SyncFeatureContract or SyncExecutor for it.
// The engine has no knowledge of entities without registered executors.
// Reads go directly to the API via the normal REST flow (not through SyncWriteGateway).
```

If you want to be explicit (for team documentation purposes):

```dart
// In the feature's repository, use the normal REST path:
@override
Future<Either<Failure, List<Report>>> getReports() =>
    handle(() => _api.getReports(null));
    // ← no SyncWriteGateway involved — pure server-side
```

---

### 19.5 Selective Sync — Per-Entity Control

You can enable/disable sync per entity without touching the sync module:

```dart
// Option A: Don't register the executor (compile-time exclusion)
// → entity never enters the queue

// Option B: Feature flag at runtime
@SyncExecutorFor('attendance')
@LazySingleton(as: SyncExecutor)
class AttendanceSyncExecutor implements SyncExecutor {
  @override
  Future<Either<Failure, SyncExecutionResult>> execute(job, version) async {
    if (!AppFeatures.attendanceOffline) {
      // If flag is off, treat as success (no-op) — job is cleared from queue
      return Right(SyncExecutionResult(localId: job.entityId, serverId: job.entityId));
    }
    // ... normal sync
  }
}
```

---

### 19.6 Reference Implementation — What to Keep vs. Replace

| File | Action for New App |
|------|--------------------|
| `Features/users/data/sync/users_sync_executor.dart` | **Replace** — implement correct POST/PATCH/DELETE for your entities |
| `Features/users/data/sync/users_sync_feature_contract.dart` | **Replace** — declare your entity contracts |
| `Features/users/data/sync/users_sync_repository_decorator.dart` | **Replace** — one decorator per entity |
| `modules/sync/` (entire folder) | **Never touch** — framework only |
| `lib/presentation/shared/sync/` (Cubits) | **Implement** — build `SyncManagerCubit` and `OfflineUxCubit` per Section 12 |

> The `users` feature in this template exists **solely as a compilable, runnable example** of the correct pattern. In your app, delete or adapt it. The sync framework itself — everything inside `modules/sync/` — is never modified.

---

### 19.7 Decision Tree — Does This Entity Need Sync?

```
Is this entity read-only?
    │
    ├── Yes → No sync needed. Use normal REST. No executor.
    │
    └── No (user can create/edit/delete)
            │
            Does it need to work offline?
            │
            ├── No → Use normal REST with online-only guard.
            │         Show "no connection" error when offline.
            │
            └── Yes → Implement SyncFeatureContract + SyncExecutor.
                        Write path: SyncWriteGateway.write()
                        Read path: SyncEntityStore (local SQLite)
                        Pull path: deltaDownload() fetches from API
```

---

## 20. Roadmap

### 20.1 Phase 1 — Blockers (2–3 days) — Nothing Ships Until Done

These are not improvements — they are defect fixes. Each represents a confirmed data corruption scenario.

- [ ] **Expand `SyncStatus` enum** — add `pendingCreate`, `pendingUpdate`, `pendingDelete`, `conflicted` (Section 0.5)
- [ ] **Expand `SyncConflictStrategy` enum** — add `lastWriteWins`, `manual`, `merge` (Section 0.5)
- [ ] **Fix `UsersSyncExecutor`** — replace `getUsers()` with `createUser/updateUser/deleteUser` (Section 0.6)
- [ ] **Add `AppFeatures.offlineSync = false`** to `AppFeatures` (Section 0.2)
- [ ] **Add `ConflictFailure`** to `foundation/errors/failure.dart` + `FailureUiMapper` + `DioFailureMapper` (Section 0.1)
- [ ] **Add `PersistenceKeys.syncLockAcquiredAt`** to `persistence_keys.dart` (Section 0.3)
- [ ] **Call `SyncSDK.initialize()`** from `main.dart` with `AppFeatures.offlineSync` guard
- [ ] **Implement `SyncLock`** with `StorageService` + 10-min TTL + stale release at startup (Section 0.3)
- [ ] **Add `idempotency_key` column** to `sync_queue` (v3 migration)
- [ ] **Send `Idempotency-Key` header** in every `SyncExecutor.execute()` implementation
- [ ] **Wire `SyncConflictResolver`** into `SyncEngine` — never retry a `ConflictFailure`
- [ ] **Enforce Push → Conflict → Pull** ordering in `runSyncCycle()`
- [ ] **`PRAGMA integrity_check`** at startup with wipe + re-bootstrap on failure
- [ ] **Refactor `SyncController`** to use `ConnectivityService` — remove direct package imports (Section 0.4)
- [ ] **Verify backend** supports `Idempotency-Key` header end-to-end
- [ ] **Verify backend** uses soft delete (`is_deleted: true`) — never hard delete

**Exit criteria for Phase 1:** Run 1000 simulated sync cycles with artificial network failures. Zero duplicate server-side records. Zero stuck entities in `failed` state due to conflict loops.

---

**Exit criteria for Phase 1:** Zero `ConflictFailure` events causing retries. Zero duplicate server-side records under 1000 simulated sync cycles with artificial network failures. SyncSDK initializes successfully behind `AppFeatures.offlineSync` flag.

---

### 20.2 Phase 2 — Stability (2–3 days)

Makes the system viable at scale and observable.

- [ ] **Wire delta sync:** `UpdatedAtFilter` + `SyncTimestampsStore` in `SyncEngine.deltaDownload()`
- [ ] **Switch to cursor-based pagination** for all bootstrap fetches
- [ ] **Add per-entity ordering constraint** in `getDueJobs()` (prevent update-before-create)
- [ ] **Execute schema v3 migration:** `sync_state`, `last_synced_at`, `local_version`, `priority`, `idempotency_key`
- [ ] **Create all required indexes** (Section 9.4)
- [ ] **Build `SyncManagerCubit`** in `presentation/shared/sync/` from spec in Section 12 and `new/05_sync/sync_manager.dart` reference
- [ ] **Wire `NetworkStabilityProbe`** into `SyncController._canSyncNow()` and `SyncManagerCubit`
- [ ] **Implement operation log** table + logging in `SyncEngine` (Section 5.6)
- [ ] **Implement download checkpointing** (cursor saved per entity per page)

---

### 20.3 Phase 3 — UX and Polish (3–4 days)

Makes offline behavior transparent and trustworthy to users.

- [ ] **Build `OfflineUxCubit`** (decoupled from `SyncEngine` — Section 11.3)
- [ ] **Build `SyncUiHost`** composing all overlay widgets
- [ ] **Implement Optimistic UI** in all write flows with rollback snapshots (Section 11.5)
- [ ] **Add pending changes indicator** on all entity list screens
- [ ] **Build conflict resolution UI** — inline badge + action sheet
- [ ] **Build sync failure UI** — `SyncErrorBanner` with retry button
- [ ] **Implement `SyncMetrics`** integrated with crash reporting

---

> ## ⛔ Reminder
>
> The system is **not production-ready** until Phase 1 is verified end-to-end including backend confirmation of idempotency support and soft-delete enforcement.
>
> Estimated Phase 1 completion: **2–3 engineering days**.
