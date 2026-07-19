# Sync Module — Quick Setup Guide

> Full architecture reference: [`readme/sync.md`](../../../readme/sync.md)

---

## Prerequisites

| Requirement | Version |
|---|---|
| Flutter | ≥ 3.19 |
| Dart | ≥ 3.3 |
| sqflite | ≥ 2.3 |
| dartz | ≥ 0.10 |
| get_it + injectable | any |

---

## Step 1 — Enable the feature flag

```dart
// lib/core/platform/features/app_features.dart
static const offlineSync = true;   // ← change false → true
```

---

## Step 2 — Bootstrap in main.dart ✅ (already done)

```dart
await SyncSDK.initialize(
  const SyncSdkConfig(
    enabled: AppFeatures.offlineSync,
    mode: SyncMode.active,          // active | passive | disabled
    periodicIntervalSeconds: 300,   // every 5 min; null = disable timer
    wifiOnly: false,                // true = only sync on WiFi
  ),
  getIt,
);
```

> `SyncSDK.initialize()` is a no-op when `AppFeatures.offlineSync == false`.

---

## Step 3 — Add your first entity

### 3a. Declare a feature contract

```dart
// lib/Features/<name>/data/sync/<name>_feature_contract.dart

@LazySingleton()
@Named('sync_feature_contracts')
class MosquesFeatureContract extends SyncFeatureContractBase {
  const MosquesFeatureContract();

  @override String get entityName => 'mosques';
  @override Type get repositoryContractType => MosquesRepository;
  @override Object resolveRepository(GetIt di) => di<MosquesRepository>();

  // Override for entity-specific conflict strategy:
  @override
  SyncConflictStrategy get conflictStrategy => SyncConflictStrategy.serverWins;
}
```

### 3b. Implement a sync executor

```dart
// lib/Features/<name>/data/sync/<name>_sync_executor.dart

@SyncExecutorFor('mosques')
@LazySingleton(as: SyncExecutor)
class MosquesSyncExecutor implements SyncExecutor {
  const MosquesSyncExecutor(this._syncApi);
  final MosquesSyncApiService _syncApi;

  @override String get entityName => 'mosques';
  @override Set<int> get supportedContractVersions => {1};

  @override
  Future<Either<Failure, SyncExecutionResult>> execute(
    SyncQueueJob job,
    int contractVersion,
  ) async {
    final payload = jsonDecode(job.payloadJson) as Map<String, dynamic>;
    final opts = Options(headers: {'Idempotency-Key': job.effectiveIdempotencyKey});
    return switch (job.type) {
      SyncJobType.create => _create(payload, opts, job),
      SyncJobType.update => _update(job.entityId, payload, opts, job),
      SyncJobType.delete => _delete(job.entityId, opts, job),
    };
  }
}
```

> ❌ **NEVER** call a GET endpoint inside an executor.  
> Executors **PUSH** (POST / PATCH / DELETE) only. Reads happen via repositories.

### 3c. Wire write path via SyncWriteGateway

```dart
// In MosquesRepositoryImpl.createMosque():
await _syncWriteGateway.write(SyncWriteCommand(
  entityName: 'mosques',
  localId: mosque.id,
  serverId: mosque.serverId,
  dataJson: jsonEncode(mosque.toJson()),
  updatedAt: DateTime.now().millisecondsSinceEpoch,
  version: 1,
  isDeleted: false,
  jobType: SyncJobType.create,
  jobPayloadJson: jsonEncode(mosque.toJson()),
  contractVersion: 1,
  enqueue: true,                        // false = cache-only, no push
));
```

### 3d. Register repository decorator (optional, for offline-first reads)

```dart
// lib/Features/mosques/data/sync/mosques_sync_repository_decorator.dart

@LazySingleton(as: SyncRepositoryDecorator)
class MosquesSyncRepositoryDecorator implements SyncRepositoryDecorator {
  @override
  Future<void> decorate(GetIt getIt) async {
    // Swap live repository for the offline-aware decorator at runtime.
    getIt.unregister<MosquesRepository>();
    getIt.registerLazySingleton<MosquesRepository>(
      () => SyncAwareMosquesRepository(
        getIt<MosquesRepositoryImpl>(),
        getIt<SyncSettingsStore>(),
        getIt<SyncEntityStore>(),
        getIt<SyncWriteGateway>(),
      ),
    );
  }
}
```

---

## Step 4 — Run code generation

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib
```

---

## Step 5 — Add UI scaffolding

### Global offline banner (app-level)

Wrap your root scaffold or top-level widget with `SyncUiHost`:

```dart
// lib/app.dart — inside MaterialApp builder:
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => getIt<SyncManagerCubit>()),
    BlocProvider(create: (_) => getIt<OfflineUxCubit>()),
  ],
  child: SyncUiHost(child: child!),
)
```

### Pending changes badge (per-screen AppBar)

```dart
AppBar(
  title: const Text('Mosques'),
  actions: const [PendingChangesChip()],
)
```

### Available widgets

| Widget | Purpose |
|---|---|
| `SyncUiHost` | Wraps a screen — banner + conflict sheet + error snackbar |
| `SyncStatusBanner` | Offline / pending changes ribbon |
| `PendingChangesChip` | AppBar badge showing pending count + sync button |

---

## Step 6 — Backend contract (required)

Your API endpoints MUST support:

```
GET  /resource?updated_since=<ISO>&include_deleted=true   ← delta pull
POST /resource                                             ← create
PATCH /resource/{id}                                       ← update
DELETE /resource/{id}                                      ← soft delete

All writes: Idempotency-Key header (required)

HTTP 409 response body:
{
  "server_version": { ...full entity... },
  "client_version": { ...full entity... },
  "conflict_fields": ["field_a", "field_b"]
}
```

Every entity MUST have these fields:

| Field | Type | Notes |
|---|---|---|
| `id` | `string` | UUID, client-generated for create |
| `created_at` | ISO timestamp | Immutable after creation |
| `updated_at` | ISO timestamp | Updated on every write |
| `is_deleted` | `boolean` | Soft delete — never hard-delete |
| `version` | `integer` | Incremented server-side on every write |

---

## Disabling sync for an entity

Simply **do not** register a `SyncFeatureContract` or `SyncExecutor` for it.  
Pass `enqueue: false` in every `SyncWriteCommand` — the data is cached locally,
never queued for push.

---

## Debugging

### Find all failed entities

```sql
SELECT local_id, entity_name, last_error, updated_at
FROM synced_entities
WHERE sync_status = 'failed';
```

### Find all conflicted entities

```sql
SELECT * FROM synced_entities WHERE sync_status = 'conflicted';
```

### Inspect operation log for an entity

```sql
SELECT operation, occurred_at, error_code, error_detail
FROM sync_operations_log
WHERE entity_name = 'mosques' AND entity_id = '<id>'
ORDER BY occurred_at DESC;
```

### Check the current queue

```sql
SELECT job_id, entity_name, type, retry_count, max_retries, last_error
FROM sync_queue
ORDER BY priority, next_retry_at;
```

### Force sync via code

```dart
context.read<SyncManagerCubit>().triggerSync();
// or directly:
getIt<SyncController>().triggerManualSync();
```

### Reset a stuck lock (dev only)

```dart
await getIt<SyncLock>().release();
```

---

## Excluding sync entirely from a new app

1. Keep `AppFeatures.offlineSync = false` (default).
2. Remove `lib/modules/sync/` from the project (optional, zero-overhead if kept).
3. Remove `SyncFeatureContract` / `SyncExecutor` registrations from all features.

The rest of the template is completely unaffected.

---

## Roadmap checklist for production readiness

- [ ] Backend supports delta sync (`updated_since`) for all synced entities
- [ ] Backend supports `Idempotency-Key` header (deduplicate retries)
- [ ] Backend returns HTTP 409 with `conflict_fields` on version conflict
- [ ] All entities have `id`, `created_at`, `updated_at`, `is_deleted`, `version`
- [ ] `AppFeatures.offlineSync = true` in the app's feature config
- [ ] `SyncFeatureContract` + `SyncExecutor` registered for each entity
- [ ] `SyncWriteGateway.write()` called in all repository mutation methods
- [ ] UI: `SyncUiHost` + `PendingChangesChip` added to screens with sync entities
- [ ] `dart run build_runner build` after every new entity registration

---

*This file is for developers setting up the sync module. Architecture decisions are in [`readme/sync.md`](../../../readme/sync.md).*
