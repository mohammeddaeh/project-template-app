# 04 — أول feature

> درس عملي كامل: من `ApiUrls` إلى شاشة تعمل، **16 خطوة مرقّمة**، لكلٍّ مكانها.
> يعوّض شريحة `notes/` المرجعية المحذوفة — [لماذا حُذفت](90_archive/template_enhancements.md).
> **يُحدَّث** عند تغيير بنية الشريحة أو ترتيب التوليد.

**المثال**: `orders` — قائمة مُصفَّحة + إنشاء + تعديل + حذف، مقابل `/api/v1/orders`.
بدّل الاسم بما تبنيه.

> **المرجع الحيّ الذي تنسخ بنيته حرفياً**: `lib/features/auth/login/` — 12 ملفاً
> بالطبقات الثلاث كاملة. اقرأه قبل أن تبدأ.

---

## قبل أي سطر

| تأكّد | لماذا |
|---|---|
| الباك يستجيب فعلاً على `/orders` | R01: عقد المفاتيح لا يُخمَّن |
| بيدك عيّنة استجابة **حقيقية** | ستصبح `test/fixtures/wire/orders_page.json` |
| قرأتَ [`03_RULES.md`](03_RULES.md) §R01 و§R04 و§R08 | الثلاثة تفشل صامتةً |

**اطلب `GET /openapi.json` من الباك** — مولَّد من نفس zod schemas التي تفرضها
`validate()`، فهو العقد القاطع لا الوصف.

---

## البنية المستهدفة

```
lib/features/orders/
├── data/
│   ├── dtos/          order_request_dto.dart          ← لكل POST/PUT
│   ├── models/        order_model.dart · orders_page_model.dart
│   ├── datasources/   orders_api_service.dart · orders_remote_datasource.dart
│   └── repositories/  orders_repository_impl.dart
├── domain/
│   ├── entities/      order.dart                      ← Dart خالص + Equatable
│   ├── params/        orders_params.dart
│   ├── repositories/  orders_repository.dart          ← مجرَّد
│   └── usecases/      orders_usecases.dart
└── presentation/
    ├── cubits/        orders_list_cubit.dart · order_form_cubit.dart (+ state)
    ├── widgets/       order_item.dart
    └── pages/         orders_screen.dart · order_form_screen.dart
```

**الترتيب من الداخل إلى الخارج**: `domain` لا يعرف `data`، و`data` لا تعرف
`presentation`. ابنِ بنفس الترتيب أدناه ولا تقفز.

---

## 1 — المسار

```dart
// lib/core/infra/network/rest/api_urls.dart
static const String orders = '/orders';
static String order(String id) => '/orders/$id';
```

> **هنا وحده.** مسارٌ مكتوب داخل `@RestApi()` غير مرئي لأي بحث يسأل «ماذا يستدعي
> هذا التطبيق؟».

## 2 — الكيان (domain)

```dart
// domain/entities/order.dart
class Order extends Equatable {
  const Order({required this.id, required this.title, required this.total,
               required this.createdAt});

  final String id;
  final String title;
  final double total;
  final DateTime createdAt;   // ← DateTime هنا، String بالـmodel

  @override
  List<Object?> get props => [id, title, total, createdAt];
}
```

**Dart خالص**: لا `fromJson`، ولا استيراد من `data/`، ولا Flutter.

## 3 — الواجهة المجرَّدة

```dart
// domain/repositories/orders_repository.dart
abstract class OrdersRepository {
  Future<Either<Failure, OrdersPage>> list(PaginationQuery query);
  Future<Either<Failure, Order>> create(CreateOrderParams params);
  Future<Either<Failure, Order>> update(UpdateOrderParams params);
  Future<Either<Failure, Unit>> delete(String id);
}
```

## 4 — الوسائط

```dart
// domain/params/orders_params.dart
class CreateOrderParams extends UseCaseParams {
  const CreateOrderParams({required this.title, required this.total});
  final String title;
  final double total;
}
```

## 5 — حالات الاستخدام

```dart
// domain/usecases/orders_usecases.dart
@injectable
class ListOrdersUseCase extends BaseUseCase<OrdersPage, PaginationQuery> {
  ListOrdersUseCase(this._repo);
  final OrdersRepository _repo;

  @override
  Future<Either<Failure, OrdersPage>> call(PaginationQuery q) => _repo.list(q);
}
// وواحدة لكل من create · update · delete
```

**واحدة تغلّف استدعاءً واحداً.** حالة استخدام تفعل شيئين ⇒ اثنتان.

## 6 — الـDTO

```dart
// data/dtos/order_request_dto.dart
class OrderRequestDto {
  const OrderRequestDto({required this.title, required this.total});
  final String title;
  final double total;

  Map<String, dynamic> toJson() => {'title': title, 'total': total};
}
```

لا يرث شيئاً ولا يحمل منطقاً. **ولا تمرّر `Map` مباشرةً.**

## 7 — النماذج ★ الخطوة الأخطر

```dart
// data/models/order_model.dart
class OrderModel {
  const OrderModel({required this.id, required this.title,
                    required this.total, required this.createdAt});

  final String id;
  final String title;
  final double total;
  final String createdAt;        // ← النوع الخام كما يصل

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id:        json['id']?.toString() ?? '',
        title:     json['title'] as String? ?? '',
        total:     (json['total'] as num?)?.toDouble() ?? 0,
        createdAt: json['created_at'] as String? ?? '',   // ← snake_case
      );

  Order toEntity() => Order(
        id: id, title: title, total: total,
        createdAt: DateTime.tryParse(createdAt) ?? DateTime(2000),
      );
}
```

**قواعد التحويل:**

| يصل كـ | بالـModel | بالـEntity | التحويل بـ`toEntity()` |
|---|---|---|---|
| `String` تاريخ ISO | `String` | `DateTime` | `DateTime.tryParse(s) ?? DateTime(2000)` |
| `int` 0/1 | `int` | `bool` | `json['x'] == true \|\| json['x'] == 1` |
| مُعرّف | `String` | `String` | `json['id']?.toString() ?? ''` |

> ⚠️ **R01**: كل مفتاح هنا عقدٌ مع الباك. `created_at` مقابل `createdAt` خطأٌ **لا
> يراه المصرِّف ولا التحليل** — المفتاح الغائب `null`، و`null` نوعٌ `dynamic` سليم.
> الخطوة 15 هي ما يمسك ذلك، وهي غير اختيارية.

**ومغلَّف الصفحة**، ومفاتيحه الخمسة عقدٌ أيضاً:

```dart
// data/models/orders_page_model.dart
factory OrdersPageModel.fromJson(Map<String, dynamic> json) => OrdersPageModel(
      items:      (json['items'] as List<dynamic>).map((e) =>
                    OrderModel.fromJson(e as Map<String, dynamic>)).toList(),
      page:       json['page'] as int? ?? 1,
      limit:      json['limit'] as int? ?? 20,
      total:      json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
    );
```

## 8 — خدمة الـAPI

```dart
// data/datasources/orders_api_service.dart
part 'orders_api_service.g.dart';       // ← مطلوب

@RestApi()
abstract class OrdersApiService {
  factory OrdersApiService(Dio dio) => _OrdersApiService(dio, baseUrl: Env.baseUrl);

  @GET(ApiUrls.orders)
  Future<HttpResponse<dynamic>> list(@Queries() Map<String, dynamic> query);

  @POST(ApiUrls.orders)
  Future<HttpResponse<dynamic>> create(@Body() OrderRequestDto body);
}
```

## 9 — مصدر البيانات

```dart
// data/datasources/orders_remote_datasource.dart
@lazySingleton                            // ← لا @singleton
class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this._api);
  final OrdersApiService _api;

  Future<ApiResponse<OrdersPageModel>> list(PaginationQuery q) async {
    final response = await _api.list(q.toJson());
    final json = response.data as Map<String, dynamic>;
    return ApiResponse.fromJson(json,
        (data) => OrdersPageModel.fromJson(data as Map<String, dynamic>));
  }
}
```

`@lazySingleton` لا `@singleton`: الثاني يبني عند الإقلاع، **قبل** أن يجهز
`AuthInterceptor`.

## 10 — التنفيذ

```dart
// data/repositories/orders_repository_impl.dart
@LazySingleton(as: OrdersRepository)
class OrdersRepositoryImpl extends BaseRepository implements OrdersRepository {
  OrdersRepositoryImpl(this._remote);
  final OrdersRemoteDataSource _remote;

  @override
  Future<Either<Failure, OrdersPage>> list(PaginationQuery q) => handle(() async {
        final res = await _remote.list(q);
        if (res.error != null) {
          return Left(BusinessFailure(
              statusCode: res.error?.code ?? 400, serverMessage: res.message));
        }
        return Right(res.data!.toEntity());
      });
}
```

**`handle()` لا `try/catch` يدوي** — هي ما يحوّل كل استثناء إلى `Failure` مصنَّفة.

## 11 — تسجيل خدمة الـAPI ★ يُنسى كثيراً

```dart
// lib/core/di/injection_module.dart
@lazySingleton
OrdersApiService ordersApiService(Dio dio) => OrdersApiService(dio);
```

> **إلزامي**: `@RestApi()` صنفٌ مجرَّد ومولَّد، فلا يقبل `@injectable`. بدون هذا
> السطر يفشل الـDI **وقت التشغيل** لا وقت الترجمة.

## 12 — التوليد

```bash
dart run scripts/gen_code.dart
```

## 13 — الكيوبتس

```dart
// presentation/cubits/orders_list_cubit.dart
@injectable
class OrdersListCubit extends PaginationCubit<Order> {
  OrdersListCubit(this._list, this._delete);
  final ListOrdersUseCase _list;
  final DeleteOrderUseCase _delete;

  @override
  Future<Either<Failure, PaginationDataEntity<Order>>> call() async {
    final res = await _list(paginationQuery);
    return res.fold(Left.new, (page) => Right(PaginationDataEntity<Order>(
          data: page.items,
          paginationInfo: PaginationInfo(
            isFirstPage: paginationQuery.page == 1,
            isLastPage:  paginationQuery.page >= page.totalPages,
          ),
        )));
  }

  @override
  bool isMatchedTwoEntity(Order a, Order b) => a.id == b.id;

  /// حذف تفاؤلي: أزل ثم تراجع عند الفشل.
  Future<void> deleteOrder(String id) async {
    final backup = List<Order>.from(data);
    removeItemWhere((e) => e.id == id);          // ← قبل await
    final res = await _delete(id);
    res.fold((f) { restoreItems(backup); _handleFailure(f); }, (_) {});
  }
}
```

`PaginationCubit` يرث `SafeCubit`، فكل قائمة محميّة بلا سطر إضافي (R04).

**وشاشة النموذج واحدة للإضافة والتعديل**: `id == null` ⇒ إنشاء، وإلا تعديل.

## 14 — الشاشات والمسارات

```dart
@RoutePage()
class OrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const OrdersHeader(),          // ← خارج الصندوق: يمتدّ للحافة
    // حدُّ عرضٍ على اللوح، ولا أثر على الهاتف (R37)
    body: ResponsiveContentBox(
      width: ContentWidth.content,         // form (٤٨٠ للحقول) · content (٨٤٠)
      horizontalPadding: false,
      child: const OrdersBody(),
    ),
  );
}
```

> ⚠️ **R37 — ولا رقمَ مقاسٍ خام داخل الجسد.** كل فراغٍ وحشوةٍ ومقاسِ أيقونة
> يمرّ بـ`context.screen`: `ResponsiveGap(24)` · `s.space(16)` · `s.size(24)`.
> شاشةٌ تُبنى بأرقامٍ ثابتة تخرج مختلفةً عن بقيّة الواجهة وتُكسر على اللوح.
> القالبُ الكامل: [`22_RESPONSIVE.md`](22_RESPONSIVE.md) §٣‑ب.

```dart
// lib/routes/router.dart
AutoRoute(page: OrdersRoute.page,    path: '/orders'),
AutoRoute(page: OrderFormRoute.page, path: '/orders/form'),
```

```dart
// test/router_contract_test.dart — أضف الاسمين
'OrdersRoute',
'OrderFormRoute',
```

> **والحارس قائم**: `test/router_contract_test.dart` يقارن ما يُنتقل إليه بـ`lib/`
> بما هو مسجَّل بـ`AppRouter.routes` — فمسارٌ يُنسى يُسقط اختباراً أحمر بدل أن
> يرمي بيد المستخدم.

> ⚠️ **R08**: الخطوة الثالثة ليست تجميلاً. بدونها يُصرَّف الانتقال نظيفاً **ويرمي
> وقت التشغيل**. وقع فعلاً على `MainShellRoute` لأسابيع.

**والحذف يسبقه تأكيد دائماً:**

```dart
AppConfirmDialog.show(context,
  titleKey: LocaleKeys.deleteConfirmTitle,
  messageKey: LocaleKeys.deleteConfirmMessage,
  isDestructive: true,
  onConfirm: () => context.read<OrdersListCubit>().deleteOrder(id),
);
```

## 15 — اختبار العقد ★ غير اختياري

> **والنصفان معاً**: ملفُّ تثبيتٍ بـ`test/fixtures/wire/` وصفٌّ بـ
> `test/wire_contract_test.dart` هنا، و`wire-contract.test.ts` عند الباك —
> **بنفس الكوميت**. والمرجع القاطع `GET /openapi.json`.

```
test/fixtures/wire/orders_page.json     ← عيّنة حقيقية من السيرفر
```

```dart
// test/wire_contract_test.dart
group('GET /api/v1/orders → data (paginated)', () {
  test('the page envelope is items/page/limit/total/total_pages', () {
    final json = jsonDecode(
      File('test/fixtures/wire/orders_page.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(json.keys.toSet(), {'items', 'page', 'limit', 'total', 'total_pages'});

    final items = (json['items'] as List<dynamic>)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    expect(items.first.title, isNotEmpty);
    expect(items.first.createdAt.year, greaterThan(2000));  // ← لا قيمة السقوط
  });
});
```

> **هذه الخطوة هي الفرق بين عطلٍ يُمسَك بدقيقة وعطلٍ يعيش شهوراً.** الفحص الأخير
> يمسك خطأ اسم مفتاح التاريخ تحديداً: `DateTime(2000)` قيمة سقوط `toEntity()`، فظهورها
> يعني أن `created_at` لم يصل.
>
> **وعدّل مقابلها بالباك بنفس التغيير**:
> `backend_template/src/features/orders/__tests__/wire-contract.test.ts`

## 16 — الترجمة والتسليم

```
1. assets/translations/ar.json   ← orders · addOrder · noOrders · orderSaved …
2. assets/translations/en.json   ← نفسها
3. dart run scripts/gen_code.dart
```

```bash
dart analyze lib          # ← No issues found
```

---

## بطاقة الإنهاء

```
[ ] 1   المسار بـapi_urls.dart وحده
[ ] 2-5 domain: كيان · واجهة · وسائط · حالات استخدام
[ ] 6-7 DTO + Model  ← أسماء المفاتيح تطابق السيرفر حرفياً (R01)
[ ] 8-10 ApiService · DataSource(@lazySingleton) · Repository(handle())
[ ] 11  ApiService مسجَّل بـinjection_module.dart      ★ يُنسى
[ ] 12  gen_code.dart
[ ] 13  Cubit يرث SafeCubit/PaginationCubit · state بـ@freezed (R04·R05)
[ ] 14  @RoutePage + router.dart + router_contract_test.dart (R08)  ★ يُنسى
[ ] 15  fixture + مجموعة عقد wire هنا وبالباك (R01)   ★ يُنسى
[ ] 16  ar.json + en.json + codegen · analyze · test
[ ] —   لا نصّ مكتوباً · لا لون خام · context.locale بكل build (R10·R11·R12)
[ ] —   لا رقمَ مقاسٍ خام · الجسد داخل ResponsiveContentBox · جُرِّبت على هاتف ولوح (R37)
[ ] —   شاشة محروسة بصلاحية؟ راجع قائمة «كل نداء بصلاحيته» بـ31_MODULE_PERMISSIONS.md §العثرة ٦   ★ يُنسى
```

---

## بعدها

| تريد | اقرأ |
|---|---|
| فلترة وبحث للقائمة | [`14_PAGINATION.md`](14_PAGINATION.md) · `AppFilterSheet` · `ListFilterBar` |
| شاشة تفاصيل تُرجع نتيجة | `lib/features/CLAUDE.md` §«شاشة التفاصيل تُرجع نوعاً» |
| حماية الشريحة بصلاحية | [`31_MODULE_PERMISSIONS.md`](31_MODULE_PERMISSIONS.md) |
| استيراد/تصدير لها | [`32_MODULE_DATA_TRANSFER.md`](32_MODULE_DATA_TRANSFER.md) — **صفر Dart** |
| عملها دون اتصال | [`30_MODULE_SYNC.md`](90_archive/sync_design_spec.md) |
