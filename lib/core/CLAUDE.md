# lib/core/CLAUDE.md — Core Architecture & API Generator

> يُحمَّل عند العمل في lib/core/**
> المرجع الكامل: `readme/core_architecture.md`

---

## Core Internal Layers

```
core/
├── foundation/   ← Pure Dart only. No Flutter, no Dio, no I/O.
├── platform/     ← Flutter/OS wrappers. Depends on foundation only.
├── infra/        ← Implementation. Depends on foundation + platform.
└── di/           ← Composition root (only place that imports everything)
```

### Layer Contents

**foundation/** — `Failure` sealed types, `BaseUseCase`, `BaseCancelToken`, `Params`, `NoParams`, `ApiResponse<T>`, `PaginationQuery`, `PaginationDataEntity`, `AuthNetworkGateway`, `TokenRefreshGateway`, `LocaleProvider`, `SessionReader`, `validators`, `num_extensions`, `value_objects`

**platform/** — `LogService`, `PersistenceKeys`, `MediaService`, `AppBlocObserver`, `AppLocale`, `AppSettings`, `ConnectivityService`, `NetworkStateMonitor`, `AppFeatures`, `StorageService`, `SecureStorageService`, `EncryptionService`, `BiometricsService`, `PermissionsService`, `ClipboardService`, `ShareService`, `FileService`, `AppLifecycleService`

**infra/** — `env/flavors`, `network` (rest/interceptors/boundary/cancellation), `errors` (mappers/registry), `session` (AuthEventBus, LocaleProviderImpl)

**di/** — `injection.dart`, `injection_module.dart`, `platform_services_registry.dart`, `injection.config.dart` (generated)

### Errors Flow

```
Exception (Dio/IO/unknown)
    ▼ infra/errors/FailureMapperRegistry.map(error) → Failure
    ▼ presentation/error/FailureUiMapper.toAction(failure) → UiAction
    ▼ Feature/cubits/ → switch → emit State
```

- `foundation/errors/` = Failure types only — لا mapping، لا Dio، لا `.tr()`
- `infra/errors/` = mapping only — لا UI، لا localization
- `presentation/error/` = عرض فقط — لا منطق
- Repositories = `handle()` — لا try/catch يدوي
- Cubits = `FailureUiMapper.toAction(failure)` — لا يعرف DioException

---

## REST API — إضافة endpoint جديد (5 خطوات)

```
1. URL → core/infra/network/rest/api_urls.dart
2. *_api_service.dart → Features/<name>/data/datasources/
3. dart run build_runner build --delete-conflicting-outputs
4. RemoteDataSource → Repository (handle()) → UseCase → Cubit
5. لا توضع Feature ApiService أو models داخل core/
```

---

## §API-GENERATOR — Templates الكاملة

> **package name:** `app_template` — لا تستخدم اسماً آخر

### Retrofit Setup (pubspec.yaml)

```yaml
dependencies:
  retrofit: ^4.2.0
dependency_overrides:
  intl: ^0.19.0
  retrofit: 4.9.0     # ← إلزامي: 4.9.2+ يكسر الـ generator
dev_dependencies:
  retrofit_generator: ^10.2.0
  build_runner: ^2.4.13
```

### ApiUrls

```dart
abstract class ApiUrls {
  static const String login = '/auth/login';
  static const String {name} = '/your/endpoint';
}
```

### Request DTO (لكل POST/PUT)

```dart
class {Name}RequestDto {
  final String field1;
  final String? field2;
  const {Name}RequestDto({required this.field1, this.field2});
  Map<String, dynamic> toJson() => {'field1': field1, if (field2 != null) 'field2': field2};
}
// DTO لا يحمل منطقاً ولا يرث من أي class — لا تمرر Map مباشرة
```

### ApiService

```dart
part '{feature}_api_service.g.dart';  // ← مطلوب

@RestApi()
abstract class {Feature}ApiService {
  factory {Feature}ApiService(Dio dio) => _{Feature}ApiService(dio, baseUrl: Env.baseUrl);

  @GET(ApiUrls.{name})
  Future<HttpResponse<dynamic>> {methodName}(@Query('page') int page);

  @POST(ApiUrls.{name})
  Future<HttpResponse<dynamic>> {postMethod}(@Body() {Name}RequestDto body);
}
// response.data هو dynamic — تحتاج cast: final json = response.data as Map<String, dynamic>
```

### Remote DataSource

```dart
@lazySingleton  // ← lazySingleton لا @singleton — لمنع eager init قبل AuthInterceptor
class {Feature}RemoteDataSource {
  Future<ApiResponse<{Model}Model>> {methodName}({params}) async {
    final response = await _apiService.{methodName}({params});
    final json = response.data as Map<String, dynamic>;
    // ⚠️ إذا API يُرجع "status": bool — لا تستخدم ApiResponse.fromJson مباشرة
    final statusBool = json['status'] as bool? ?? false;
    if (!statusBool) {
      return ApiResponse<{Model}Model>(status: 'error', message: json['message'] ?? '',
        data: null, error: ApiError(code: json['code'] ?? 400, message: json['message'] ?? ''));
    }
    return ApiResponse.fromJson(json, (data) => {Model}Model.fromJson(data as Map<String, dynamic>));
  }
}
```

### Data Model

```dart
class {Name}Model {
  final String id;
  final String createdAt;  // ← النوع الخام من API

  factory {Name}Model.fromJson(Map<String, dynamic> json) => {Name}Model(
    id: json['id']?.toString() ?? '',
    // is_active: (json['is_active'] == true || json['is_active'] == 1)
    createdAt: json['created_at'] as String? ?? '',
  );

  {Entity} toEntity() => {Entity}(
    id: id,
    // DateTime يُحوَّل هنا:
    createdAt: DateTime.tryParse(createdAt) ?? DateTime(2000),
  );
}
```

**قواعد التحويل:**
| API type | Model | Entity | التحويل في toEntity() |
|---|---|---|---|
| `String` (ISO date) | `String` | `DateTime` | `DateTime.tryParse(s) ?? DateTime(2000)` |
| `int` (0/1) | `int` | `bool` | `json['x'] == true \|\| json['x'] == 1` |
| `int` (id) | `int` | `int` | `json['id'] as int? ?? 0` |

### Domain Entity

```dart
class {Entity} extends Equatable {
  final String id;
  const {Entity}({required this.id});
  @override List<Object?> get props => [id];
}
```

### Repository Implementation

```dart
@LazySingleton(as: {Feature}Repository)
class {Feature}RepositoryImpl extends BaseRepository implements {Feature}Repository {
  @override
  Future<Either<Failure, {Entity}>> {methodName}() => handle(() async {
    final res = await _dataSource.{methodName}();
    if (res.error != null) return Left(BusinessFailure(statusCode: res.error?.code ?? 400, serverMessage: res.message));
    return Right(res.data!.toEntity());
  });
}
```

### Paginated Cubit

```dart
@injectable
class {Name}Cubit extends PaginationCubit<{Entity}> {
  @override
  Future<Either<Failure, PaginationDataEntity<{Entity}>>> call() async {
    final res = await _{useCase}({Name}Params(paginationQuery: paginationQuery));
    return res.fold(Left.new, (page) => Right(PaginationDataEntity<{Entity}>(
      data: page.items,
      paginationInfo: PaginationInfo(
        isFirstPage: paginationQuery.page == 1,
        isLastPage: paginationQuery.page >= page.totalPages,
      ),
    )));
  }
  @override bool isMatchedTwoEntity({Entity} e1, {Entity} e2) => e1.id == e2.id;
  @override Future<void> close() { _{useCase}.cancel(); return super.close(); } // ← إلزامي
}
```

---

## Dependency Injection

### تسجيل ApiService (إلزامي في injection_module.dart)

```dart
@module
abstract class InjectableModule {
  @lazySingleton
  {Feature}ApiService {featureName}ApiService(Dio dio) => {Feature}ApiService(dio);
  // لماذا هنا؟ لأن @RestApi() abstract class لا تقبل @injectable مباشرة
}
```

### قواعد الـ Scope

| Annotation | متى |
|---|---|
| `@lazySingleton` | **الافتراضي** — DataSource + Repository |
| `@singleton` (eager) | حصراً SessionRepository (يحمل token state) |
| `@injectable` (factory) | UseCases + Cubits |

**SessionRepository (تسجيل مزدوج):**
```dart
// @singleton على الـ class + في injection_module.dart:
@lazySingleton AuthNetworkGateway authNetworkGateway(SessionRepository repo) => repo;
// النتيجة: getIt<SessionRepository>() ✓  و  getIt<AuthNetworkGateway>() ✓
```

---

## Generation Order (REST — كامل)

```
1.  ApiUrls → core/infra/network/rest/api_urls.dart
2.  domain/entities/{entity}.dart
3.  domain/repositories/{feature}_repository.dart
4.  domain/params/{name}_params.dart
5.  domain/usecases/{use_case}.dart
6.  data/dtos/{name}_request_dto.dart
7.  data/models/{model}_model.dart
8.  data/datasources/{feature}_api_service.dart
9.  data/datasources/{feature}_remote_datasource.dart
10. data/repositories/{feature}_repository_impl.dart
11. core/di/injection_module.dart ← أضف {Feature}ApiService كـ @lazySingleton
12. presentation/cubits/{name}_cubit.dart + state
13. presentation/pages/{name}_screen.dart
14. translations ar.json + en.json
15. dart run build_runner build --delete-conflicting-outputs
16. flutter pub run easy_localization:generate -f keys ...
    flutter pub run easy_localization:generate -f json ...
```

## ✅ Final Checklist

- [ ] Package: `app_template` في جميع imports
- [ ] DTO منشأ لكل POST/PUT endpoint
- [ ] `{Feature}ApiService` في `injection_module.dart` كـ `@lazySingleton`
- [ ] State يستخدم `@freezed` + `part '...freezed.dart'`
- [ ] Cubit يعتمد على UseCase (لا Repository مباشرة)
- [ ] URL في `api_urls.dart`
- [ ] Repository extends `BaseRepository` + يستخدم `handle()`
- [ ] `response.data as Map<String, dynamic>` — لا dynamic مباشرة
- [ ] boolean status: `json['status'] as bool? ?? false`
- [ ] `is_active` integer: `json['x'] == true || json['x'] == 1`
- [ ] DateTime: `DateTime.tryParse(s) ?? DateTime(2000)` في `toEntity()`
- [ ] `build_runner` شُغّل
- [ ] `@RoutePage()` + route في `router.dart`
- [ ] مفاتيح الترجمة في ar.json + en.json + `locale_keys.g.dart`
