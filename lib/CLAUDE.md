# lib/CLAUDE.md — UI Rules, Imports, Localization

> يُحمَّل تلقائياً عند العمل في أي ملف داخل lib/.
> **اسم الـ package الإلزامي:** `app_template` — لا تستخدم اسماً آخر أبداً.

---

## Correct Import Paths

| Resource | Correct Path |
|---|---|
| Feature ApiService | `package:app_template/Features/{feature}/data/datasources/{feature}_api_service.dart` |
| ApiUrls | `package:app_template/core/infra/network/rest/api_urls.dart` |
| ApiResponse | `package:app_template/core/foundation/contracts/api_response.dart` |
| Failure | `package:app_template/core/foundation/errors/failure.dart` |
| BaseRepository | `package:app_template/core/infra/network/boundary/base_repository.dart` |
| HandleBodyResponse | `package:app_template/core/infra/network/rest/handle_body_response.dart` |
| PersistenceKeys | `package:app_template/core/platform/storage/persistence_keys.dart` |
| Extensions barrel (UI) | `package:app_template/presentation/extensions/extensions.dart` |
| Widgets barrel | `package:app_template/shared/widgets/widgets.dart` |
| PaginationCubit | `package:app_template/presentation/shared/pagination/pagination_cubit.dart` |
| BaseUseCase | `package:app_template/core/foundation/domain/base_usecase.dart` |
| UseCaseParams | `package:app_template/core/foundation/domain/use_case_params.dart` |
| NoParams | `package:app_template/core/foundation/domain/no_params.dart` |
| LocaleKeys | `package:app_template/resources/locale_keys.g.dart` |
| Router | `package:app_template/routes/router.gr.dart` |

## Extensions imported directly (NOT in barrel)

```dart
import 'package:app_template/presentation/extensions/screen_sizes_extensions.dart';
// context.sw, context.sh, context.bottomPadding, context.topPadding

import 'package:app_template/presentation/extensions/app_padding_extension.dart';
// 16.allPadding, 16.horizontalPadding, 16.verticalPadding / 4.widthBox, 4.heightBox

import 'package:app_template/presentation/theme/theme_extensions.dart';
// context.colors, context.textTheme, context.colorScheme

// ⚠️ feedback — لا يُصدَّر من extensions.dart — مطلوب صراحةً في كل ملف
import 'package:app_template/presentation/feedback/feedback_extension.dart';
```

> **محذوف:** `context.showToast(...)` و`context.showSimpleToast(...)` — استخدم `context.feedback.*`

---

## Feedback API

```dart
context.feedback.success('msg');
context.feedback.error('msg');
context.feedback.warning('msg', title: 'title');
context.feedback.toast('msg');
```

## Locale API

```dart
context.isAr         // bool
context.isRtl        // bool
context.appLocale    // AppLocale enum
context.changeLocale(AppLocale.english);
context.toggleLocale();
```

---

## Typography — قواعد النصوص (صارمة)

| Style | fontSize | weight | الاستخدام |
|---|---|---|---|
| `displayLarge` | 24 | w800 | أكبر عنوان hero |
| `headlineLarge` | 26 | w700 | page title |
| `headlineMedium` | 20 | w700 | section title |
| `headlineSmall` | 14 | w700 | card title |
| `bodyMedium` | 14 | w500 | default body |
| `bodySmall` | 12 | w400 | secondary body |
| `labelLarge` | 14 | w400 | button, chip |

**ممنوع ❌:** `TextStyle(fontSize: 16)` · `fontFamily: 'NotoSansArabic'` hardcoded · `TextStyle(color: Color(...))`
→ استخدم: `context.textTheme.bodyMedium` + `.copyWith(color: context.colors.X)`

## Colors — قواعد الاستخدام (صارمة)

```
Figma hex → AppPalette (raw) → AppColors.light/dark (semantic) → context.colors.X
```

**ممنوع ❌:** `Color(0xFF...)` في الـ UI · `AppPalette.X` خارج `app_colors.dart` · `Colors.blue`

---

## Localization — 4 خطوات إلزامية دائماً

```
1. assets/translations/ar.json   ← أضف المفتاح
2. assets/translations/en.json   ← أضف المفتاح
3. شغّل الأمرَين:
   flutter pub run easy_localization:generate -f keys -O lib/resources -S assets/translations -o locale_keys.g.dart
   flutter pub run easy_localization:generate -f json -O lib/resources -S assets/translations -o codegen_loader.g.dart
4. في الـ UI: LocaleKeys.myKey.tr()
```

> لماذا أمران؟ التطبيق يقرأ من `codegen_loader.g.dart` وقت التشغيل — إهمال الأمر الثاني يجعل الترجمة تظهر كـ key.

**ممنوع ❌:** `Text('نص عربي')` hardcoded · `locale.languageCode == 'ar'` · مفتاح في ar.json فقط بدون en.json

## Locale-Reactive Widgets — قاعدة إلزامية

`.tr()` لا تُسجِّل الـ element تلقائياً — يجب الوصول لـ `context.locale` في نفس `build()`:

```dart
// ✅ StatelessWidget
@override
Widget build(BuildContext context) {
  // ignore: unnecessary_statements — EasyLocalization dependency
  context.locale;
  return Text(LocaleKeys.title.tr());
}

// ✅ BlocBuilder
BlocBuilder<MyCubit, MyState>(
  builder: (context, state) {
    context.locale; // ignore: unnecessary_statements
    return Text(LocaleKeys.label.tr());
  },
)

// ✅ إذا استخدمت context.isAr في نفس build() — كافٍ (يُسجِّل تلقائياً)
```

---

## Text — Overflow & Expansion (صارمة)

- كل `Text` داخل `Row` أفقي → `Expanded` + `overflow: TextOverflow.ellipsis`
- كل `Text` قابل للنمو (body/card/list) → `maxLines` + `overflow: TextOverflow.ellipsis`
- **ممنوع ❌:** `Text` بدون `Expanded` داخل `Row` → RenderFlex overflow في runtime

## Images — قواعد السلامة

| الحالة | الحل |
|---|---|
| صورة شخص / أفاتار | `AvatarWidget(initial: name.isNotEmpty ? name[0] : '?', imageUrl: url)` |
| صورة محتوى من شبكة | `NetworkImageWidget(url: url ?? '')` |
| صورة عامة مع cache | `CachedImageWidget(url: url ?? '')` |
| **ممنوع ❌** | `Image.network(url)` مباشرة — لا cache، لا error widget، لا placeholder |

- `imageUrl: null` → crash في runtime — **دائماً** `url ?? ''` قبل التمرير

## context.mounted — إلزامي بعد كل await

بعد أي `await` → تحقق من `context.mounted` قبل أي استخدام لـ `context`:

```dart
await _someService.call();
if (!context.mounted) return;
context.router.push(...);
context.feedback.success(...);
```

**متى يُطبَّق؟** كل مرة تستخدم `context` بعد `await` داخل `StatefulWidget` أو listener أو initState.

## context.textTheme — ممنوع Theme.of(context)

```dart
// ✅ صحيح
context.textTheme.bodyMedium
context.textTheme.headlineLarge?.copyWith(color: context.colorScheme.primary)

// ❌ ممنوع
Theme.of(context).textTheme.bodyMedium
```

## Feedback — التمييز بين الأنواع

| الحالة | الأداة |
|---|---|
| رسالة عابرة (toast / snackbar) | `context.feedback.success/error/warning/toast` |
| حالة ثابتة في الشاشة (نجاح) | `SuccessStateWidget(messageKey: ...)` |
| قائمة فارغة | `EmptyStateWidget(titleKey: ..., icon: ...)` |
| خطأ مع retry | `ErrorStateWidget(messageKey: ..., onRetry: ...)` |
| لا إنترنت | `NoInternetWidget(onRetry: ...)` |
| صيانة | `const MaintenanceWidget()` |

**ممنوع ❌:** `context.feedback.error` لحالة ثابتة في الشاشة — استخدم `ErrorStateWidget`.

---

## Optional Platform Services

```dart
// تفعيل خدمة — خطوة واحدة فقط في app_features.dart:
static const biometrics = true;  // → يسجّل BiometricsService تلقائياً
```

| Flag | الخدمة |
|---|---|
| `biometrics = true` | `BiometricsService` |
| `clipboard = true` | `ClipboardService` |
| `shareSheet = true` | `ShareService` |
| `fileOperations = true` | `FileService` |
| `appLifecycle = true` | `AppLifecycleService` |
| `certificatePinning = true` | `CertificatePinningConfig` on Dio |
