# Sync Feature Adapter Generator (Design Contract)

> ⚠️ **This document describes a planned / historical code-generation approach.
> It is not the currently implemented runtime mechanism.** No generator, no
> `source_gen` builder and no `generated/` output exists in this repository.
> Feature sync adapters are written by hand — see `SETUP.md` §Step 3 and the
> reference implementation in `lib/Features/notes/data/sync/`.

What the SDK *does* support today is auto-discovery of decorators and executors
through DI: `SyncSDK.initialize` resolves every registered `SyncExecutor`,
`SyncPullExecutor` and `SyncRepositoryDecorator` from the container, so adding
an entity needs no edit to the module. Everything below describes generating
those files rather than writing them, and remains a proposal.

## Input expected from feature developer

- Domain entity
- DTO/domain mapping functions (`toJson`, `fromJson`)

## Generated outputs

- `<feature>_sync_repository_decorator.dart`
- `<feature>_sync_executor.dart`
- DI bindings (`@LazySingleton(as: SyncRepositoryDecorator)` and `@LazySingleton(as: SyncExecutor)`)

## Generator strategy

- Use `build_runner` + `source_gen`
- Scan for classes implementing `SyncFeatureContract<TEntity>`
- Emit generated files under `Features/<feature>/data/sync/generated/`
- Keep manual overrides optional by partial classes or extension points

## Runtime wiring

- `SyncSDK.initialize(...)` calls:
  1. `registerSyncCore(di)`
  2. `applySyncRepositoryDecorators(di)` (generated decorators are auto-included)
  3. `SyncController.init()`

This keeps sync invisible to Cubits/UseCases and feature business logic.
