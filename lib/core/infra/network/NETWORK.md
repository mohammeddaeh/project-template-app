# Network Layer — دليل الشبكة والـ Interceptors

> **الغرض:** شرح طبقة الشبكة كاملةً — ترتيب الـ interceptors، كيف تعمل معاً، وكيف تستخدم كل قدرة في الـ Features.
>
> **Last updated:** Jun 2026

---

## البنية الكاملة للطبقة

```
lib/core/infra/network/
├── interceptors/
│   ├── auth_interceptor.dart           ← P1: إضافة Bearer token
│   ├── internet_checker_interceptor.dart ← P2: فحص الاتصال
│   ├── token_refresh_interceptor.dart  ← I1: تجديد التوكن تلقائياً
│   ├── retry_interceptor.dart          ← I2: إعادة المحاولة مع back-off
│   └── request_cache_interceptor.dart  ← I3: كاش الـ GET requests
├── security/
│   └── certificate_pinning_config.dart ← I4: تثبيت الشهادة
├── boundary/
│   └── base_repository.dart            ← قاعدة كل Repository
├── cancellation/
│   └── dio_cancel_token_wrapper.dart   ← إلغاء الطلبات
└── rest/
    ├── api_urls.dart                   ← جميع الـ endpoints هنا فقط
    └── handle_body_response.dart       ← معالجة الأخطاء المركزية
```

---

## ترتيب الـ Interceptors مهم!

```
Request يُرسَل ───►  [AuthInterceptor]
                          ↓ يُضيف Authorization header
                     [InternetCheckerInterceptor]
                          ↓ يرفض فوراً إذا لا يوجد اتصال
                     [RetryInterceptor]
                          ↓ يُعيد المحاولة عند الفشل
                     [RequestCacheInterceptor]
                          ↓ يُعيد من الكاش أو يُمرّر للشبكة
                     ──► API Server

Response يعود ◄───  [RequestCacheInterceptor]
                          ↑ يُخزّن الـ GET responses
                     [TokenRefreshInterceptor]
                          ↑ يُجدّد التوكن عند 401 ويُعيد الطلب
                     ──► HandleBodyResponse
                          ↑ يُحوّل الأخطاء إلى Failure
                     ──► Repository.handle()
```

---

## I1 — TokenRefreshInterceptor · تجديد التوكن التلقائي

**المشكلة التي يحلّها:** عند انتهاء صلاحية الـ access token، ترجع الـ API 401. بدون هذا الـ interceptor يجب تسجيل الدخول من جديد.

**كيف يعمل:**
```
401 received
  ├─ أول طلب → يبدأ refresh (Completer)
  ├─ طلبات متزامنة أخرى → تنتظر نفس الـ Completer
  └─ refresh نجح → يُعيد جميع الطلبات المعلّقة بالتوكن الجديد
     refresh فشل → AuthEventBus.sessionExpired → توجيه لتسجيل الدخول
```

**ما تحتاج تنفيذه:**
```dart
// lib/Features/<name>/data/datasources/<name>_token_refresh_gateway.dart
class MyTokenRefreshGateway implements TokenRefreshGateway {
  @override
  Future<void> refresh() async {
    final refreshToken = await _secureStorage.readString('refresh_token');
    final newToken = await _api.refreshToken(refreshToken!);
    await _secureStorage.writeString('access_token', newToken.accessToken);
  }

  @override
  Future<void> onRefreshFailed() async {
    await _secureStorage.delete('access_token');
    await _secureStorage.delete('refresh_token');
  }
}
```

> ثم سجّله في `injection_module.dart`:
> ```dart
> @LazySingleton(as: TokenRefreshGateway)
> class MyTokenRefreshGateway implements TokenRefreshGateway { … }
> ```

---

## I2 — RetryInterceptor · إعادة المحاولة مع Exponential Back-off

**الحالات التي يُعيد فيها المحاولة:**
| الحالة | إعادة؟ |
|--------|--------|
| `connectionError` (انقطع الشبكة) | ✅ نعم |
| `connectionTimeout` / `receiveTimeout` | ✅ نعم |
| HTTP 5xx (خطأ في السيرفر) | ✅ نعم |
| HTTP 408 (Request Timeout) | ✅ نعم |
| HTTP 4xx (خطأ في الطلب) | ❌ لا |
| HTTP 401 | ❌ لا — يُعالَج بـ `TokenRefreshInterceptor` |
| طلب مُلغى | ❌ لا |

**التأخيرات:**
- المحاولة 1 → 1 ثانية
- المحاولة 2 → 2 ثانية
- المحاولة 3 → 4 ثانية

**تخصيص:**
```dart
// في injection_module.dart:
RetryInterceptor(
  dio,
  maxRetries: 3,                          // الافتراضي
  initialDelay: const Duration(seconds: 1), // الافتراضي
)
```

---

## I3 — RequestCacheInterceptor · كاش الـ GET requests

**يعمل تلقائياً** على جميع GET requests بـ TTL افتراضي 5 دقائق.

### تخصيص TTL لطلب معيّن
```dart
// في الـ RemoteDataSource أو ApiService:
await _dio.get(
  ApiUrls.products,
  options: Options(extra: {
    RequestCacheInterceptor.ttlKey: const Duration(hours: 1),
  }),
);
```

### تجاوز الكاش (force refresh)
```dart
await _dio.get(
  ApiUrls.userProfile,
  options: Options(extra: {
    RequestCacheInterceptor.skipKey: true,
  }),
);
```

### إبطال الكاش بعد تعديل البيانات
```dart
// في الـ Repository بعد POST/PUT/DELETE:
class ProductsRepositoryImpl extends BaseRepository {
  final RequestCacheInterceptor _cache;

  Future<Either<Failure, Unit>> createProduct(Product p) async {
    final result = await handle(() => _dataSource.createProduct(p));
    // إذا نجح → أبطل كاش قائمة المنتجات
    if (result.isRight()) {
      await _cache.invalidate(ApiUrls.products);
    }
    return result;
  }
}
```

> **للحصول على RequestCacheInterceptor في Repository:**
> أضفه كـ dependency عبر DI أو احتفظ بـ reference من injection_module.

---

## BaseRepository · القاعدة المشتركة لجميع الـ Repositories

```dart
// كل Repository يرث من BaseRepository ويستخدم handle():
class UsersRepositoryImpl extends BaseRepository implements UsersRepository {
  UsersRepositoryImpl(super.handler, this._dataSource);

  final UsersRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, List<User>>> getUsers() =>
      handle(() => _dataSource.getUsers());
      // ↑ لا try/catch يدوي — handle() يُحوّل كل استثناء إلى Failure
}
```

**ما يفعله `handle()` تلقائياً:**
- `DioException` → `NetworkFailure` / `ServerFailure` / `UnauthorisedFailure`
- `FormatException` / JSON error → `ParseFailure`
- أي استثناء آخر → `UnknownFailure`

---

## إلغاء الطلبات · DioCancelTokenWrapper

مفيد لإلغاء طلبات الـ search عند تغيير المستخدم للنص:
```dart
final _cancelToken = DioCancelTokenWrapper();

// عند كل ضغطة:
_cancelToken.cancel(); // ألغِ الطلب السابق
final results = await _dataSource.search(
  query,
  cancelToken: _cancelToken.token,
);
```

---

## الـ Endpoints · api_urls.dart

**القاعدة:** جميع الـ URLs في ملف واحد فقط:
```dart
// lib/core/infra/network/rest/api_urls.dart
abstract final class ApiUrls {
  static String get users    => '/users';
  static String get products => '/products';
  static String user(int id) => '/users/$id';
}
```

**لا تضع URLs في:**
- `*_api_service.dart` (Retrofit) — استخدم `ApiUrls.users` كـ path
- أي Feature مباشرةً

---

## Certificate Pinning · I4

مفصّل في `lib/core/platform/PLATFORM_SERVICES.md` ← قسم I4.

---

## أمثلة شائعة

### Feature جديدة من الصفر
```dart
// 1. ApiService (Retrofit):
@RestApi()
abstract class OrdersApiService {
  @GET(ApiUrls.orders)        // ← URL من api_urls.dart
  Future<List<OrderDto>> getOrders();
}

// 2. Repository:
class OrdersRepositoryImpl extends BaseRepository {
  Future<Either<Failure, List<Order>>> getOrders() =>
      handle(() => _api.getOrders().then((dtos) => dtos.map(Order.fromDto).toList()));
}

// 3. UseCase (لا تعرف شيئاً عن الشبكة):
class GetOrders {
  Future<Either<Failure, List<Order>>> call() => _repo.getOrders();
}
```

### معالجة الأخطاء في الـ Cubit
```dart
final result = await _getOrders();
result.fold(
  (failure) => switch (FailureUiMapper.toAction(failure)) {
    ShowError(:final message) => emit(OrdersError(message)),
    NavigateToLogin()         => emit(OrdersSessionExpired()),
    Silent()                  => null,
  },
  (orders) => emit(OrdersLoaded(orders)),
);
```
