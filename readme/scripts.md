# Scripts Reference

> **مرجع معماري:** [`core_architecture.md`](core_architecture.md)
> **يُحدَّث هذا الملف** عند إضافة/تعديل/حذف سكربت في `scripts/`.

كل السكربتات موجودة في `scripts/` وتُشغَّل من جذر المشروع:

```bash
dart run scripts/<script_name>.dart
```

يوجد حالياً **6 سكربتات**:

| السكربت | الغرض |
|---|---|
| `codegen.dart` | توليد الكود (build_runner + مفاتيح الترجمة) |
| `export.dart` | تصدير APK مع إدارة الإصدار تلقائياً |
| `sync_flavors.dart` | إعداد/إزالة flavors (Android productFlavors + أسماء + أيقونات + launch.json) |
| `gen_assets.dart` | مسح `assets/` وتوليد `lib/resources/assets.gen.dart` |
| `sync_fonts.dart` | اكتشاف خطوط `assets/fonts/` وتسجيلها في pubspec + `app_fonts.dart` |
| `sync_permissions.dart` | قراءة `AppFeatures` وتحديث أذونات Android/iOS تلقائياً |

---

## 1) `codegen.dart` — توليد الكود

```bash
dart run scripts/codegen.dart
```

يُشغّل 3 خطوات بالتسلسل:
1. `build_runner` — Retrofit · Freezed · Injectable · AutoRoute
2. `easy_localization:generate` → `locale_keys.g.dart`
3. `easy_localization:generate` → `codegen_loader.g.dart` (runtime reader)

> **ملاحظة:** التطبيق يستخدم `assetLoader: const CodegenLoader()` — إذا نُفِّذت الخطوة 2 فقط بدون 3 ستظهر المفاتيح الجديدة كنص خام بالواجهة لأن `codegen_loader.g.dart` لن يتحدّث.

### متى تُعيد تشغيله

| الملف/المنطقة المتغيّرة | السبب |
|---|---|
| `*_api_service.dart` | Retrofit يولّد `.g.dart` |
| `@injectable` / `@module` classes | تحديث `injection.config.dart` |
| `@RoutePage` / router | إعادة توليد `router.gr.dart` |
| `*.freezed.dart` models | إعادة بناء state classes |
| `ar.json` / `en.json` | تحديث `locale_keys.g.dart` و`codegen_loader.g.dart` |

---

## 2) `export.dart` — تصدير APK للإرسال

```bash
dart run scripts/export.dart [options]
```

| Flag | القيم | الافتراضي |
|---|---|---|
| `--flavor` | dev / staging / prod | dev |
| `--mode` | debug / release | debug |
| `--bump` | build / patch / minor / major | build |
| `--no-bump` | — | off |
| `--clean` | — | off |
| `--no-codegen` | — | off |

**أنواع الـ bump:**

| النوع | مثال قبل | مثال بعد | متى |
|---|---|---|---|
| `build` | 1.2.3+5 | 1.2.3+6 | كل dev build — الافتراضي |
| `patch` | 1.2.3+5 | 1.2.4+6 | bugfix للـ testers |
| `minor` | 1.2.3+5 | 1.3.0+6 | feature جديدة |
| `major` | 1.2.3+5 | 2.0.0+6 | إعادة هيكلة |

يرفع `versionCode` دائماً لمنع `INSTALL_FAILED_VERSION_DOWNGRADE`.
يقرأ `flavor_settings.json` لمعرفة `applicationId`/`displayName` لكل flavor، ويحدّث `app_name` بالإصدار الجديد إذا كان `showVersion: true`.
يشترط وجود ملف بيئة `.env.{flavor}.json` قبل البناء.
يكتب نتيجة البناء في `.dart_tool/last_build.json` (مُتجاهَل git).

**APK output:** `build/app/outputs/flutter-apk/{displayName}-{mode}-{version}.apk`

### بناء يدوي (بدون السكربتات)

```bash
# بدون flavors
flutter build apk --split-per-abi
flutter build appbundle -t lib/main.dart

# مع flavors (يدوي فقط إذا اضطررت)
flutter build apk --split-per-abi --flavor <flavor_name>
flutter build appbundle --flavor <flavor_name>
```

> **تحذير:** البناء اليدوي لا يرفع الإصدار ولا يُشغّل codegen — استخدم `export.dart` دائماً.

---

## 3) `sync_flavors.dart` — إعداد/إزالة الـ Flavors

```bash
dart run scripts/sync_flavors.dart           # إعداد الـ flavors
dart run scripts/sync_flavors.dart --reset   # إزالة كل شيء تابع للـ flavors
```

يقرأ `flavor_settings.json` ويُحدِّث تلقائياً:
1. `android/app/build.gradle.kts` — يحقن `productFlavors` + `applicationId` لكل flavor بين علامتَي `// BEGIN FLAVORS` / `// END FLAVORS`
2. `android/app/src/{flavor}/res/values/strings.xml` — اسم التطبيق (مع رقم الإصدار إذا `showVersion: true`)
3. `flutter_launcher_icons-{flavor}.yaml` — ملف إعداد لكل flavor
4. يُشغّل `flutter_launcher_icons` لكل flavor لتوليد الأيقونات
5. `.vscode/launch.json` — إعدادات تشغيل VSCode لكل flavor

`--reset` يحذف مجلدات `android/app/src/{dev,staging,prod}`، ملفات `flutter_launcher_icons-*.yaml`، كتلة `productFlavors` من `build.gradle.kts`، و`.vscode/launch.json` — إعادة المشروع لوضع Flutter عادي بلا flavors.

> ضع أيقونات PNG بحجم 1024×1024 في المسارات المذكورة بـ `flavor_settings.json` (انظر [`assets/app_icons/README.md`](../assets/app_icons/README.md)) قبل تشغيل السكربت.

---

## 4) `gen_assets.dart` — توليد Assets

```bash
dart run scripts/gen_assets.dart          # مسح + توليد
dart run scripts/gen_assets.dart --check  # فحص pubspec فقط (بدون كتابة)
```

يمسح `assets/` (باستثناء `fonts/`, `translations/`, `app_icons/`) بأي عمق تداخل، ويولّد `lib/resources/assets.gen.dart` بصنف `Assets` هرمي:

```
assets/images/vectors/logo.svg  →  Assets.images.vectors.logoSvg
assets/vectors/logo.svg         →  Assets.vectors.logoSvg
```

تسمية الـ getters:
- SVG بلا تعارض → `camelCase(stem) + 'Svg'` (مثال: `logo.svg` → `logoSvg`)
- PNG/JPG/... بلا تعارض → `camelCase(stem)` (مثال: `banner.png` → `banner`)
- عند تعارض الامتدادات لنفس الاسم → `camelCase(stem) + لاحقة الامتداد` (مثال: `logo.svg` + `logo.png` → `logoSvg` / `logoPng`)

يحدّث تلقائياً `lib/resources/assets.dart` (barrel) و`pubspec.yaml` (يضيف أي مسار مفقود تحت `flutter: assets:`)، ويحذف ملفات قديمة (`vectors.dart`, `icons.dart`, `images.dart`) إذا وُجدت.

---

## 5) `sync_fonts.dart` — توليد الخطوط

```bash
dart run scripts/sync_fonts.dart
```

سكربت تفاعلي:
1. يكتشف عائلات الخطوط تلقائياً من `assets/fonts/` (يدعم ملف مباشر أو مجلد فرعي باسم العائلة)
2. يسجّل الخطوط في `pubspec.yaml`
3. يسأل عن خيارات الخط للمستخدم (الاسم/العربي/اللاتيني/العائلة)
4. يحدّث `lib/core/infra/config/app_fonts.dart`

هياكل المجلدات المدعومة:
```
assets/fonts/Cairo-Regular.ttf          ← ملف مباشر
assets/fonts/NotoSans/NotoSans-Bold.ttf ← مجلد فرعي باسم العائلة
assets/fonts/0/NotoSans-Bold.ttf        ← مجلد فرعي بأي اسم
```

---

## 6) `sync_permissions.dart` — مزامنة الأذونات

```bash
dart run scripts/sync_permissions.dart
```

يقرأ الأعلام المفعّلة في `lib/core/platform/features/app_features.dart` (كل `static const x = true`) ويكتب الأذونات المطابقة في:
- `android/app/src/main/AndroidManifest.xml` (بين `<!-- SYNC:PERMISSIONS:START/END -->`)
- `ios/Runner/Info.plist` (بين نفس العلامتين)

يدعم حالياً: `camera`, `microphone`, `location`, `locationAlways`, `photos`, `fileStorage`, `contacts`, `bluetooth`, `pushNotifications`, `localNotifications`. الكتل مُدارة بعلامات sync آمنة — لا تلمس أي إدخال يدوي خارجها، وتُحذف/تُضاف تلقائياً في كل تشغيل حسب الأعلام الحالية.

---

## 7) Troubleshooting

| Issue | Fix |
|-------|-----|
| `*.g.dart` / `*.freezed.dart` errors | Run `dart run build_runner build --delete-conflicting-outputs` (أو `dart run scripts/codegen.dart`) |
| Routes not found after `@RoutePage` change | Run `codegen.dart` |
| iOS build fails after flavors change | `flutter clean` + `cd ios && pod install` |
| DI registration errors | Run `codegen.dart`, تحقق من `injection.config.dart` |
| Localization key shows as raw string at runtime | شغّل `codegen.dart` كاملاً (يشمل locale_keys.g.dart + codegen_loader.g.dart) |
| `.tr()` text doesn't update on locale switch | أضف `context.locale;` في أعلى `build()` / `BlocBuilder.builder` |
| `injection.config.dart` hash collision (DI fails) | أعد تسمية alias المكرر يدوياً (مثال: `_i693` → `_i6931`) في الملف المولَّد |
| APK غير موجود بعد `export.dart` | تحقق من وجود `.env.{flavor}.json` بجذر المشروع قبل البناء |

## 8) Script Usage Rules

- استخدم السكربتات بدل التعديل اليدوي للإعدادات كلما أمكن.
- أعد تشغيل `codegen.dart` بعد أي تغيير يمس DI/router/API/الترجمة.
- حدّث هذا الملف عند إضافة أو تعديل أي سكربت في `scripts/`.

## 9) Related Docs

- [`new_developer_guide.md`](new_developer_guide.md) — onboarding + full structure
- [`core_architecture.md`](core_architecture.md) — architecture principles
- [`rest_api.md`](rest_api.md) — REST workflow

*Last updated: 2026-07-23 — أعيدت كتابة الملف بالكامل ليطابق السكربتات الفعلية الـ6 الموجودة في `scripts/` (كان يوثّق 11 سكربتاً غير موجود ويتجاهل 3 سكربتات حقيقية).*
