# REST API Guide

> **مرجع معماري:** [`core_architecture.md`](core_architecture.md)  
> **يُحدَّث هذا الملف** عند أي تغيير في `core/infra/network/rest/` أو نمط Feature API.

This template uses **REST only** (`dio` + `retrofit`) with Clean Architecture.

## 1) API Flow

```text
api_urls.dart (core/infra/network/rest/)
  -> *_api_service.dart (feature — Retrofit)
  -> *.g.dart (generated)
  -> remote_datasource
  -> repository (BaseRepository.handle)
  -> usecase
  -> cubit
  -> page
```

Errors:

```text
Exception
  DioException            → DioFailureMapper       → Failure
  FormatException (direct)→ FailureMapperRegistry  → ParseFailure(malformedJson)
  TypeError (direct)      → FailureMapperRegistry  → ParseFailure(typeMismatch)
  Failure (passthrough)   → FailureMapperRegistry  → same Failure
                                                        ↓
                                              FailureUiMapper.toAction()
                                                        ↓
                                                     UiAction
```

## 1b) أعطال جهة الخادم — من الثِّقَل إلى الإغلاق

**الخطأ الخادميّ ليس نوعاً واحداً، ولا يُقرأ للمستخدم بجملة واحدة.** الفارق بين «مشغول الآن» و«معطوب» هو الفارق بين زرِّ إعادة محاولة يعمل وزرٍّ لا ينجح أبداً — وقبل هذا التقسيم كان الاثنان يصلان الشاشة متطابقَين، بلا إعادة محاولة أصلاً.

| ما يحدث فعلاً | `Failure` | يُعاد تلقائياً؟ | `canRetry` بالواجهة |
|---|---|---|---|
| **٥٠٢ · ٥٠٣ · ٥٠٤** — ثِقَل، صيانة، أو upstream سقط | `ServiceUnavailableFailure` | ✅ (٣ محاولات) | ✅ + تلميح انتظار |
| **٥٠٠ · ٥٠١ · ٥٠٥** — خلل داخل الخادم | `ServerFailure` | ❌ | ❌ |
| **الخادم مغلق** — لا شيء أجاب، والجهاز متصل | `ServerUnreachableFailure` | ✅ | ✅ |
| **الجهاز غير متصل** | `NoInternetFailure` | ✅ | ✅ |
| **٤٢٩** — تجاوز الحدّ | `RateLimitFailure` | ❌ | ❌ + تلميح انتظار |

**ثلاث قواعد تحمل هذا الجدول:**

1. **٥٠٠ لا يُعاد.** الطلب نفسه بعد ثانية يُنتج الخطأ نفسه، فالإعادة تضاعف الحمل على خادمٍ يفشل أصلاً وتؤخّر رسالة المستخدم سبع ثوانٍ بلا مقابل. `RetryInterceptor` كان يعيد **كل** ٥xx.
2. **`Retry-After` يتقدّم على منحنى التراجع.** خادم يقول «عد بعد ٦٠ ثانية» فيعود العميل بعد ١ ثم ٢ ثم ٤ هو عميلٌ يحوّل الضغط إلى انقطاع. ويُقرأ **بصيغتيه** — الثواني والتاريخ — إذ كانت الثانية تسقط إلى `null` بصمت. وانتظارٌ يتجاوز `maxHonouredRetryAfter` (١٠ث) **لا يُنام عليه**: تظهر الرسالة فوراً بدل تجميد الطلب خلف مؤشّر تحميل.
3. **«لا يوجد إنترنت» تهمة، ولا تُقال إلا بدليل.** `connectionError` يصل من Dio متطابقاً في الحالتين، فيُسأل `NetworkStateMonitor`: الجهاز متصل ⇒ الخادم هو المغلق. وإن كانت الحالة `unknown` تبقى الإجابة القديمة — ادّعاءٌ غير مُثبَت على الخادم أسوأ من رسالة مبهمة.

**ومن جهة الباك**: `ServiceUnavailableError` (٥٠٣، مع `Retry-After` اختياري) للصيانة والتفريغ المتعمَّد، **و`error-handler.ts` يترجم سقوط أي تبعية إلى ٥٠٣ لا ٥٠٠** — قاعدة البيانات تُعاد تشغيلها أو ينفد مجمّع اتصالاتها فيصل الخطأ كخطأ مقبس لا كـ`ApiError`، وتسميته «خطأً داخلياً» تُخبر كل مستخدم أن التطبيق معطوب في اللحظة التي كان انتظار عشر ثوانٍ يكفي فيها. تُطابَق بـ`code` لا بنصّ الرسالة.

## 2) Add a New Endpoint

### Step A: Add API path (core/infra — shared URLs only)

File: `lib/core/infra/network/rest/api_urls.dart`

```dart
static const String products = '/products';
```

### Step B: Add Retrofit service (feature — NOT in core)

File: `lib/Features/products/data/datasources/products_api_service.dart`

```dart
// لا تضع @lazySingleton هنا — abstract class بـ factory constructor لا تدعم @injectable مباشرة
// سجِّلها في injection_module.dart (انظر Step D)
@RestApi()
abstract class ProductsApiService {
  factory ProductsApiService(Dio dio) =>
      _ProductsApiService(dio, baseUrl: Env.baseUrl);

  @GET(ApiUrls.products)
  Future<HttpResponse<dynamic>> getProducts(
    @CancelRequest() CancelToken? cancelToken,
  );
}
```

### Step C: Register in injection_module.dart (إلزامي لكل ApiService)

```dart
// lib/core/di/injection_module.dart
@lazySingleton
ProductsApiService productsApiService(Dio dio) => ProductsApiService(dio);
```

> **لماذا injection_module.dart؟** `ProductsApiService` abstract class بـ factory constructor مُولَّد — لا يمكن وضع `@injectable` عليه مباشرة.

### Step D: Generate Retrofit code

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 3) RemoteDataSource Pattern

Keep it thin — call the feature ApiService only.

```dart
@lazySingleton   // ← lazySingleton لا @singleton — يمنع eager init لـ Dio قبل AuthInterceptor
class ProductsRemoteDataSource {
  ProductsRemoteDataSource(this._apiService);
  final ProductsApiService _apiService;

  Future<ApiResponse<ProductsResponse>> getProducts({
    CancelToken? cancelToken,
  }) => _apiService.getProducts(cancelToken);
}
```

## 4) Repository Pattern

Extend `BaseRepository` and use `handle()` — no manual try/catch.

```dart
@LazySingleton(as: ProductsRepository)   // ← LazySingleton لا @Singleton (eager)
class ProductsRepositoryImpl extends BaseRepository implements ProductsRepository {
  ProductsRepositoryImpl(this._remote, HandleBodyResponse handler) : super(handler);

  final ProductsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Product>>> getProducts({
    CancelToken? cancelToken,
  }) => handle(() async {
    final result = await _remote.getProducts(cancelToken: cancelToken);

    if (result.error == null && result.data != null) {
      return Right(result.data!.items.map((m) => m.toEntity()).toList());
    }

    return Left(
      BusinessFailure(
        statusCode: result.error?.code ?? 400,
        serverMessage: result.message.isNotEmpty ? result.message : null,
      ),
    );
  });
}
```

## 5) UseCase Pattern

```dart
return _repository.getProducts(
  cancelToken: resetCancelToken<DioCancelTokenWrapper>(
    DioCancelTokenWrapper(),
  ).raw,
);
```

### Cancellation (REST)

- `BaseUseCase` stores one `BaseCancelToken`.
- REST uses `DioCancelTokenWrapper` (`core/infra/network/cancellation/`) → `.raw` gives `CancelToken`.
- Calling `cancel()` on the use case cancels the in-flight request.

## 6) Cubit Error Pattern

```dart
res.fold((failure) {
  switch (FailureUiMapper.toAction(failure)) {
    case ShowError(:final message): emit(State.error(message));
    case NavigateToLogin(): AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    case Silent(): break;
  }
}, (data) => emit(State.success(data)));
```

## 7) Core Files Reference

| File | Role |
|------|------|
| `core/infra/network/rest/api_urls.dart` | Shared endpoint paths |
| `core/foundation/contracts/api_response.dart` | Unified response wrapper |
| `core/infra/network/rest/handle_body_response.dart` | REST error boundary |
| `core/infra/network/boundary/base_repository.dart` | `handle()` for repositories |
| `core/infra/network/interceptors/` | Auth + internet + token refresh + retry + cache |
| `core/infra/network/security/` | `CertificatePinningConfig` (SHA-256, OFF by default) |
| `core/foundation/contracts/token_refresh_gateway.dart` | Contract — auth feature implements this for refresh endpoint |
| `core/foundation/errors/failure.dart` | `Failure` sealed types + `ParseFailure` + `ValidationFailure` + `PermissionFailure` + `StorageFailure` |
| `core/infra/errors/failure_mapper_registry.dart` | Exception → Failure (`FormatException`/`TypeError` → `ParseFailure`) |
| `presentation/error/failure_ui_mapper.dart` | Failure → UiAction |

## 8) Rules

- Do not put feature models or `*_api_service.dart` in `core/`.
- Do not throw raw `DioException` to UI — use `Failure`.
- Do not use `ErrorModel` — removed; use `Failure` + `FailureUiMapper`.

## 9) Quick Checklist

- [ ] URL added in `core/infra/network/rest/api_urls.dart`
- [ ] `*_api_service.dart` created in feature `data/datasources/` (بدون `@injectable`)
- [ ] ApiService مُسجَّل في `core/di/injection_module.dart` كـ `@lazySingleton`
- [ ] `build_runner` run
- [ ] RemoteDataSource مُعلَّق بـ `@lazySingleton` (ليس `@singleton`)
- [ ] Repository extends `BaseRepository` + uses `handle()` + `@LazySingleton(as: XRepository)`
- [ ] UseCase + Cubit connected
- [ ] Cubit uses `FailureUiMapper.toAction()`
- [ ] `dart analyze lib` passes

## 10) Canonical Import Paths

```dart
// ✅ Correct
import 'package:app_template/modules/multi_device/data/device_session_api_service.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/cancellation/dio_cancel_token_wrapper.dart';

// ❌ Wrong — outdated paths (removed from codebase)
import 'package:app_template/core/network/api/api_service.dart';
import 'package:app_template/core/network/models/error_model.dart';
import 'package:app_template/core/failure/failure.dart';
```

## 11) Common Mistakes

- Putting Retrofit service in `core/` instead of `Features/<name>/data/datasources/`
- Returning raw models to UI instead of mapped domain entities
- Manual try/catch in repository instead of `handle()`
- Calling DataSource from Cubit directly — must go through UseCase + Repository
- Forgetting `build_runner` after changes to `*_api_service.dart`
- Using `ErrorModel` (removed — use `Failure` from `core/foundation/errors/`)
- Registering repository as concrete type — use `@LazySingleton(as: XRepository)` (not `@Singleton`)
- Annotating `*ApiService` with `@injectable` directly — register it in `injection_module.dart` instead
- Using `Env().config.baseUrl` — use `Env.baseUrl` (abstract final class, لا instantiation)

## 12) Related Docs

- [`core_architecture.md`](core_architecture.md)
- [`architecture.md`](architecture.md)

*Last updated: 2026-06-17 — F1-F4 مكتملة: `ParseFailure`+`ValidationFailure`+`PermissionFailure`+`StorageFailure`؛ `FailureUiMapper` يعالج جميعها؛ `FormatException`/`TypeError` → `ParseFailure` تلقائياً.*
