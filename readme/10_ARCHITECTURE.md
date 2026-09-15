# Architecture Guide

> **المرجع الكامل:** [`11_CORE.md`](11_CORE.md) — اقرأه قبل أي تعديل معماري.  
> **مزامنة إلزامية:** عند تغيير الكود → حدّث readme المرتبط (انظر القسم 0 في `11_CORE.md`).

This template uses **Clean Architecture** with **feature-based organization**. **REST only** in `lib/`.

---

## Documentation Index

> **الفهرس كامل** — كل ملف `.md` بالمستودع مذكور هنا. ملفٌ يُضاف بلا سطر هنا يصير غير مكتشَف: القارئ لا يبحث عمّا لا يعلم بوجوده.

### ابدأ من هنا

| File | When to read / update |
|------|----------------------|
| [`11_CORE.md`](11_CORE.md) | **الأساس** — المبادئ، الطبقات، قواعد التعديل |
| [`00_START_HERE.md`](00_START_HERE.md) | Onboarding، أول تشغيل، feedback & locale API |
| [`../CLAUDE.md`](../CLAUDE.md) | جدول القرار + قانون المرآة + مزامنة التوثيق الإلزامية |

### الطبقات والأنماط

| File | When to read / update |
|------|----------------------|
| [`12_REST_API.md`](12_REST_API.md) | REST endpoints، مسارات الاستيراد، الأخطاء الشائعة، التوليد |
| [`13_ERROR_FLOW.md`](13_ERROR_FLOW.md) | **مسار الخطأ كاملاً عبر النصفين** — ترتيب الـinterceptors، `Failure`→`UiAction`، `error-handler.ts`، أخطاء المستخدم المتوقَّعة |
| [`14_PAGINATION.md`](14_PAGINATION.md) | قوائم بتمرير لا نهائي — بلا مرجع حيّ بالقالب اليوم |
| [`20_WIDGETS.md`](20_WIDGETS.md) | **أين** يوضع الـwidget |
| [`21_WIDGETS_USAGE.md`](21_WIDGETS_USAGE.md) | **كيف** يُستعمل كل widget — أمثلة كاملة |
| [`../lib/core/infra/network/NETWORK.md`](../lib/core/infra/network/NETWORK.md) | الـinterceptors، الكاش، إعادة المحاولة، `TokenRefresh`، `BaseRepository` |
| [`../lib/core/platform/PLATFORM_SERVICES.md`](../lib/core/platform/PLATFORM_SERVICES.md) | خدمات المنصّة الاختيارية — التفعيل والاستخدام |

### الموديولات الاختيارية

| File | When to read / update |
|------|----------------------|
| [`31_MODULE_PERMISSIONS.md`](31_MODULE_PERMISSIONS.md) | `modules/access_control/` + `core/authz/` — الصلاحيات |
| [`32_MODULE_DATA_TRANSFER.md`](32_MODULE_DATA_TRANSFER.md) | `modules/data_transfer/` — الاستيراد والتصدير |
| [`sync_design_spec.md`](90_archive/sync_design_spec.md) | **Offline Sync — Engineering Reference** (المرجع القاطع) |
| [`../lib/modules/sync/SETUP.md`](../lib/modules/sync/SETUP.md) | Sync — إعداد سريع (اقرأه أولاً) |
| [`../lib/modules/multi_device/README.md`](../lib/modules/multi_device/README.md) | الأجهزة والجلسات النشطة |
| `../lib/modules/*/SETUP.md` | analytics · crash_reporting · push_notifications · remote_config · in_app_updates · session_guard · notification_center |

### العمليات والخارطة

| File | When to read / update |
|------|----------------------|
| [`40_SCRIPTS.md`](40_SCRIPTS.md) | السكربتات، البناء والإصدار، التوليد، حلّ المشاكل |
| [`90_archive/template_enhancements.md`](90_archive/template_enhancements.md) | خارطة تطوير القالب — جدول الحالة + تفاصيل كل بند |
| [`90_archive/integration_audit.md`](90_archive/integration_audit.md) | **سجلّ تاريخي** — تدقيق عقد الـwire (2026-08-11) وإصلاحه (2026-08-12) |
| [`90_archive/template_enhancements.md`](90_archive/template_enhancements.md) | **قراءة لحظية** — انحراف القالب عن قرطاس بالاتجاهين (2026-08-17) + أولويات النقل. لا يُصان: يُعاد التدقيق ويُعاد كتابته |
| [`90_archive/realtime_design.md`](90_archive/realtime_design.md) | **تصميم لم يُبنَ** — مزامنة الجلسات اللحظية بين الأجهزة. لا كود له بالقالب |

---

## `lib/` Structure

| Folder | Role |
|--------|------|
| `lib/core/` | Shared infrastructure — `foundation/`, `platform/`, `infra/`, `di/` |
| `lib/modules/` | Optional runtime modules — each has `SETUP.md` + entry point |
| `lib/features/` | Isolated business features — data / domain / presentation |
| `lib/ui/` | The whole shared UI layer — `widgets/` (barrel: `widgets.dart`) · `theme/` · `state/` · `error/` · `feedback/` · `locale/` · `extensions/` |
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
| `in_app_updates/` | `inAppUpdates` | ⬜ OFF | `InAppUpdatesModule.initialize(di)` بـ`ModulesBootstrap` + `AppUpdateGate` بالقشرة | in_app_update · package_info_plus · url_launcher |
| `session_guard/` | `sessionGuard` | ⬜ OFF | `SessionGuardPlugin.initialize(di)` بـ`ModulesBootstrap` + `SessionGuardGate` بالقشرة (الأعلى بين المعلِنَين — راجع `main_shell_page.dart`) | crypto (بصمة الرقم — لا تبعية خارجية أخرى) |
| `notification_center/` | `notificationCenter` | ⬜ OFF | `NotificationCenterPlugin.initialize(di)` بـ`ModulesBootstrap` — يستهلك بثّ `push_notifications` (`pushNotifications` يجب أن يكون مُشعلاً أيضاً)، ولا يستدعي FCM بذاته | لا تبعية خارجية إضافية |

> **العَلَم هو العمود المهم.** الجدول السابق لم يحمله، فكان يقرأ الجميعَ كموصولين —
> و`sync/` كان موسوماً `✅` مع «called in `main.dart`»، وهو **مطفأ** ولا يُستدعى من
> `main.dart` بل من `ModulesBootstrap` تحت شرط. و`data_transfer/` — الموديول الوحيد
> المشتعل افتراضياً — **كان غائباً عن الجدول تماماً** (صُحِّح 2026-08-17).
>
> **و`in_app_updates/` هو النموذج الصحيح لموديول لا يمرّ بـ`ModulesBootstrap`**:
> يحتاج `BuildContext` فلا مكان له بالإقلاع، **فحمل عَلَمه وحارسه داخل دالته**
> (`if (!AppFeatures.inAppUpdates) return;`). الشكل الخاطئ — كود كامل بلا علم وبلا
> حارس — لا يُطفأ لأنه لا يُشعَل، ووقع فعلاً بمشروع قرطاس المبنيّ على هذا القالب.

> ✅ **و`in_app_updates/` صار يُولد بثلاثته (2026-09-09)** — وكان مثالَ R29 الحيّ:
> كودٌ كامل وثلاثُ تبعيّاتٍ تُشحن، **بلا سطرٍ بـ`ModulesBootstrap`**. وموضعُ
> النقص كان بنيوياً لا سهواً: الحوارُ يحتاج `BuildContext` فلا مكان له بالإقلاع.
> فانقسم الموديول نصفين — `initialize(di)` يسجّل **اللقطة المحلّية ومهمّةَ
> تحديثها بدورة المزامنة** ولا يطلب الشبكة، و`AppUpdateGate` بالقشرة يقرأ اللقطة
> عند التركيب ويستمع لتبدّلها. فيصل قرارٌ جديد **فور انتهاء الدورة** بلا أن
> تسأل شاشةٌ شيئاً.
>
> ⚠️ **ونقطتُه `GET /api/v1/settings` ليست عقداً عامّاً** — تردّ قائمةَ
> `{key, value, isActive}` ويُقرأ منها `app_version` و`app_download_url` و
> `force_update`. بدّلها بما يخدمه باكُك، أو بدّل `AppUpdateSettings.fromEntries`.
>
> ⛔ **وتبعيّةُ المزامنة محصورةٌ بملفٍّ واحد** — `integration/app_update_settings_refresh_task.dart`
> — لأن `test/sync/deletion_contract_test.dart` يشهد على أن حذفَ المزامنة حذفُ
> مجلَّد. حتى الوسيطُ النوعيُّ `SyncRefreshTask` لا يُكتب بملفّ المدخل.

> `realtime/` **لم يعد موجوداً بـ`lib/modules/`** — كان مجلداً يحوي وثيقة تصميم بلا سطر Dart واحد، فيُقرأ من شجرة المجلدات موديولاً قائماً. نُقلت الوثيقة إلى [`90_archive/realtime_design.md`](90_archive/realtime_design.md) وحُذف المجلد (2026-08-17). **مجلد فارغ باسم ميزة هو ادّعاء بوجودها.**

---

## 🧟 جرد «المبنيّ بلا مستهلك»

**بمستودع قالب، هذا هو الوضع الطبيعي لمعظم الموديولات** — تُشحن مطفأة ليُشعلها
المشروع. ولهذا بالذات يجب أن يكون الجرد مكتوباً: التمييز بين *سطحٍ يُقصد أن ينتظر*
و*سلسلةٍ انقطعت بالخطأ* لا يقوم به المصرِّف ولا `dart analyze` ولا الاختبارات —
**كلها خضراء في الحالتين**. الفرق أن الأول له علم يُشعله، والثاني لا.

| ما هو | الحالة |
|---|---|
| `ui/state/mutation_result.dart` | **لا يستورده شيء بالقالب** — البند #19 كان `✅` بجدول [`90_archive/template_enhancements.md`](90_archive/template_enhancements.md) بمعنى «الملف وصل». النمط يُغلق حين يستهلكه أول cubit طفرة هنا |
| `ui/state/sync/widgets/` (`SyncUiHost` · `PendingChangesChip`) | يتراجعان لبعضهما ولا يركّبهما شيء — `sync` مطفأ أصلاً |
| `core/foundation/extensions/num_extensions.dart` · `platform/extensions/{string,datetime}_extensions.dart` | ثلاثة ملفات **لا يستوردها أي ملف** |
| `core/foundation/value_objects/` | جزيرة مغلقة: الثلاثة يصدّرها الـbarrel، والـbarrel لا يستورده أحد |
| `modules/sync/domain/sync_failure_report.dart` | **حصيلةُ إخفاقٍ بأسماء حقولها لا بنصِّ الخادم** — يكتبها منفّذُ الشريحة ويقرؤها من يعرض الطابور. مُصدَّرةٌ وبلا كاتبٍ هنا. ⚠️ **والترجمةُ عند العرض لا عند التخزين**: `last_error` يُكتب مرّةً ويُقرأ مراراً واللغةُ تتبدّل بينهما، فالمخزَّنُ **مساراتُ حقولٍ لا نثرٌ** |
| `modules/sync/domain/sync_activity.dart` | **لقطةُ طور الدفع** — «الصفُّ الثالث من سبعة». تبثّها الدورةُ ولا شاشةَ تقرؤها |
| `modules/sync/data/sync_bootstrap_stamp.dart` + `engine/sync_bootstrap_progress.dart` | **هل جُرد هذا الحساب على هذا الجهاز، وأين وصل الجرد** — الختمُ يفصل «أوّل دخول» عن «إقلاعٌ عاديّ»، والتقدّمُ يقول للواقف ينتظر كم وصل. ⛔ **ولا شريحةَ جردٍ بالقالب**، فهما سطحٌ ينتظرها |
| `modules/sync/engine/attachment_upload_progress.dart` | **نبضُ «كم صعد من هذا الملفّ»** — موصولٌ بالمدير ومسجَّلٌ بالـDI، وبلا شاشةٍ تقرؤه. ⚠️ **يُبَثّ ولا يُخزَّن**، ويُفرَغ بـ`finally` على الطريقين: كسرةٌ متروكة عند ٠٫٧ لملفٍّ أُكِّد تجعل الشاشة تخلط «انتهى» بـ«توقّف عند سبعين بالمئة» |
| `modules/sync/engine/sync_row_mapper.dart` | **كيف يُقرأ صفُّ الخادم** — الموديولُ يملك متى يُسأل ومَن يُسأل، والشريحةُ تملك قراءةَ الجواب. عقدٌ بلا منفّذ |
| `modules/sync/engine/sync_urls.dart` · `rest_attachment_upload_target.dart` | **مسارُ المرفقات وجسدُ رفعها** — ⛔ **ولا نقطةَ لها بأيّ باكٍ افتراضيّ**: تُبدَّل بما يخدمه باكُك، والهدفُ يُسجَّل بالـDI لتُسمّي كلُّ شريحةٍ كيانَها |
| `modules/sync/integration/sync_private_file_ingest_service.dart` | **منفّذُ `PrivateFileIngestService` فوق مخزن المرفقات** — يُسجَّل بالـDI حين تريد شريحةٌ أن يسكن ملفُّها التخزينَ الخاصّ ويُمحى مع الحساب |
| `modules/in_app_updates/**` | **تحديثُ التطبيق بإعداداتٍ يملكها الخادم** — موصولٌ بثلاثته (علَم · سطرُ إقلاع · صفُّ جدول) و`AppUpdateGate` مركَّبٌ بالقشرة، **والعلَمُ مطفأ**. ⚠️ **ونقطتُه `GET /api/v1/settings` ليست عقداً عامّاً**: تُبدَّل بما يخدمه باكُك، أو يُبدَّل `AppUpdateSettings.fromEntries` وحده |
| `core/infra/session/welcome_greeting.dart` | **رايةُ «رحِّب بهذا الداخل»** — مستهلكُها `WelcomeAnnouncer` مركَّبٌ بالقشرة، **ولا رافعَ لها**: `raise()` تُنادى ممّن يعرف متى صار الحسابُ جاهزاً — كيوبتِ الدخول، أو ذيلِ أوّل جردٍ إن أُشعلت المزامنة. ⚠️ **ونصُّ `welcomeReady` يُبدَّل مع الرافع**: الجملةُ تصف ما تغيّر فعلاً |
| `modules/sync/domain/sync_media_catalog.dart` + `engine/media_prefetch_manager.dart` | **تنزيلُ الصور والملفّات** — الطورُ السادس موصولٌ بذيل الدورة وخارج القفل، ومسجَّلٌ بالـDI. وبلا جردِ شريحةٍ يسقط الطورُ بفحصٍ واحد (`allOf`) |
| `modules/sync/domain/sync_job_explainer.dart` | **ماذا سيصل الخادمَ من هذا الصفّ وما الذي يحجز الباقي** — تنفّذه الشريحة، ويقرؤه من يعرض الطابور. مُصدَّرٌ وبلا منفّذ |
| `modules/sync/domain/sync_refresh_task.dart` + `sync_hydration.dart` | عقدان مسجَّلان ومُصدَّران، والمحرّك ينادي الأوّل بذيل الدورة — **وبلا منفّذٍ بالقالب**. النمطان بـ`lib/modules/sync/SETUP.md` §3e و§3f |
| `<feature>/data/sync/` (المنفذ الرابع بعقد الحذف — انظر §wire الحذف بالأسفل) | ⚠️ **صفر عقود منفَّذة اليوم.** المثال الوحيد (`features/notes/data/sync/`) حُذف مع تنظيف `notes/` بتاريخ 2026-09-08 — تنظيفٌ عامٌّ لا علاقة له بـsync. `getAll<SyncFeatureContractBase>()` يعيد صفراً فعلياً بكامل `lib/`، فتفعيل `AppFeatures.offlineSync` اليوم يترك التطبيق يعمل بالكامل على الشبكة **بصمت** — بلا انهيار ولا تحذير. الحالة المُحدَّثة والمرحلة المسنَدة بـ[`lib/modules/sync/PLAN.md`](../lib/modules/sync/PLAN.md) ب١٣/ب١٤ |
| `modules/access_control/presentation/pages/user_access_screen.dart` + مسار `/users/:userId/access` | **مبنيّةٌ بالكامل ولا نقطةَ دخولٍ إليها بالقالب** (2026-09-13). تحتاج `userId` محدداً، و«من هم المستخدمون وكيف تُعرض قائمتهم» قرارٌ يخصّ كل مشروع — بناء شاشة مستخدمين هنا يعيد القالب إلى «مثال CRUD» الذي حُذف عمداً بتنظيف 2026-09-08. المشروع يضيف زرّاً من شاشة مستخدميه الخاصة: `context.router.push(UserAccessRoute(userId: id))`، محميّاً بـ`Can(permission: PermKeys.userAccessView)`. **وشاشة الأدوار المقابلة (`RolesRoute`) عامّة فعلاً ووُصلت** بـ`AccessControlSection` بشاشة الإعدادات — الفرق أن الأدوار لا تفترض شيئاً عن نموذج المستخدمين بينما هذه الشاشة تفترض وجود واحد |
| `platform/location/device_location_service*.dart` | خدمةُ موقعٍ خلف عقد — **مشروطةٌ بـ`AppFeatures.location`** (مطفأة افتراضاً)، فبلا العلَم لا يُسجَّل شيء. وحزمةُ `geolocator` تبقى بالتبعيات: تُحذف من `pubspec.yaml` إن كان المشروع لا يحتاج موقعاً |
| `platform/files/private_file_ingest_service.dart` | عقدُ إدخال ملفٍّ إلى التخزين الخاصّ — بلا منفّذٍ ولا مستدعٍ |
| `foundation/utils/natural_order.dart` | ترتيبٌ طبيعيٌّ لمعرّفاتٍ مرقّمة («٩١/٢» قبل «٩١/١٠») |
| `ui/widgets/media/` (خمسُ ودجات) | **مرفقاتٌ ميدانية** — بطاقةٌ ومعاينةٌ وعارضٌ وفتحٌ بالنظام. مصدَّرةٌ بالـbarrel وبلا شاشةٍ تركّبها: تُغلق بأوّل استمارةٍ تلتقط صورة. ⚠️ **و`cacheWidth` ليس تحسيناً**: ستُّ صورِ كاميرا بلاه ≈ ٧٥ ميغابايت مقيمة |
| `ui/widgets/states/placeholder_screen.dart` · `inputs/app_radio_group.dart` · `indicators/progress_with_count.dart` · `connectivity/connectivity_dot.dart` · `extensions/byte_size_extension.dart` | ودجاتٌ عامّة مصدَّرة بلا مستهلكٍ بعد |
| `infra/files/server_file_cache.dart` + `foundation/utils/inline_file_data.dart` | **ملفّاتُ الخادم بتوكن** — كاشٌ دائم، تنزيلٌ بضغطةٍ لا مسبق، ويُمحى مع الحساب. مسجَّلٌ بالـDI وبلا مستدعٍ: يُغلق حين تعرض شاشةٌ مرفَقاً يملكه الخادم. ⚠️ **ونقطتُه (`ApiUrls.files`) ليست عقداً عامّاً** — تُبدَّل بما يخدمه باكُك |
| `platform/storage/offline_snapshot.dart` | **لقطةُ آخرِ ردٍّ ناجح، لا تنتهي** — نُقلت من مشروعٍ بلغ فيه المستهلكون ثلاثة. تُغلق حين تريد شاشةٌ جواباً خارج التغطية بعد انقضاء TTL المخبّئ |
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
              → استثناءٌ موثَّق: `ui/state/<module>/` يستورد `modules/<module>/`
                نفسَه فقط — محوّل UI خاص بموديول واحد، لا وصولٌ عامّ لـ modules/.
                المثال القائم: `ui/state/sync/**` يستورد `modules/sync/sync_plugin.dart` وحده

core          → Features      NEVER (except di/)
core          → presentation  NEVER (except di/)
core          → routes        NEVER (except di/)
modules       → Features      NEVER
modules       → presentation  NEVER
```

---

## Feature Structure

```text
features/<name>/
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
# feature جديدة: أنشئ data/domain/presentation يدوياً تحت features/<name>/ ثم:
dart run scripts/sync_platform_permissions.dart      # after changing AppFeatures flags
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
