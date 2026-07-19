# Sync Feature Adapter Generator (Design Contract)

This SDK now supports auto-discovered decorators/executors through DI.
To reach zero-boilerplate onboarding, code-generation should produce feature sync files from `SyncFeatureContract`.

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
