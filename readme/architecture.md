# Architecture Guide

> **المرجع الكامل:** [`core_architecture.md`](core_architecture.md) — اقرأه قبل أي تعديل معماري.  
> **مزامنة إلزامية:** عند تغيير الكود → حدّث readme المرتبط (انظر القسم 0 في `core_architecture.md`).

This template uses **Clean Architecture** with **feature-based organization**. **REST only** in `lib/`.

---

## Documentation Index

> **الفهرس كامل** — كل ملف `.md` بالمستودع مذكور هنا. ملفٌ يُضاف بلا سطر هنا يصير غير مكتشَف: القارئ لا يبحث عمّا لا يعلم بوجوده.

### ابدأ من هنا

| File | When to read / update |
|------|----------------------|
| [`core_architecture.md`](core_architecture.md) | **الأساس** — المبادئ، الطبقات، قواعد التعديل |
| [`new_developer_guide.md`](new_developer_guide.md) | Onboarding، أول تشغيل، feedback & locale API |
| [`../CLAUDE.md`](../CLAUDE.md) | جدول القرار + قانون المرآة + مزامنة التوثيق الإلزامية |

### الطبقات والأنماط

| File | When to read / update |
|------|----------------------|
| [`rest_api.md`](rest_api.md) | REST endpoints، مسارات الاستيراد، الأخطاء الشائعة، التوليد |
| [`error_flow.md`](error_flow.md) | **مسار الخطأ كاملاً عبر النصفين** — ترتيب الـinterceptors، `Failure`→`UiAction`، `error-handler.ts`، أخطاء المستخدم المتوقَّعة |
| [`pagination.md`](pagination.md) | قوائم بتمرير لا نهائي — المرجع الحيّ `Features/notes/` |
| [`widgets.md`](widgets.md) | **أين** يوضع الـwidget |
| [`widgets_usage.md`](widgets_usage.md) | **كيف** يُستعمل كل widget — أمثلة كاملة |
| [`../lib/core/infra/network/NETWORK.md`](../lib/core/infra/network/NETWORK.md) | الـinterceptors، الكاش، إعادة المحاولة، `TokenRefresh`، `BaseRepository` |
| [`../lib/core/platform/PLATFORM_SERVICES.md`](../lib/core/platform/PLATFORM_SERVICES.md) | خدمات المنصّة الاختيارية — التفعيل والاستخدام |

### الموديولات الاختيارية

| File | When to read / update |
|------|----------------------|
| [`permissions.md`](permissions.md) | `modules/access_control/` + `core/authz/` — الصلاحيات |
| [`data_transfer.md`](data_transfer.md) | `modules/data_transfer/` — الاستيراد والتصدير |
| [`sync.md`](sync.md) | **Offline Sync — Engineering Reference** (المرجع القاطع) |
| [`../lib/modules/sync/SETUP.md`](../lib/modules/sync/SETUP.md) | Sync — إعداد سريع (اقرأه أولاً) |
| [`../lib/modules/multi_device/README.md`](../lib/modules/multi_device/README.md) | الأجهزة والجلسات النشطة |
| `../lib/modules/*/SETUP.md` | analytics · crash_reporting · push_notifications · remote_config · in_app_updates |

### العمليات والخارطة

| File | When to read / update |
|------|----------------------|
| [`scripts.md`](scripts.md) | السكربتات، البناء والإصدار، التوليد، حلّ المشاكل |
| [`template_enhancements.md`](template_enhancements.md) | خارطة تطوير القالب — جدول الحالة + تفاصيل كل بند |
| [`test_scenarios_roadmap.md`](test_scenarios_roadmap.md) | سيناريوهات `Features/test/` — قانون المرآة |
| [`integration_audit.md`](integration_audit.md) | **سجلّ تاريخي** — تدقيق عقد الـwire (2026-08-11) وإصلاحه (2026-08-12) |
| [`template_vs_qirtas.md`](template_vs_qirtas.md) | **قراءة لحظية** — انحراف القالب عن قرطاس بالاتجاهين (2026-08-17) + أولويات النقل. لا يُصان: يُعاد التدقيق ويُعاد كتابته |
| [`realtime_design.md`](realtime_design.md) | **تصميم لم يُبنَ** — مزامنة الجلسات اللحظية بين الأجهزة. لا كود له بالقالب |

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
│   │                 auth_network_gateway, locale_provider, token_refresh_gateway
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
│   ├── features/     app_features (central toggle)
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
│   ├── errors/       failure_mapper, dio_failure_mapper, failure_mapper_registry,
│   │                 server_message_extractor
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

> **نقطة التفعيل الوحيدة**: `ModulesBootstrap.initializeAll(getIt)` بـ`main.dart`
> بعد `configureInjection()` مباشرة — **لا يُستدعى أي موديول من `main.dart` مباشرةً**،
> والترتيب مفروض بالكود هناك لا بالتعليقات. كل وحدة تحتوي `SETUP.md` بخطوات التفعيل.

| Module | العلَم (`AppFeatures`) | افتراضياً | نقطة التفعيل | Packages |
|---|---|---|---|---|
| `data_transfer/` | `dataTransfer` | ✅ **ON** | `DataTransferPlugin.initialize(di)` | dio · file_picker |
| `access_control/` | `accessControl` | ⬜ OFF | `AccessControlPlugin.initialize(di)` | dio (retrofit) |
| `multi_device/` | `multiDevice` | ⬜ OFF | `MultiDevicePlugin.initialize(di)` | dio (retrofit) |
| `sync/` | `offlineSync` | ⬜ OFF | `SyncSDK.initialize(config, di)` | sqflite |
| `push_notifications/` | `pushNotifications` | ⬜ OFF | `PushNotificationsModule.initialize(di)` | firebase_messaging |
| `crash_reporting/` | `crashReporting` | ⬜ OFF | `CrashReportingModule.initialize()` | firebase_crashlytics |
| `analytics/` | `analytics` | ⬜ OFF | `AnalyticsModule.initialize(di)` | firebase_analytics |
| `remote_config/` | `remoteConfig` | ⬜ OFF | `RemoteConfigModule.initialize(di)` | firebase_remote_config |
| `in_app_updates/` | `inAppUpdates` | ⬜ OFF | `InAppUpdatesModule.checkAndPrompt(context)` — **من شاشة لا من `ModulesBootstrap`** (يحتاج `BuildContext`)، والحارس داخل الدالة | in_app_update |

> **العَلَم هو العمود المهم.** الجدول السابق لم يحمله، فكان يقرأ الجميعَ كموصولين —
> و`sync/` كان موسوماً `✅` مع «called in `main.dart`»، وهو **مطفأ** ولا يُستدعى من
> `main.dart` بل من `ModulesBootstrap` تحت شرط. و`data_transfer/` — الموديول الوحيد
> المشتعل افتراضياً — **كان غائباً عن الجدول تماماً** (صُحِّح 2026-08-17).
>
> **و`in_app_updates/` هو النموذج الصحيح لموديول لا يمرّ بـ`ModulesBootstrap`**:
> يحتاج `BuildContext` فلا مكان له بالإقلاع، **فحمل عَلَمه وحارسه داخل دالته**
> (`if (!AppFeatures.inAppUpdates) return;`). الشكل الخاطئ — كود كامل بلا علم وبلا
> حارس — لا يُطفأ لأنه لا يُشعَل، ووقع فعلاً بمشروع قرطاس المبنيّ على هذا القالب.

> `realtime/` **لم يعد موجوداً بـ`lib/modules/`** — كان مجلداً يحوي وثيقة تصميم بلا سطر Dart واحد، فيُقرأ من شجرة المجلدات موديولاً قائماً. نُقلت الوثيقة إلى [`realtime_design.md`](realtime_design.md) وحُذف المجلد (2026-08-17). **مجلد فارغ باسم ميزة هو ادّعاء بوجودها.**

---

## 🧟 جرد «المبنيّ بلا مستهلك»

**بمستودع قالب، هذا هو الوضع الطبيعي لمعظم الموديولات** — تُشحن مطفأة ليُشعلها
المشروع. ولهذا بالذات يجب أن يكون الجرد مكتوباً: التمييز بين *سطحٍ يُقصد أن ينتظر*
و*سلسلةٍ انقطعت بالخطأ* لا يقوم به المصرِّف ولا `dart analyze` ولا الاختبارات —
**كلها خضراء في الحالتين**. الفرق أن الأول له علم يُشعله، والثاني لا.

| ما هو | الحالة |
|---|---|
| `presentation/shared/mutation_result.dart` | **لا يستورده شيء بالقالب** — البند #19 كان `✅` بجدول [`template_enhancements.md`](template_enhancements.md) بمعنى «الملف وصل». النمط يُغلق حين يستهلكه أول cubit طفرة هنا |
| `presentation/shared/sync/widgets/` (`SyncUiHost` · `PendingChangesChip`) | يتراجعان لبعضهما ولا يركّبهما شيء — `sync` مطفأ أصلاً |
| `core/foundation/extensions/num_extensions.dart` · `platform/extensions/{string,datetime}_extensions.dart` | ثلاثة ملفات **لا يستوردها أي ملف** |
| `core/foundation/value_objects/` | جزيرة مغلقة: الثلاثة يصدّرها الـbarrel، والـbarrel لا يستورده أحد |
| `platform/storage/adapters/shared_prefs_storage_adapter.dart` | محوِّل بديل — المُسجَّل فعلاً هو `HiveStorageAdapter` |
| `resources/fonts.dart` (`AppFontFamilies`) | مولَّد بـ`sync_fonts.dart` ولا يقرأه شيء — مصدر الحقيقة المستعمَل `core/infra/config/app_fonts.dart` |
| `modules/sync/sync_plugin.dart` | **مدخل ثانٍ ميت** — `ModulesBootstrap` يستدعي `SyncSDK.initialize` من `sdk/sync_sdk.dart` |
| barrels `modules/{analytics,crash_reporting,in_app_updates,push_notifications,remote_config}/<name>.dart` | ملفات `export` لا يستوردها أحد — `ModulesBootstrap` يستورد `*_module.dart` مباشرةً |

**حُذف بدل أن يُدرَج** (2026-08-17): `resources/translations/locale_keys.g.dart`
(نسخة قديمة بـ٥٨ مفتاحاً بجوار الحيّة بـ٦٠٤) · `modules/multi_device/domain/failures/`
(ملف re-export بلا مستورِد) — إضافةً إلى ما حُذف بنفس الجولة (`session_reader` ·
`base_cancel_token` · `dio_cancel_token_wrapper` · `prefetch_stage_exception` ·
`updated_at_filter` · `network_stability_probe` · `feature_permission_map` ·
`app_text_styles` · `default_svg_img`).

> **أي شيء تُنهي وصله: احذف صفّه من الجرد بنفس التغيير.** جردٌ يذكر موصولاً يُدرّب
> القارئ على تجاهل الجرد كلّه.

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
# feature جديدة: أنشئ data/domain/presentation يدوياً تحت Features/<name>/ ثم:
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
| N5 | **ConnectivityBanner widget** | `shared/` widget يعرض شريط offline تلقائياً عبر `ConnectivityCubit` (انظر `readme/sync.md` لمرجع `OfflineBanner`/`OfflineConnectivityLayer` المخطَّط) | 🟡 متوسطة |
| N6 | **AnalyticsRouteObserver** | `RouteObserver` يُسجّل screen views تلقائياً لكل route دون كود يدوي | 🟢 منخفضة |
| N7 | **UserSession** | كيان مركزي لـ userId + token + role — يُستخدم من Crashlytics + Analytics + AuthInterceptor | 🟢 منخفضة |

---

*Last updated: 2026-07-23 — أُزيلت إشارات لمجلد `new/` غير الموجود (GraphQL backup، reference patterns) وقاعدة Cursor المحذوفة؛ أُضيف `multi_device/` لجدول Optional Modules؛ صُحِّح سطر `feature_generator.dart` غير الموجود.*
