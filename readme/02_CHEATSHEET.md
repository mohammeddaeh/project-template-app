# 02 — المرجع السريع

> **المكان المركزي.** نسيتَ أمراً أو مساراً أو خطوة؟ هنا، لا في خمسة ملفات.
> **يُحدَّث** عند إضافة أمر · مسار import · widget · قيمة enum · سكربت.

**ابحث بـ Ctrl+F.** الأقسام: [أوامر](#أوامر) · [إضافة X](#كيف-أضيف-x) ·
[Imports](#imports) · [Widgets](#widgets) · [Cubits](#cubits-والحالة) ·
[الأخطاء](#الأخطاء) · [الأعلام](#الأعلام) · [الملفات المفتاحية](#الملفات-المفتاحية) ·
[الأعطال](#أعطال-شائعة)

---

## أوامر

### يومي

```bash
dart run scripts/gen_code.dart                 # ★ بعد أي DI/router/API/freezed/ترجمة
dart analyze lib                              # ★ يجب أن يكون نظيفاً قبل أي تسليم
dart run scripts/check_structure.dart         # ★ بنية الواجهة — يفشل بمخالفة جديدة
dart run scripts/check_wire_contract.dart     # ★ عقد المقاسم مقابل openapi الحيّ (R01)
dart run scripts/check_wire_contract.dart --file spec.json   # مواصفة محفوظة، بلا شبكة
flutter run --flavor dev --dart-define-from-file=.env.dev.json
```

> `flutter run` بلا `--dart-define-from-file` ⇒ `Env.baseUrl` فارغ وكل طلب يفشل.

### إعداد

```bash
flutter pub get
dart run scripts/sync_flavors.dart            # .env.* + productFlavors + أيقونات + launch.json
dart run scripts/sync_flavors.dart --reset    # إزالة الـflavors (لا يحذف .env.*)
dart run scripts/sync_fonts.dart              # تفاعلي — يسجّل الخطوط ويولّد app_fonts.dart
dart run scripts/gen_assets.dart              # يمسح assets/ ويولّد assets.gen.dart
dart run scripts/gen_assets.dart --check      # فحص pubspec فقط
dart run scripts/sync_platform_permissions.dart        # AppFeatures → AndroidManifest + Info.plist
dart run scripts/gen_permission_keys.dart    # permissions.lock.json → permission_keys.g.dart
```

### الفيغما

```bash
# مرّة واحدة: التوكن بـ.figma/token (مُتجاهَل من git) ثم مفتاح الملف
dart run scripts/pull_figma.dart --file "<الصق رابط الفيغما>"

dart run scripts/pull_figma.dart --list          # الصفحات والإطارات بمعرّفاتها
dart run scripts/pull_figma.dart --styles        # ★ أولاً — نظام الألوان والخطوط المنشور
dart run scripts/pull_figma.dart --name "Login"  # اسحب شاشةً: png + md + json
dart run scripts/pull_figma.dart --node 1:57     # المعرّف بدل الاسم
dart run scripts/pull_figma.dart --all           # كل الإطارات العليا
```

> المخرَج بـ`.figma/cache/`. القواعد: [`05_FIGMA_TO_PAGE.md`](05_FIGMA_TO_PAGE.md) ·
> التفاصيل: [`40_SCRIPTS.md`](40_SCRIPTS.md) §7.

### إصدار

```bash
dart run scripts/build_apk.dart                                          # dev · debug · bump build
dart run scripts/build_apk.dart --flavor prod --mode release --bump minor
```

| Flag | القيم | الافتراضي |
|---|---|---|
| `--flavor` | `dev` · `staging` · `prod` | `dev` |
| `--mode` | `debug` · `release` | `debug` |
| `--bump` | `build` · `patch` · `minor` · `major` | `build` |
| `--no-bump` · `--clean` · `--no-codegen` | — | مُطفأة |

المخرَج: `build/app/outputs/flutter-apk/{displayName}-{mode}-{version}.apk`

### إصلاح

```bash
flutter clean && flutter pub get
cd ios && pod install                                    # بعد تغيير flavors — macOS
dart run build_runner build --delete-conflicting-outputs # gen_code.dart يشمله
```

---

## كيف أضيف X

### مفتاح ترجمة — أربع خطوات، لا ثلاث

```
1. assets/translations/ar.json   ← أضف المفتاح
2. assets/translations/en.json   ← أضفه هنا أيضاً (إلزامي)
3. dart run scripts/gen_code.dart
4. بالـUI: LocaleKeys.myKey.tr()
```

> ⚠️ التطبيق يقرأ من `codegen_loader.g.dart` وقت التشغيل. توليد `locale_keys.g.dart`
> وحده يجعل المفتاح **يظهر كنصّ خام** بالواجهة. `gen_code.dart` يولّد الاثنين.

### endpoint جديد

```
1. lib/core/infra/network/rest/api_urls.dart          ← const للمسار
2. features/<f>/data/dtos/                            ← DTO لكل POST/PUT
3. features/<f>/data/datasources/<f>_api_service.dart ← @RestApi
4. lib/core/di/injection_module.dart                  ← @lazySingleton للـApiService
5. dart run scripts/gen_code.dart
```

> الخطوة 4 إلزامية: `@RestApi()` صنف مجرَّد ومولَّد، فلا يقبل `@injectable`.

الرحلة كاملةً بـ16 خطوة: [`04_FIRST_FEATURE.md`](04_FIRST_FEATURE.md)

> **والمرجع القاطع لأي مفتاح: `GET /api/v1/docs/openapi.json` من الخادم** (R01)
> — لا مجموعة Postman بجذر المستودع: تلك لقطةٌ مصدَّرة تحمل قيماً وهمية
> (`"string"`) بأمثلتها.

#### المسارات المخدومة اليوم

⛔ **لا مسارَ تطبيقياً واحداً بالقالب.** `ApiUrls` يحمل مسارات الحساب
(`auth/*`) وحدَها، ومسارُ كلِّ شريحةٍ **يسكن شريحتَها** (`data/<name>_urls.dart`)
لا ملفاً مركزياً يتضخّم بعقودٍ لا يقرؤها أحد.

وعقدُ ما يخدمه باكُك يُكتب بـ[`17_SERVED_CONTRACT.md`](17_SERVED_CONTRACT.md) —
**يصل فارغاً بقصد**، تملؤه بأوّل نقطةٍ تُوصَل.
### شاشة جديدة

```
1. @RoutePage() فوق الـwidget
2. lib/routes/router.dart          ← AutoRoute(page: XRoute.page, path: '/x')
3. test/router_contract_test.dart  ← صفٌّ باسم المسار
4. dart run scripts/gen_code.dart
```

> ⚠️ الخطوة 2 **لا يفرضها المصرِّف**: `auto_route` يولّد `PageRouteInfo` لكل
> `@RoutePage()` سُجِّل أو لم يُسجَّل، فالاستدعاء يُصرَّف نظيفاً **وينهار وقت
> التشغيل**. الخطوة 3 هي ما يمسك ذلك — فلا تتخطَّها (R08).

**ومعامل مسارٍ تكتبه شريحةٌ وتقرأه أخرى موضعه `lib/routes/`** لا شريحةَ أحدهما
(`features → features ❌`). ولا مفردةَ كهذه بالقالب اليوم — أوّلُ مسارٍ يحتاجها
يضعها هناك.

### widget مشترك

```
1. lib/ui/widgets/<category>/my_widget.dart
2. lib/ui/widgets/widgets.dart   ← export '<category>/my_widget.dart';
3. readme/21_WIDGETS_USAGE.md        ← وثّق وسائطه
```

خاص بـfeature واحدة ⇒ `features/<f>/presentation/widgets/` بلا تصدير.

### خدمة منصّة

```dart
// lib/core/platform/features/app_features.dart — سطر واحد
static const biometrics = true;   // → BiometricsService يُسجَّل تلقائياً
```

ثم `dart run scripts/sync_platform_permissions.dart` لتحديث الأذونات.

### صلاحية

المفتاح **يُعلَن بالباك** (`requirePermission('orders.update')`) ويُلمّ تلقائياً.
هنا: حدّث `permissions.lock.json` ثم `dart run scripts/gen_permission_keys.dart`.

```dart
Can(permission: PermKeys.ordersUpdate, child: EditButton())
```

> ⚠️ **لا تكتب المفتاح نصّاً خاماً أبداً.** `PermKeys` مولَّد — مفتاحٌ يحذفه الباك
> **يكسر البناء** بدل أن يُخفي زرّاً للأبد بصمت.

---

## Imports

| ما تحتاجه | المسار |
|---|---|
| ApiUrls | `package:app_template/core/infra/network/rest/api_urls.dart` |
| ApiResponse | `package:app_template/core/foundation/contracts/api_response.dart` |
| Failure | `package:app_template/core/foundation/errors/failure.dart` |
| BaseRepository | `package:app_template/core/infra/network/boundary/base_repository.dart` |
| HandleBodyResponse | `package:app_template/core/infra/network/rest/handle_body_response.dart` |
| BaseUseCase · UseCaseParams · NoParams | `package:app_template/core/foundation/domain/{base_usecase,use_case_params,no_params}.dart` |
| SafeCubit | `package:app_template/core/foundation/domain/safe_cubit.dart` |
| PaginationCubit | `package:app_template/ui/state/pagination/pagination_cubit.dart` |
| NetworkOrigin — وسمُ منفذ الشبكة | `package:app_template/core/foundation/contracts/network_origin.dart` |
| ServerFileCache — بايتاتُ ملفٍّ يملكه الخادم | `package:app_template/core/infra/files/server_file_cache.dart` |
| NaturalOrder — ترتيبُ «٩١/٢» قبل «٩١/١٠» | `package:app_template/core/foundation/utils/natural_order.dart` |
| PersistenceKeys | `package:app_template/core/platform/storage/persistence_keys.dart` |
| **كل الودجات** | `package:app_template/ui/widgets/widgets.dart` |
| **الاستجابة** — `context.screen` · `ResponsiveContentBox` · `ResponsiveGap` | `package:app_template/ui/responsive/responsive.dart` |
| LocaleKeys | `package:app_template/resources/locale_keys.g.dart` |
| PermKeys | `package:app_template/resources/permission_keys.g.dart` |
| Assets | `package:app_template/resources/assets.dart` |
| Router | `package:app_template/routes/router.gr.dart` |
| getIt | `package:app_template/core/di/injection.dart` |

### امتدادات — لا تأتي من الـbarrel

```dart
import 'package:app_template/ui/extensions/extensions.dart';
// barrel عام

import 'package:app_template/ui/extensions/screen_sizes_extensions.dart';
// context.sw · context.sh · context.topPadding · context.bottomContentInset
// ⚠️ قياسُ الشاشة فقط — لا مسافةً ولا مقاساً. تلك من responsive.dart أدناه

import 'package:app_template/ui/responsive/responsive.dart';
// context.screen → space(24) · size(115) · gutter · isTablet · pick(...)
// ResponsiveContentBox · ResponsiveGap · ResponsiveBuilder — readme/22_RESPONSIVE.md

import 'package:app_template/ui/extensions/app_padding_extension.dart';
// 16.allPadding · 16.horizontalPadding · 4.widthBox · 4.heightBox

import 'package:app_template/ui/theme/theme_extensions.dart';
// context.colors · context.textTheme · context.colorScheme · context.isDark

import 'package:app_template/ui/feedback/feedback_extension.dart';
// ⚠️ منفصل عمداً — مطلوب صراحةً بكل ملف يستعمل context.feedback

import 'package:app_template/core/platform/storage/offline_snapshot.dart';
// OfflineSnapshot<T> · OfflineListSnapshot<T> — «آخر نسخة معروفة» عند انقطاع
// الشبكة. تُعرض بشرط `failure.leftUnanswered` وحده (لا شبكة · مهلة · خادم لا
// يُبلَغ) — لا فوق رفضٍ صريح 401/403.
// **مستهلكوها**: مهامي (الخلاصة) · حسابي (البطاقة) — و«المرفوضات» حُذفت 2026-08-28

import 'package:app_template/ui/extensions/byte_size_extension.dart';
// bytes.asFileSize → «٢٫٤ ميغابايت» · "2.4 MB"
// كسرةٌ عشرية واحدة، وتقريبٌ لأعلى دون الميغابايت («٠ كيلوبايت» تُقرأ «فارغ»)،
// ونصٌّ فارغ لغير الموجب. **مستهلكاها**: سطرُ ملفّ السجل · بطاقةُ المزامنة

import 'package:app_template/core/platform/extensions/datetime_extensions.dart';
// date.dayMonthYear         → dd/MM/yyyy — **لا MM/dd**، يقرؤها العربي يوماً
// date.timeAndDayMonthYear  → HH:mm · dd/MM/yyyy
// date.timeAgo() · date.lastSeenAgo
```

> **تاريخٌ يُعرض للمستخدم يمرّ بهذين الاثنين، لا بـ`DateFormat` محليّ.** صيغتان
> متجاورتان بشاشتين تُقرآن تاريخين مختلفين، ولا شيء يكشفه إلا العين.

---

## Widgets

```dart
PrimaryButton(text: LocaleKeys.submit.tr(), onTap: _submit,
    isLoading: false, isEnabled: true)

CustomTextField(controller: _ctrl, labelText: '...', validator: _v)
CustomTextField(controller: _ctrl, isFieldObscure: true)   // كلمة مرور
CustomTextField(controller: _ctrl, isSearch: true)         // بحث
CustomTextField(controller: _ctrl, maxLines: 4, minLines: 2)

// قيمةٌ هي المعلومة — كبيرة ووسطاً، والعنوان يبقى بجهة البداية
CustomTextField(controller: _ctrl, labelText: '...', textAlign: TextAlign.center,
    textStyle: context.textTheme.headlineLarge)   // التلميح يرث المقاس وحده

AppCard(child: ..., onTap: ..., padding: EdgeInsets.all(16))
```

### التحميل والتقدّم — `AppProgress` وحده

```dart
const AppProgress.circular()                          // تحميل · md · brand
const AppProgress.circular(size: AppProgressSize.xs)  // داخل شارة أو حقل
const AppProgress.circular(centered: true)            // وسط الشاشة
AppProgress.linear(value: .65, tone: AppProgressTone.accent, label: '52 / 80')
AppProgress.circular(value: .65, dimension: 54,
                     center: GlyphCenter(child: Text('65%')))
```

**ممنوع ❌:** `CircularProgressIndicator` · `LinearProgressIndicator` ·
`CupertinoActivityIndicator` مباشرةً بأي ملف تحت `lib/`.

| `AppProgressTone` | `brand` (افتراضي) · `accent` (تدرّج ذهبي) · `success` · `warning` · `danger` · `neutral` · `onBrand` |
|---|---|
| `AppProgressSize` | `xs` 14/3 · `sm` 20/5 · `md` 28/7 (افتراضي) · `lg` 44/10 — (قُطر الدائرة / ارتفاع الشريط) |
| تجاوزات | `color` · `trackColor` · `gradient` · `strokeWidth` · `dimension` · `height` · `radius` · `padding` · `centered` · `animate` · `adaptive` |

> `value: null` ⇒ غير محدّد · `value: 0.0–1.0` ⇒ محدّد ويتحرّك. نفس الويدجت.
> التفصيل: [`21_WIDGETS_USAGE.md`](21_WIDGETS_USAGE.md) §33.

### توسيط الأرقام — `GlyphCenter` بالشارات

```dart
// رقمٌ وحده في صندوقٍ مركزيّ ⇒ يُلَفّ. العربيُّ لا يُلَفّ.
Container(
  width: 28, height: 28, alignment: Alignment.center,
  decoration: const BoxDecoration(shape: BoxShape.circle),
  child: GlyphCenter(child: Text('$n', style: context.textTheme.headlineSmall)),
)
```

صندوق سطر `itfQomraArabic` علويُّ الثقل (`ascent 1851` / `descent −998`)،
فالأرقام واللاتيني بلا نوازل ترتفع **14.16%** من `fontSize` عن مركز الصندوق —
والعربيُّ منحرفٌ **1.25%** فقط فلا يُلَفّ. ولا خاصيّةَ في `TextStyle` تصلحه:
`height` و`leadingDistribution` و`StrutStyle` لا تغيّر نسبة الصعود/النزول.
المقدار في `AppFonts.opticalCenterCorrectionFor` — **المكان الوحيد** الذي
يُعدَّل لو تغيّر الخط.

> `StepProgressIndicator` يلفّ رقمه داخلياً. التفصيل وحدودُ الاستعمال:
> [`21_WIDGETS_USAGE.md`](21_WIDGETS_USAGE.md) §36.

### حالات الشاشة — لكل حالة widget

| الحالة | الأداة |
|---|---|
| تحميل | `MyBody.loading()` + `Skeletonized(enabled:)` — الهيكلُ هو الجسدُ نفسُه ([`21`](21_WIDGETS_USAGE.md) §18) · و`const LoadingWidget()` لما لا شكلَ له |
| فارغة | `EmptyStateWidget(titleKey: ..., icon: ...)` |
| خطأ + إعادة | `ErrorStateWidget(messageKey: ..., onRetry: ...)` |
| لا إنترنت | `NoInternetWidget(onRetry: ...)` |
| صيانة | `const MaintenanceWidget()` |
| نجاح ثابت | `SuccessStateWidget(messageKey: ...)` |
| رسالة عابرة | `context.feedback.success/error/warning/toast` |

> ⚠️ **لا تستعمل `context.feedback.error` لحالة ثابتة بالشاشة** — استعمل
> `ErrorStateWidget`. الأول يختفي بعد ثانيتين ويترك الشاشة فارغة بلا تفسير.

### الصور — لا `Image.network` مباشرةً

| الحالة | الأداة |
|---|---|
| صورة شخص | `AvatarWidget(initial: name.isNotEmpty ? name[0] : '?', imageUrl: url ?? '')` |
| محتوى من الشبكة | `NetworkImageWidget(url: url ?? '')` |
| مع cache | `CachedImageWidget(url: url ?? '')` |

> `imageUrl: null` ⇒ انهيار وقت التشغيل. **دائماً** `url ?? ''`.

المكتبة كاملةً بوسائطها: [`21_WIDGETS_USAGE.md`](21_WIDGETS_USAGE.md)

---

## Cubits والحالة

```dart
@injectable
class XCubit extends SafeCubit<XState> {     // ← SafeCubit، لا Cubit
  XCubit(this._useCase) : super(const XState.initial());
  final GetXUseCase _useCase;
}

@freezed                                      // ← إلزامي لكل state
abstract class XState with _$XState {
  const factory XState.initial()                             = XInitial;
  const factory XState.loading()                             = XLoading;
  const factory XState.loaded({required X data})             = XLoaded;
  const factory XState.error({required String errorMessage}) = XError;
}
```

### نطاق التسجيل بالـDI

| الوسم | لِمَن |
|---|---|
| `@lazySingleton` | **الافتراضي** — DataSource · Repository |
| `@injectable` (factory) | UseCases · Cubits |
| `@singleton` (eager) | حصراً `SessionRepository` |

---

## الأخطاء

```
Exception → FailureMapperRegistry.map() → Failure → FailureUiMapper.toAction() → UiAction
```

```dart
res.fold((failure) {
  switch (FailureUiMapper.toAction(failure)) {
    case ShowError(:final message): emit(XState.error(errorMessage: message));
    case NavigateToLogin():         AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    case Silent():                  break;
  }
}, (data) => emit(XState.loaded(data: data)));
```

| الطبقة | مسؤوليتها — ولا شيء غيرها |
|---|---|
| `core/foundation/errors/` | أنواع `Failure` فقط — لا تحويل، لا Dio، لا `.tr()` |
| `core/infra/errors/` | التحويل فقط — لا UI، لا ترجمة |
| `ui/error/` | العرض فقط — لا منطق |
| Repository | `handle()` — لا `try/catch` يدوي |
| Cubit | `FailureUiMapper.toAction()` — لا يعرف `DioException` |

المسار عبر النصفين: [`13_ERROR_FLOW.md`](13_ERROR_FLOW.md)

---

## الأعلام

`lib/core/platform/features/app_features.dart` — المصدر الوحيد.

| العلَم | ما يُشعله |
|---|---|
| `debugSkipLogin` | تخطّي الدخول → `MainShellRoute` **بلا توكن** (كلُّ طلبٍ بعده ٤٠١). **و`false` بالإنتاج حتماً** — مقفولٌ بـ`kDebugMode && _skipLoginRequested` (2026-08-30)، فالنسيان لا يشحن. ولدخولٍ بتوكنٍ حقيقي: شاشةُ الدخول نفسُها، فـKeycloak مخدوم. و`DEV_TOKEN` **حُذف (2026-08-30)** — [`01_SETUP.md`](01_SETUP.md) |
| `verboseNetworkLog` | سجلّ كامل لكل طلب. **اتركه `false`** — يدفن الأخطاء الحقيقية |
| `biometrics` · `clipboard` · `shareSheet` · `fileOperations` · `appLifecycle` | خدمات `core/platform/` — تُسجَّل تلقائياً |
| `certificatePinning` | تثبيت الشهادة على Dio |
| `localNotifications` | `FlnNotificationsAdapter` بدل المعطَّل |
| `camera` · `microphone` · `location` · `photos` · `contacts` · `bluetooth` … | أذونات المنصّة — ثم `sync_platform_permissions.dart` |
| `offlineSync` | ⛔ **مطفأ** — المحرّك كامل ويُشحن ساكناً: إشعالُه بلا محوّلِ شريحةٍ يترك التطبيق يعمل على الشبكة **بلا انهيارٍ ولا تحذير**. راجع [`lib/modules/sync/SETUP.md`](../lib/modules/sync/SETUP.md) |
| `accessControl` · `multiDevice` | موديولات `lib/modules/` — **مطفأة** |
| `dataTransfer` | ✅ **مُشعَل** — شاشتاه تُبنيان من ردّ الخادم، فلا Dart لكل مورد. راجع [`32_MODULE_DATA_TRANSFER.md`](32_MODULE_DATA_TRANSFER.md) |

---

## الملفات المفتاحية

| ما تبحث عنه | الملف |
|---|---|
| الأعلام | `lib/core/platform/features/app_features.dart` |
| مسارات الـAPI | `lib/core/infra/network/rest/api_urls.dart` |
| ترتيب الـinterceptors + تسجيل ApiServices | `lib/core/di/injection_module.dart` |
| المسارات | `lib/routes/router.dart` |
| الألوان الخام ثم الدلالية | `lib/ui/theme/app_palette.dart` → `app_colors.dart` |
| الخطوط | `lib/core/infra/config/app_fonts.dart` |
| قراءة البيئة | `lib/core/infra/config/env.dart` |
| ترتيب الإقلاع · قرارُ أوّل شاشة | `lib/main.dart` + `lib/features/startup/` → [`23_STARTUP_SPLASH.md`](23_STARTUP_SPLASH.md) §٤ |
| شعارُ الإقلاع ولونُه (أندرويد) | `android/app/src/main/res/drawable/splash_*.xml` + `values/colors.xml` — **ولا يُولَّد من `flutter_native_splash`** |
| تبويبات الغلاف الرئيسي | `lib/routes/main_shell_page.dart` |
| مفاتيح التخزين | `lib/core/platform/storage/persistence_keys.dart` |
| هوية الـflavors | `flavor_settings.json` |
| قفل الصلاحيات | `permissions.lock.json` |

---

## أعطال شائعة

| العَرَض | السبب والعلاج |
|---|---|
| كل الطلبات تفشل و`Env.baseUrl` فارغ | شغّل بـ`--dart-define-from-file=.env.dev.json` |
| مفتاح الترجمة يظهر نصّاً خاماً | `codegen_loader.g.dart` لم يُولَّد — شغّل `gen_code.dart` كاملاً |
| النصّ لا يتغيّر عند تبديل اللغة | أضف `context.locale;` بأعلى `build()` أو `BlocBuilder.builder` |
| `Bad state: Cannot emit new states after calling close` | الـcubit يرث `Cubit` لا `SafeCubit` |
| المسار يرمي وقت التشغيل رغم أن الكود يُصرَّف | غير مسجَّل بـ`router.dart` — [§شاشة جديدة](#شاشة-جديدة) |
| `ProviderNotFoundException` داخل `appBar` | الـ`context` والد الـ`BlocProvider` — غلّف بـ`Builder` |
| أخطاء `*.g.dart` / `*.freezed.dart` | `dart run scripts/gen_code.dart` |
| `RenderFlex overflow` بـ`Row` | كل `Text` بـ`Row` أفقي: `Expanded` + `overflow: ellipsis` |
| تصادم hash بـ`injection.config.dart` | أعد تسمية الـalias المكرّر يدوياً (`_i693` → `_i6931`) |
| iOS يفشل بعد تغيير flavors | `flutter clean` ثم `cd ios && pod install` |
| APK غير موجود بعد `build_apk.dart` | `.env.{flavor}.json` مفقود بالجذر |
| الموديول مُشعَل ولا يفعل شيئاً | علَمٌ بلا نصفٍ بالباك أو بلا تسجيل DI — يفشل **صامتاً** |

المزيد: [`40_SCRIPTS.md`](40_SCRIPTS.md) §7

---

## قبل كل تسليم

```
[ ] dart analyze lib test                    → No issues found
[ ] flutter test                             → All tests passed!
[ ] dart run scripts/check_structure.dart    → لا مخالفات جديدة
[ ] الوثيقة المقابلة حُدِّثت                  → CLAUDE.md §Mandatory Documentation Sync
[ ] لا نصّ hardcoded · لا Color(0xFF...) · لا TextStyle(fontSize:) · لا رقمَ مقاسٍ خام
```

> ⚠️ **والاختبارُ الذي يُضاف يُثبَت أنه يحرس شيئاً**: عطِّل الحارسَ الذي كُتب له
> وشغّله — **إن بقي أخضر فهو يقيس اسماً لا سلوكاً**. سبعةُ اختباراتٍ بهذا
> المستودع كانت كذلك، وكلُّها من الجذر نفسِه: مقياسٌ يُطابق أكثرَ مما يُقصد به.

القواعد الصارمة كاملةً: [`03_RULES.md`](03_RULES.md)
