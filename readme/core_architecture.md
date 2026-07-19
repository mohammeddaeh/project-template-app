# Core Architecture — المبادئ المرجعية للتيمبلت

> **استخدم هذا الملف** عند أي تعديل أو تفكير معماري في المشروع.
> القاعدة المرتبطة في Cursor: `.cursor/rules/core-architecture.mdc` (`alwaysApply: true`)

---

## 0. مزامنة التوثيق (إلزامي مع كل تعديل)

**كل تعديل على الكود يتطلب تحديث readme المرتبط — في نفس الجلسة / نفس الـ PR.**

### الـ README الرسمية (7 ملفات فقط)

| إذا غيّرت… | حدّث فوراً… |
|------------|-------------|
| مبادئ core، حدود الطبقات، هيكل core/ | `core_architecture.md` + `.cursor/rules/core-architecture.mdc` |
| REST، network، ApiService، Repository، Failure flow | `rest_api.md` |
| `presentation/feedback/` أو feedback API | `widgets.md` + `new_developer_guide.md` |
| `presentation/locale/` أو locale API | `widgets.md` + `new_developer_guide.md` |
| Pagination | `pagination.md` |
| Widgets / theme / presentation paths | `widgets.md` |
| Scripts، build/release، troubleshooting | `scripts.md` |
| Onboarding، هيكل lib/ | `new_developer_guide.md` + `architecture.md` |
| فهرس عام | `architecture.md` |
| GraphQL الاحتياطي | `new/09_graphql/README.md` فقط |

> `apigenerator.md` و`project_workflow.md` **محذوفان** — محتواهما مدمج في `rest_api.md` و`scripts.md`.

**قاعدة Cursor (`.cursor/rules/core-architecture.mdc`):** تُطبَّق تلقائياً في كل جلسة — تحوي نفس جدول الخريطة أعلاه.

---

## 1. الفكرة الأساسية

كل **تقسيمة** في `lib/core/` يجب أن تكون:

| المبدأ | المعنى |
|--------|--------|
| **مركزية** | مجلد واحد يجمع كل ما يحتاجه المشروع لهذا الموضوع |
| **مُجهَّزة** | التصنيف الداخلي جاهز — لا يُعاد اختراعه في كل Feature |
| **بسيطة من الخارج** | واجهة واحدة / أمر واحد للاستخدام |
| **قابلة للتخصيص** | التخصيص عند نقطة الاستخدام (Cubit / Feature) وليس داخل Core |

---

## 2. الهيكل الثلاثي لـ Core (الهدف الرسمي)

`lib/core/` مقسّم إلى **ثلاث طبقات داخلية**:

```
core/
├── foundation/    ← Pure Dart — لا Flutter، لا Dio، لا I/O
├── platform/      ← غلافات Flutter / OS / خدمات منصة
└── infra/         ← تنفيذ فعلي + شبكة + DI + إعدادات
```

### قاعدة الاعتماديات بين الطبقات

```
foundation  ──►  لا يستورد شيئاً من platform أو infra
platform    ──►  foundation فقط
infra       ──►  foundation + platform

Features    ──►  foundation + infra  (نادراً platform عبر infra)
presentation──►  foundation + infra  (للأخطاء عبر Failure فقط)
```

**القاعدة الذهبية:**
```
❌ foundation → platform   ممنوع
❌ foundation → infra      ممنوع
❌ platform   → infra      ممنوع
❌ core       → Features   ممنوع
❌ core       → presentation ممنوع
❌ core       → routes     ممنوع
```

---

## 3. محتوى كل طبقة

### 3.1 `foundation/` — Pure Logic

> لا يحتوي على أي استيراد لـ Flutter أو Dio أو SharedPreferences أو routes.
> Pure Dart فقط — قابل للاختبار بدون أي setup.

| التقسيمة | المحتوى |
|----------|---------|
| `foundation/errors/` | `Failure` sealed classes + `ParseFailure`(`ParseErrorKind`) + `ValidationFailure` + `PermissionFailure`(`PermissionDeniedReason`) + `StorageFailure`(`StorageOperation`) — أنواع فقط، لا mapping |
| `foundation/domain/` | `BaseUseCase`, `BaseCancelToken`, `Params`, `NoParams` |
| `foundation/contracts/` | `ApiResponse<T>`, `PaginationQuery`, `PaginationDataEntity` — عقود مشتركة |
| `foundation/extensions/` | `string_extensions`, `num_extensions`, `datetime_extensions` |
| `foundation/utils/` | `Validators` — قواعد نقية بدون UI |
| `foundation/value_objects/` | `Email`, `PhoneNumber`, `DateRange` — factory-only construction → `Either<ValidationFailure, T>` |

### 3.2 `platform/` — Wrappers

> غلاف رفيع حول قدرات المنصة. لا منطق أعمال — فقط تجريد.

| التقسيمة | المحتوى |
|----------|---------|
| `platform/logging/` | `LogService` (static) + `LogDelegate` (interface for swapping backend) |
| `platform/storage/` | `PersistenceKeys` (key constants) + `StorageService` + `SecureStorageService` + `EncryptionService` (interfaces) + `adapters/` (SharedPrefs, InMemory, FlutterSecureStorage, AES-256-CBC) |
| `platform/media/` | `MediaService` (interface) + `MediaServiceImpl` (image_picker + video_thumbnail) |
| `platform/launcher/` | `UrlLauncherService` (interface) + `UrlLauncherServiceImpl` (url_launcher) |
| `platform/observability/` | `CustomBlocObserver`, `BlocLogger` |
| `platform/extensions/` | `string_extensions`, `datetime_extensions` |
| `platform/config/` | `AppSettings` — runtime constants (kReleaseMode) |
| `platform/locale/` | `AppLocale` — enum: arabic/english + isRtl + fromCode |
| `platform/connectivity/` | `NetworkState`, `ConnectivityService` (static utility), `NetworkStateMonitor` (interface + impl), `NetworkStabilityProbe` (multi-ping reachability verifier � optional) |
| `platform/permissions/` | `AppPermission`, `AppPermissionStatus`, `PermissionsService` (interface + impl) |
| `platform/biometrics/` | `BiometricsService` (interface) + `BiometricsServiceImpl` (local_auth) |
| `platform/clipboard/` | `ClipboardService` (interface) + `ClipboardServiceImpl` (Flutter built-in) |
| `platform/share/` | `ShareService` (interface) + `ShareServiceImpl` (share_plus) |
| `platform/files/` | `FileService` (interface) + `FileServiceImpl` (file_picker + open_filex) |
| `platform/lifecycle/` | `AppLifecycleService` (interface) + `AppLifecycleServiceImpl` (WidgetsBindingObserver) |
| `platform/features/` | `AppFeatures` (central toggles), `feature_permission_map` |
| `platform/notifications/` | `LocalNotificationsService` (interface), `FlnNotificationsAdapter`, `DisabledNotificationsAdapter` |

### 3.3 `infra/` — Implementation

> التنفيذ الفعلي + الربط مع العالم الخارجي. يستورد Dio، SQLite، injectable.

| التقسيمة | المحتوى |
|----------|---------|
| `infra/config/` | `env.dart`, `env_config.dart`, `flavors_settings.dart` |
| `infra/network/rest/` | `api_urls.dart`, `handle_body_response.dart`, `updated_at_filter.dart` (delta-sync URL builder � optional) |
| `infra/network/interceptors/` | `auth_interceptor`, `internet_checker_interceptor`, `token_refresh_interceptor`, `retry_interceptor`, `request_cache_interceptor` |
| `infra/network/security/` | `certificate_pinning_config` — SHA-256 fingerprint pinning (OFF by default) |
| `infra/network/boundary/` | `base_repository.dart` — `handle()` للـ repositories |
| `infra/network/cancellation/` | `dio_cancel_token_wrapper.dart` |
| `infra/errors/` | `failure_mapper.dart`, `dio_failure_mapper.dart` (يصطاد `FormatException` المُغلَّف)، `failure_mapper_registry.dart` (`FormatException`/`TypeError` مباشرةً → `ParseFailure`)، `server_message_extractor.dart`, `prefetch_stage_exception.dart` |
| `infra/session/` | `auth_event_bus.dart`, `locale_provider_impl.dart` |

> **ملاحظة:** `core/di/` (injection.dart, injection_module.dart, injection.config.dart) هو جذر التركيب — مستوى مستقل يُوازي `foundation/` و`platform/` و`infra/`، وليس داخل `infra/`. مسموح له باستيراد كل شيء بما في ذلك Features/ و routes/.

---

## 4. الهيكل الكامل المستهدف

```text
lib/core/
│
├── foundation/                      ← Pure Dart — لا Flutter، لا Dio
│   ├── errors/
│   │   └── failure.dart             ← sealed Failure types + ParseFailure + ValidationFailure + PermissionFailure + StorageFailure
│   ├── domain/
│   │   ├── base_usecase.dart
│   │   ├── base_cancel_token.dart
│   │   ├── use_case_params.dart
│   │   └── no_params.dart
│   ├── contracts/
│   │   ├── api_response.dart        ← ApiResponse<T> + ApiError
│   │   ├── pagination_query.dart
│   │   ├── pagination_data_entity.dart
│   │   ├── auth_network_gateway.dart ← interface: getToken() + clearSession()
│   │   ├── locale_provider.dart     ← interface: languageCode
│   │   └── session_reader.dart      ← interface: getUserId()
│   ├── extensions/
│   │   └── num_extensions.dart      ← (string/datetime في platform/extensions/)
│   ├── utils/
│   │   └── validators.dart
│   └── value_objects/
│       ├── email.dart               ← Email.validate(input) → Either<ValidationFailure, Email>
│       ├── phone_number.dart        ← PhoneNumber.parse('+966...') → Either<...>
│       ├── date_range.dart          ← DateRange.create(from:, to:) → Either<...>
│       └── value_objects.dart       ← barrel export
│
├── platform/                        ← Flutter / OS wrappers
│   ├── config/
│   │   └── app_settings.dart        ← kReleaseMode, build constants
│   ├── extensions/
│   │   ├── string_extensions.dart
│   │   └── datetime_extensions.dart
│   ├── locale/
│   │   └── app_locale.dart          ← enum: arabic/english + isRtl + fromCode
│   ├── logging/
│   │   └── log_service.dart           (static API + LogDelegate interface)
│   ├── storage/
│   │   └── persistence_keys.dart
│   ├── media/
│   │   ├── media_service.dart         (abstract interface)
│   │   └── media_service_impl.dart    (image_picker + video_thumbnail)
│   ├── launcher/
│   │   ├── url_launcher_service.dart      (abstract interface)
│   │   └── url_launcher_service_impl.dart (url_launcher package)
│   ├── observability/
│   │   └── app_bloc_observer.dart
│   ├── connectivity/                ← ✅ P1
│   │   ├── network_state.dart
│   │   ├── connectivity_service.dart
│   │   ├── network_state_monitor.dart
│   │   └── network_state_monitor_impl.dart
│   ├── permissions/                 ← ✅ P2
│   │   ├── app_permission.dart
│   │   ├── app_permission_status.dart
│   │   ├── permissions_service.dart
│   │   └── permissions_service_impl.dart
│   ├── features/                    ← ✅ Feature Activation System
│   │   ├── app_features.dart        (central toggle — edit here to enable features)
│   │   └── feature_permission_map.dart (docs for sync_permissions.dart script)
│   ├── notifications/
│   │   ├── local_notifications_service.dart   (abstract interface)
│   │   └── adapters/fln_notifications_adapter, disabled_notifications_adapter
│   ├── storage/
│   │   ├── storage_service.dart         ← interface (key-value)
│   │   ├── secure_storage_service.dart  ← interface (tokens)
│   │   ├── encryption_service.dart      ← interface (AES-256-CBC)
│   │   ├── persistence_keys.dart
│   │   └── adapters/                    ← SharedPrefs, InMemory, FlutterSecureStorage, AES
│   ├── biometrics/   BiometricsService + impl        [AppFeatures.biometrics]
│   ├── clipboard/    ClipboardService + impl         [AppFeatures.clipboard]
│   ├── share/        ShareService + impl             [AppFeatures.shareSheet]
│   ├── files/        FileService + impl              [AppFeatures.fileOperations]
│   └── lifecycle/    AppLifecycleService + impl      [AppFeatures.appLifecycle]
│
├── infra/                           ← Implementation
│   ├── config/
│   │   ├── env.dart
│   │   ├── env_config.dart
│   │   └── flavors_settings.dart
│   ├── network/
│   │   ├── rest/
│   │   │   ├── api_urls.dart
│   │   │   └── handle_body_response.dart
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart
│   │   │   ├── internet_checker_interceptor.dart
│   │   │   ├── token_refresh_interceptor.dart    ← 401 → refresh → retry
│   │   │   ├── retry_interceptor.dart            ← 5xx/network → exponential back-off
│   │   │   └── request_cache_interceptor.dart    ← GET cache بـ TTL في StorageService
│   │   ├── security/
│   │   │   └── certificate_pinning_config.dart   ← SHA-256 fingerprint [AppFeatures.certificatePinning]
│   │   ├── boundary/
│   │   │   └── base_repository.dart
│   │   └── cancellation/
│   │       └── dio_cancel_token_wrapper.dart
│   ├── errors/
│   │   ├── failure_mapper.dart
│   │   ├── dio_failure_mapper.dart
│   │   ├── failure_mapper_registry.dart
│   │   ├── server_message_extractor.dart
│   │   └── prefetch_stage_exception.dart
│   └── session/
│       ├── auth_event_bus.dart
│       └── locale_provider_impl.dart  ← AppLocaleProvider @LazySingleton(as: LocaleProvider)
│
└── di/                              ← Composition root (injectable/GetIt)
    ├── injection.dart                    ← configureInjection() + يستدعي PlatformServicesRegistry.configure()
    ├── injection_module.dart             ← always-on bindings (Dio, Storage, Auth, Notifications)
    ├── platform_services_registry.dart  ← optional P6-P10 — مفعَّلة عبر AppFeatures فقط
    └── injection.config.dart            ← مولَّد تلقائياً (build_runner)
```

**خارج `core/` بالكامل:**

```text
presentation/     theme, extensions UI, FailureUiMapper, PaginationCubit
Features/         منطق أعمال + per-feature ApiService
shared/           widgets
new/              graphql, connectivity backup, …
```

---

## 5. تدفق الأخطاء (Error Flow)

```
Exception
  ├─ DioException            ─► DioFailureMapper
  │     └─ error is FormatException ─► ParseFailure(malformedJson)
  ├─ FormatException (direct) ─► ParseFailure(malformedJson)
  ├─ TypeError (direct)       ─► ParseFailure(typeMismatch)
  └─ Other                    ─► UnknownFailure
        ↓ infra/errors/ — FailureMapperRegistry.map(error)
        ↓ foundation/errors/
  Failure (sealed type)
        ↓ presentation/error/   ← يبدأ هنا فقط الـ UI
  FailureUiMapper.toAction(failure)
        ↓
  UiAction (ShowError | NavigateToLogin | Silent)
        ↓ Feature/cubits/
  switch على كل حالة → emit State
```

**قواعد الأخطاء:**
- `foundation/errors/` = أنواع فقط — لا mapping، لا Dio، لا `.tr()`
- `infra/errors/` = mapping فقط — لا UI، لا localization
- `presentation/error/` = عرض فقط — لا منطق، لا Dio
- Repository = `handle()` من `BaseRepository` فقط — لا try/catch يدوي
- Cubit = `FailureUiMapper.toAction(failure)` فقط — لا يعرف DioException
- `ParseFailure` — أخطاء JSON parsing؛ `kind` و`fieldName` للـ logging فقط — لا تُعرض للمستخدم
- `ValidationFailure` — تحقق **محلي** فقط (form/value object)؛ لا يُنتَج من `FailureMapperRegistry`؛ `fields` map لتظليل حقول بعينها
- `PermissionFailure` — يُنتَج من `PermissionsService`؛ `reason` يحدد سلوك UI (إعادة طلب / فتح الإعدادات / معلومات فقط)
- `StorageFailure` — يُنتَج من `StorageService`/`SecureStorageService`؛ `operation`+`key` للـ logging فقط

---

## 6. تدفق REST API (Request Flow)

```
Page / Screen
    │
    ▼ Features/*/presentation/cubits/
Cubit.callMethod()
    │
    ▼ Features/*/domain/usecases/
UseCase(params)   ← DioCancelTokenWrapper من infra/network/cancellation/
    │
    ▼ Features/*/domain/repositories/ (interface)
    ▼ Features/*/data/repositories/  (impl)
BaseRepository.handle(call)   ← من infra/network/boundary/
    │
    ▼ Features/*/data/datasources/
RemoteDataSource
    │
    ▼ Features/*/data/datasources/*_api_service.dart
Retrofit ApiService
    │
    ▼ Dio  ← من infra/di/injection_module
        ↓  infra/network/interceptors/
        ↓  AuthInterceptor → AuthEventBus  (infra/session/)
        ↓  InternetCheckerInterceptor
    │
    ▼ Server
    │
    ◄── ApiResponse<T>  ← foundation/contracts/
    │
    ▼ Repository map → Either<Failure, Entity>
    ▼ UseCase → Cubit → emit State
```

---

## 7. هيكل Feature القياسي

```text
Features/<name>/
├── data/
│   ├── datasources/
│   │   ├── <name>_api_service.dart   ← Retrofit (feature-local)
│   │   └── <name>_remote_datasource.dart
│   ├── models/
│   └── repositories/
│       └── <name>_repository_impl.dart  ← extends BaseRepository
├── domain/
│   ├── entities/
│   ├── repositories/   ← interface
│   └── usecases/
└── presentation/
    ├── cubits/
    └── pages/
```

**قواعد:**
- Feature لا يستورد Feature آخر
- Feature يستورد `core/foundation/` + `core/infra/` فقط
- `*_api_service.dart` في Feature — لا في core

---

## 8. قواعد التعديل والبناء (إلزامية)

### قبل أي تعديل
- [ ] هل الملف في الطبقة الصحيحة (foundation / platform / infra)؟
- [ ] هل يستورد foundation شيئاً من platform أو infra؟ → **ممنوع**
- [ ] هل Core سيعتمد على Feature أو UI؟ → **أوقف وأعد التصميم**
- [ ] هل هناك نقطة دخول مركزية موجودة؟ → **استخدمها** (لا تكرار)

### أثناء التعديل
- تغيير **minimal ومعزول** — لا refactors واسعة بدون موافقة
- لا تغيير logic إلا إذا المطلوب صراحة
- اتبع أسلوب الملفات المحيطة (naming, imports, DI)

### بعد التعديل
```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib
```

> **⚠️ بعد كل build_runner:** تحقق من `injection.config.dart` — injectable_generator قد يُولِّد نفس alias لملفين:
> ```bash
> grep -c "as _i693;" lib/core/di/injection.config.dart  # يجب أن يكون 1
> ```
> إذا كان 2 — غيّر alias أحدهما يدوياً (مثلاً `_i693` → `_i6931`).

### بعد تعديل ملفات الترجمة (ar.json / en.json)
```bash
flutter pub run easy_localization:generate -f keys -O lib/resources -S assets/translations -o locale_keys.g.dart
flutter pub run easy_localization:generate -f json -O lib/resources -S assets/translations -o codegen_loader.g.dart
```
الأمر الثاني إلزامي — التطبيق يستخدم `CodegenLoader` لا JSON مباشرةً.

### مزامنة التوثيق (إلزامي)
راجع القسم 0 في أعلى هذا الملف — حدّث readme المرتبط قبل إنهاء المهمة.

---

## 9. أمثلة

### ✅ صحيح — Repository
```dart
return handle(() async {
  final res = await _remote.login(...);
  if (res.error == null && res.data != null) {
    return Right(LoginResult(accessToken: res.data!.accessToken));
  }
  return Left(BusinessFailure(statusCode: res.error?.code ?? 400));
});
```

### ✅ صحيح — Cubit
```dart
res.fold((failure) {
  switch (FailureUiMapper.toAction(failure)) {
    case ShowError(:final message): emit(State.error(message));
    case NavigateToLogin(): AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    case Silent(): break;
  }
}, (data) => emit(State.success(data)));
```

### ❌ خطأ
```dart
// foundation يستورد Dio
import 'package:dio/dio.dart';  // ❌ في foundation/

// Core يستورد Feature
import '.../Features/auth/...';  // ❌ في core/

// Repository بدون handle()
catch (e) { return Left(UnknownFailure()); }  // ❌ تجاوز Registry

// UI في Core
message: LocaleKeys.error.tr()  // ❌ في infra/errors/
```

---

## 10. أنماط معروفة ومستقرة (Stabilized Patterns)

### A — `AdaptiveTheme` + font/locale sync (`app.dart`)

`AdaptiveTheme.didUpdateWidget()` يتجاهل تغييرات `light`/`dark` prop — لا يمكن تغيير الـ theme بإعادة بناء الـ parent.

**الحل:** `_ThemeSyncLayer` داخل `AdaptiveTheme.builder` يستدعي `AdaptiveTheme.of(context).setTheme()`:
```dart
builder: (theme, darkTheme) => _ThemeSyncLayer(
  appTheme: _appTheme,
  child: MaterialApp.router(theme: theme, darkTheme: darkTheme, ...),
),
```
`_ThemeSyncLayer` يُصدر `setTheme()` عبر `addPostFrameCallback` (لتجنب "setState during build"):
- عند تغيير الخط → `BlocListener<FontPreferenceCubit>`
- عند تغيير اللغة → `didChangeDependencies()` يرصد `context.locale`

### B — Locale-Reactive Widgets

كل `build()` يستخدم `.tr()` يجب أن يصل إلى `context.locale` (أو أي EasyLocalization extension) ليُسجَّل كمعتمد:
- `StatelessWidget.build()` — أضف `context.locale;` في الأعلى
- `BlocBuilder.builder` — نفس الشيء؛ `BlocBuilderBaseState.build()` هو context الفعلي

### C — SessionRepository (تسجيل مزدوج)

```dart
// 1. @singleton (concrete) — eager، يحمل session state
class SessionRepository implements AuthNetworkGateway { ... }

// 2. في injection_module.dart: alias lazy
@lazySingleton
AuthNetworkGateway authNetworkGateway(SessionRepository repo) => repo;
```
النتيجة: `getIt<SessionRepository>()` و`getIt<AuthNetworkGateway>()` كلاهما يعمل.

### D — ApiResponse مع `"status": bool`

بعض الـ APIs تُرجع `"status": true/false` (bool لا String) — `ApiResponse.fromJson` يُلقي `ParseFailure` عند محاولة cast. الحل: بناء يدوي:
```dart
final statusBool = json['status'] as bool? ?? false;
if (!statusBool) {
  return ApiResponse(status: 'error', message: ..., data: null, error: ApiError(...));
}
final dataJson = json['data'] as Map<String, dynamic>?;
return ApiResponse(status: 'success', message: ..., data: dataJson != null ? Model.fromJson(dataJson) : null, error: null);
```

---

## 11. مراجع ذات صلة

| الملف | الغرض |
|-------|--------|
| `readme/architecture.md` | فهرس + هيكل كامل + Future Ideas |
| `readme/rest_api.md` | REST workflow + import paths + common mistakes |
| `readme/pagination.md` | pagination |
| `readme/widgets.md` | widget placement + feedback + locale |
| `readme/scripts.md` | scripts + build/release + troubleshooting |
| `readme/new_developer_guide.md` | onboarding + feedback & locale API |
| `new/09_graphql/README.md` | GraphQL الاحتياطي |
| `.cursor/rules/core-architecture.mdc` | قواعد AI التلقائية (alwaysApply) |

---

*آخر تحديث: 2026-06-29 — أضيف §10 (أنماط مستقرة: AdaptiveTheme/font sync، locale-reactive، SessionRepository، ApiResponse bool)؛ تحديث قواعد بناء الترجمة (أمران لا أمر واحد)؛ تصحيح @singleton → @lazySingleton للـ DataSource.*
