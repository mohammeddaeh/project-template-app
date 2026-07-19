# Architecture Guide

> **المرجع الكامل:** [`core_architecture.md`](core_architecture.md) — اقرأه قبل أي تعديل معماري.  
> **قاعدة Cursor:** `.cursor/rules/core-architecture.mdc` (تُطبَّق تلقائياً).  
> **مزامنة إلزامية:** عند تغيير الكود → حدّث readme المرتبط (انظر القسم 0 في `core_architecture.md`).

This template uses **Clean Architecture** with **feature-based organization**. **REST only** in `lib/`.

---

## Documentation Index

| File | When to read / update |
|------|----------------------|
| [`core_architecture.md`](core_architecture.md) | **Primary** — principles, layers, modification rules |
| [`new_developer_guide.md`](new_developer_guide.md) | Onboarding, first setup, feedback & locale API |
| [`rest_api.md`](rest_api.md) | REST endpoints, import paths, common mistakes, AI generation |
| [`pagination.md`](pagination.md) | Infinite scroll lists |
| [`widgets.md`](widgets.md) | Widget placement, feedback & locale widgets |
| [`scripts.md`](scripts.md) | Scripts, build/release, code generation, troubleshooting |
| [`../lib/core/platform/PLATFORM_SERVICES.md`](../lib/core/platform/PLATFORM_SERVICES.md) | Optional platform services P6-P10 — how to enable & use |
| [`../lib/core/infra/network/NETWORK.md`](../lib/core/infra/network/NETWORK.md) | Network interceptors, cache, retry, TokenRefresh, BaseRepository |
| [`widgets_usage.md`](widgets_usage.md) | **Widget Usage Guide** — كل الويدجتات مع أمثلة الاستخدام |
| [`../lib/modules/sync/SETUP.md`](../lib/modules/sync/SETUP.md) | Sync module — quick setup |
| [`sync.md`](sync.md) | **Offline Sync — Engineering Reference** (architecture, lifecycle, failure scenarios, roadmap) |
| [`../new/09_graphql/README.md`](../new/09_graphql/README.md) | Optional GraphQL (not in template) |

---

## `lib/` Structure

| Folder | Role |
|--------|------|
| `lib/core/` | Shared infrastructure — `foundation/`, `platform/`, `infra/`, `di/` |
| `lib/modules/` | Optional runtime modules — each has `SETUP.md` + entry point |
| `lib/Features/` | Isolated business features — data / domain / presentation |
| `lib/presentation/` | Theme, UI extensions, error UI, feedback, locale, shared pagination |
| `lib/shared/` | Reusable widgets (`widgets.dart` barrel) |
| `lib/routes/` | Navigation (`auto_route`) |
| `lib/resources/` | Generated locale keys, assets helpers |
| `lib/new/` | Optional alternate stacks (GraphQL backup, reference patterns) |

---

## `lib/core/` Internal Layers

```text
core/
├── foundation/   ← Pure Dart only (no Flutter, no Dio, no injectable)
│   ├── errors/       failure.dart — sealed: NoInternet/Timeout/BadCert/Cancelled/Login/
│   │                 Unauthorized/RateLimit/Server/Business/Parse/Validation/
│   │                 Permission/Storage/Cache/Unknown (16 types)
│   ├── domain/       base_usecase, base_cancel_token, use_case_params, no_params
│   ├── contracts/    api_response, pagination_query, pagination_data_entity,
│   │                 auth_network_gateway, locale_provider, session_reader
│   ├── extensions/   num_extensions
│   ├── utils/        validators
│   └── value_objects/ Email, PhoneNumber, DateRange → Either<ValidationFailure, T>
│
├── platform/     ← Flutter/OS wrappers (depends on foundation only)
│   ├── config/       app_settings
│   ├── extensions/   string_extensions, datetime_extensions
│   ├── locale/       app_locale (enum: arabic/english + isRtl)
│   ├── logging/      log_service (static) + LogDelegate (interface)
│   ├── observability/ app_bloc_observer
│   ├── features/     app_features (central toggle), feature_permission_map
│   ├── connectivity/ network_state, connectivity_service,
│   │                 network_state_monitor, network_state_monitor_impl
│   ├── permissions/  app_permission, app_permission_status,
│   │                 permissions_service, permissions_service_impl
│   ├── notifications/ local_notifications_service (interface),
│   │                 adapters/fln_notifications_adapter,
│   │                 adapters/disabled_notifications_adapter
│   ├── media/        media_service (interface) + media_service_impl
│   ├── launcher/     url_launcher_service (interface) + url_launcher_service_impl
│   ├── storage/      StorageService + SecureStorageService + EncryptionService (interfaces)
│   │                 + persistence_keys
│   │                 adapters/ → SharedPrefs, InMemory, FlutterSecureStorage, AES-256-CBC
│   ├── biometrics/   BiometricsService (interface) + BiometricsServiceImpl [AppFeatures.biometrics]
│   ├── clipboard/    ClipboardService (interface) + ClipboardServiceImpl [AppFeatures.clipboard]
│   ├── share/        ShareService (interface) + ShareServiceImpl [AppFeatures.shareSheet]
│   ├── files/        FileService (interface) + FileServiceImpl [AppFeatures.fileOperations]
│   └── lifecycle/    AppLifecycleService (interface) + AppLifecycleServiceImpl [AppFeatures.appLifecycle]
│
├── infra/        ← Implementation (depends on foundation + platform)
│   ├── config/       env, env_config, flavors_settings
│   ├── network/
│   │   ├── rest/         api_urls, handle_body_response
│   │   ├── interceptors/ auth_interceptor, internet_checker_interceptor,
│   │   │                 token_refresh_interceptor, retry_interceptor,
│   │   │                 request_cache_interceptor
│   │   ├── security/     certificate_pinning_config [AppFeatures.certificatePinning]
│   │   ├── boundary/     base_repository
│   │   └── cancellation/ dio_cancel_token_wrapper
│   ├── errors/       failure_mapper, dio_failure_mapper, failure_mapper_registry,
│   │                 server_message_extractor, prefetch_stage_exception
│   └── session/      auth_event_bus, locale_provider_impl
│
└── di/           ← Composition root (injectable/GetIt)
    ├── injection.dart                   ← configureInjection() + PlatformServicesRegistry.configure()
    ├── injection_module.dart            ← always-on (Dio, Storage, Auth, Notifications)
    ├── platform_services_registry.dart  ← optional P6-P10+I4 via AppFeatures
    └── injection.config.dart            ← generated (build_runner)
```

---

## Optional Modules (`lib/modules/`)

> كل وحدة مستقلة تماماً — تُفعَّل بأمر واحد بعد `configureInjection()`.  
> كل وحدة تحتوي `SETUP.md` بخطوات التفعيل الكاملة.

| Module | Entry Point | Packages |
|--------|-------------|---------|
| `sync/` ✅ | `SyncSDK.initialize(config, getIt)` — called in `main.dart` | sqflite |
| `push_notifications/` | `PushNotificationsModule.initialize(getIt, config: ...)` | firebase_messaging |
| `crash_reporting/` | `CrashReportingModule.initialize(enabled: kReleaseMode)` | firebase_crashlytics |
| `analytics/` | `AnalyticsModule.initialize(getIt, enabled: kReleaseMode)` | firebase_analytics |
| `remote_config/` | `RemoteConfigModule.initialize(getIt, defaults: {...})` | firebase_remote_config |
| `in_app_updates/` | `InAppUpdatesModule.checkAndPrompt(context)` | in_app_update |

---

## Dependency Rules

```text
foundation    → nothing (no platform, no infra, no Flutter, no Dio)
platform      → foundation only
infra         → foundation + platform only
di            → everything (composition root — استثناء مقصود)
modules       → foundation + infra only (NOT Features, NOT presentation)
Features      → foundation + infra + modules (NOT other Features)
presentation  → foundation + infra + platform (للـ AppLocale فقط عبر locale/)

core          → Features      NEVER (except di/)
core          → presentation  NEVER (except di/)
core          → routes        NEVER (except di/)
modules       → Features      NEVER
modules       → presentation  NEVER
```

---

## Feature Structure

```text
Features/<name>/
  data/       datasources, models, repositories
  domain/     entities, repositories (interface), usecases
  presentation/   cubits, pages
```

---

## Request Flow (REST)

```text
Page → Cubit → UseCase → Repository → RemoteDataSource → ApiService → Dio
Errors:
  DioException              → DioFailureMapper         → Failure
  FormatException / TypeError → FailureMapperRegistry  → ParseFailure
  Other                     → FailureMapperRegistry    → UnknownFailure
                                                           ↓
                                                  FailureUiMapper → UiAction
```

---

## Workflow

```bash
dart run scripts/feature_generator.dart
dart run scripts/sync_permissions.dart      # after changing AppFeatures flags
dart run build_runner build --delete-conflicting-outputs
dart analyze lib
```

---

## Future Ideas Backlog

> مقترحات لتحسين التيمبلت — لم تُنفَّذ بعد.

| # | الفكرة | الغرض | الأولوية |
|---|--------|--------|----------|
| N1 | **UserPreferencesService** | typed wrapper حول `StorageService` للإعدادات المستخدم (locale، theme، notifications) | 🔴 عالية |
| N2 | **DeepLinkService** | تمرير push notification taps + URL schemes بشكل موحّد للـ router | 🔴 عالية |
| N3 | **FormValidator utility** | استخدام Value Objects + ValidationFailure في validation مركزي لنماذج `form_builder` | 🟡 متوسطة |
| N4 | **AppUpdateChecker** | يجمع `RemoteConfigModule` (min_version) مع `InAppUpdatesModule` في utility واحد | 🟡 متوسطة |
| N5 | **ConnectivityBanner widget** | `shared/` widget يعرض شريط offline تلقائياً عبر `ConnectivityCubit` | 🟡 متوسطة |
| N6 | **AnalyticsRouteObserver** | `RouteObserver` يُسجّل screen views تلقائياً لكل route دون كود يدوي | 🟢 منخفضة |
| N7 | **UserSession** | كيان مركزي لـ userId + token + role — يُستخدم من Crashlytics + Analytics + AuthInterceptor | 🟢 منخفضة |

---

## Reference Patterns in `new/`

> موجودة كمراجع — تُرقَّى إلى `lib/` عند الحاجة.

| المجلد | المحتوى | الحالة |
|--------|---------|--------|
| ~~`new/01_connectivity/`~~ | ~~ConnectivityService + NetworkManager~~ | ✅ رُقِّي إلى `platform/connectivity/` |
| `new/05_sync/` | `NetworkStabilityProbe`, `SyncManager` | مرجع |
| `new/07_sync_widgets/` | `OfflineBanner`, `OfflineConnectivityLayer` | مرجع — ذات صلة بـ N5 |
| `new/08_local_storage/` | `KeyValueStore` abstraction | مرجع |

---

*Last updated: 2026-06-17*
