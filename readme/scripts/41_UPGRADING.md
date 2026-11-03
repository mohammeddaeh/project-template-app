# ترقية مشروعٍ مبنيٍّ على القالب إلى إصدارٍ أحدث

> لمن يملك مشروعاً أنشأه `setup_project.dart` من إصدارٍ أقدم، ويريد ما أُضيف بعده.
> **`template_update.dart` يحدّث ملفات القالب وحدها** (`templateOwned` — راجع
> [`40_SCRIPTS.md`](40_SCRIPTS.md) §8‑ط). وما يملكه المشروع — `main.dart` · `app.dart` ·
> `features/` · `pubspec.yaml` · `assets/` · `android/` · `app_features.dart` — لا يلمسه،
> وهذا الملف يقول ماذا يُنقل منها باليد، لكل إصدار.

إصدارُ مشروعك بـ`.template_manifest.json` (`templateRelease`)، والقالبُ بـ`TEMPLATE_VERSION`.
اقرأ أقسام هذا الملف **من إصدارك إلى الأحدث بالترتيب**.

---

## الطريق — لأي إصدار

```bash
# ١) فرعٌ نظيف، ونسخةٌ محلّية من القالب بجانب المشروع
git switch -c chore/template-upgrade
git -C ../app_template fetch --tags

# ٢) ما سيتغيّر بملفات القالب ومفاتيح الترجمة — بلا كتابة
#    سكربتُ القالب بأحدث نسخه لا نسخةُ المشروع: نسختك بعمر إصدارك، فتفوتها قدرةٌ أُضيفت
#    بعده. و`--to` يختار الإصدارَ الذي تنتقل إليه، أيّاً كان
git -C ../app_template pull --ff-only
dart run ../app_template/scripts/template_update.dart --template ../app_template --to v<الإصدار>

# ٣) الكتابة، ثم التعارضات بـ.template_update/ تُدمج يدوياً ويُحذف المجلد
dart run ../app_template/scripts/template_update.dart --template ../app_template --to v<الإصدار> --apply

# ٤) ملفات المشروع: ما غيّره القالب فيها بين إصدارك والجديد — يُقرأ ويُنقل باليد
git -C ../app_template diff v<إصدارك> v<الإصدار> -- \
  lib/main.dart lib/app.dart lib/routes lib/features pubspec.yaml \
  lib/core/platform/features/app_features.dart \
  android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml .gitignore

# ٥) قسمُ الإصدار أدناه، ثم
dart run scripts/gen_code.dart
dart analyze lib && flutter test
dart run scripts/check_structure.dart && dart run scripts/check_docs.dart
```

**وأخطاءُ المصرِّف بعد الخطوة ٣ هي الخريطة**: كلُّ اسمٍ تغيّر بواجهةٍ عامة يظهر خطأً
باسمه، وجدولُ الإصدار يقول بديله. أمّا ما **يغيّر السلوك بلا خطأ** فلا يكشفه إلا الجدول
— ولذلك عمودُه منفصل.

> ⚠️ **اختباراتُ القالب تصل مع التحديث** (`test/` بملفات القالب). اختبارٌ منها يفحص
> شاشةً غيّرها مشروعك بـ`features/` قد يفشل — هو يصف القالب لا مشروعك: كيّفه أو احذفه
> بالـcommit نفسه، ولا تتركه أحمر.

---

## `3.0.0` ⇐ التالي (غير مُصدَر)

| بمشروعك | البديل | ابحث |
|---|---|---|
| درجاتٌ عدّلتها بـ`lib/ui/theme/app_palette.dart` (حُذف) | انقلها إلى `palettes/standard.json` بالاسم نفسه، ثم `dart run scripts/gen_code.dart` | `git log -p -- lib/ui/theme/app_palette.dart` |
| درجةٌ أضفتها إلى `AppPalette` | مفتاحٌ بـ`colors` في **كل** ملفٍّ بـ`palettes/` | `git show HEAD:lib/ui/theme/app_palette.dart` |
| `AppPalette.x` بـ`app_colors.dart` · `AppColors.light()`/`dark()` بلا وسيط | `p.x` داخل `AppColors.light(AppPalette p)` · `AppThemePresets.fallback.light` خارجها | `git grep -n "AppPalette\." lib test` · `git grep -n "AppColors\.light()" lib test` |

وأوّلُ `gen_code.dart` بعد التحديث يكتب `app_palette.g.dart`؛ قبله لا يُبنى المشروع.

---

## `2.1.0` ⇐ `3.0.0`

| بمشروعك | البديل | ابحث |
|---|---|---|
| `PaginationBuilderWdg` · مسار `pagination_builder_wdg.dart` | `PaginationBuilder` · `pagination_builder.dart` | `git grep -nE "PaginationBuilderWdg\|pagination_builder_wdg" lib` |
| وسيطا `itemWdg:` · `allItemWdg:` | `itemBuilder:` · `allItemsBuilder:` | `git grep -nE "\b(itemWdg\|allItemWdg):" lib` |
| `ListItemAppearWdg` | `ListItemEntrance` — و`ListItemAppear` يبقى اسمَ نوع الحركة | `git grep -n ListItemAppearWdg lib` |

والسطرُ الواحد يصلحها كلّها:

```bash
git grep -lE "PaginationBuilderWdg|ListItemAppearWdg|pagination_builder_wdg|itemWdg|allItemWdg" lib test |
  xargs sed -i -E 's/PaginationBuilderWdg/PaginationBuilder/g; s/ListItemAppearWdg/ListItemEntrance/g; s/pagination_builder_wdg\.dart/pagination_builder.dart/g; s/\ballItemWdg\b/allItemsBuilder/g; s/\bitemWdg\b/itemBuilder/g'
```

ولا تغييرَ سلوكٍ صامت.

---

## `1.0.0` ⇐ `2.0.0`

### أ) يكسر البناء — المصرِّف يدلّك

| بمشروعك | البديل | ابحث |
|---|---|---|
| `AnalyticsModule` · `CrashReportingModule` · `RemoteConfigModule` · `PushNotificationsModule` · `InAppUpdatesModule` ومساراتها `*_module.dart` | `…Plugin` بـ`<name>_plugin.dart`. الأسماءُ القديمة `typedef` مُهمَلة تعمل، **والمسار وحده يكسر** — بـ`modules_bootstrap.dart` غالباً (`projectEdited`، فيصل تعارضاً يُدمج) | `git grep -nE "_module\.dart\|[A-Z]\w+Module\b" lib` |
| أحجامُ `TextThemeEx` · `showLoader` · `rSpace`/`rSize` · `dismissKeyboard` · `GlobalKeyExtensions` · `ThemeEx.dividerColor`/`scaffoldBackgroundColor` | `context.textTheme` (Material) · `context.showLoadingDialog()` · `context.screen` (R37) · `context.unfocus()` · `context.colors.dividerSubtle`/`.bgPage` | `git grep -nE "TextThemeEx\|showLoader\|rSpace\|rSize\|dismissKeyboard\|GlobalKeyExtensions\|context\.(dividerColor\|scaffoldBackgroundColor)" lib` |
| `AccountContextRefresher` | لا بديل — لا مستدعيَ له بالقالب. منفّذُك يبقى صنفاً عادياً بـ`features/` | `git grep -n AccountContextRefresher lib` |
| `DeviceIdService.saveSession(isPrimary:, …)` · `isPrimary` · `PersistenceKeys.deviceIsPrimary` | `saveSession(deviceSessionId: …)` وحده | `git grep -nE "isPrimary\|deviceIsPrimary" lib` |
| `leftPadding`/`rightPadding` وأخواتها بـ`app_padding_extension` | `startPadding`/`endPadding`… وتُعيد `EdgeInsetsDirectional` | `git grep -nE "(left\|right)(Padding\|Margin)" lib` |
| مفتاح الترجمة `voiceOpenSettings` بكود مشروعك | `kitOpenSettings` — يصل مع الترجمات، والقديم يبقى حتى تحذفه | `git grep -n voiceOpenSettings` |
| `KitNeedsPermission(permission)` | `KitNeedsPermission([permissions])` — قائمة | `git grep -n KitNeedsPermission lib` |
| `NavigationState`/`SettingsState` بـ`features/` (صنفان يدويّان) | `@freezed` — انقل الملفين من القالب كما هما إن لم تعدّلهما، ثم `gen_code` | الخطوة ٤ |
| **`AppFeatures.authMode` · `.showcase` · `.speechRecognition` · `.textToSpeech` · `.tokenInspector`** غائبة | `app_features.dart` ملكُ المشروع ولا يُحدَّث: أضف الأعلام الخمسة و`enum AuthMode` من القالب. **`authMode = AuthMode.required`** إن كان مشروعك يُلزم بالدخول (افتراضُ القالب `none` — §ب) · `showcase = false` إن كانت الرئيسية رئيسيةَ مشروعك | `undefined name 'authMode'` |
| `package:kit_contracts` لا يُحلّ · `kits.g.dart` غائب | بـ`pubspec.yaml` تحت `dependencies`: `kit_contracts: {path: packages/kit_contracts}` — ثم **`lib/core/di/kits.g.dart` بلا kit** (الكتلة أدناه) و`android/app/proguard-kits.pro` من القالب. ومنها `dart run scripts/kit.dart add <name>` لما تريد | `Target of URI doesn't exist` |
| `animations` لا يُحلّ | `animations: ^2.1.1` بـ`dependencies` | — |
| `StartupResolver(...)` · `LoginRepositoryImpl` · `TokenRefreshGatewayImpl` بـ`features/` | يأخذ كلٌّ `AuthSessionObserver` (والـresolver `StorageService` أيضاً)، وسطرُ إخبارٍ واحد بالموضع المناسب — انقله من الخطوة ٤. **بلا هذا يعمل التطبيق**، لكنّ `token_inspector` لا يرى شيئاً | الخطوة ٤ |

**مفاتيحُ الترجمة لا خطوةَ لها**: `template_update` يضيف ما بالقالب ولا يملكه المشروع
ويحدّث ما لم يلمسه، وقيمةٌ غيّرها الطرفان تبقى للمشروع وقيمةُ القالب بـ`.template_update/`.
لكن **بسكربت القالب** (الخطوة ٢، من `2.1.0` فأحدث) — نسخةُ مشروعٍ على `1.0.0` لا تعرف ذلك.

**`lib/core/di/kits.g.dart` بلا kit** — ما يكتبه `kit.dart` حين لا يُركَّب شيء:

```dart
// GENERATED by scripts/kit.dart — do not edit by hand.
// The only file in lib/ that imports a device kit (C18).

import 'package:get_it/get_it.dart';

/// The device kits this app is built with.
const installedKits = <String>[];

void registerKits(GetIt getIt) {}
```

### ب) يغيّر السلوك بلا خطأ — لا يكشفه إلا هذا الجدول

| ما يتغيّر | ماذا تفعل |
|---|---|
| **أوّلُ تشغيلٍ يعرض `WelcomeScreen`** مرّةً على الجهاز (`StartupDestination.welcome` · `WelcomeRoute` بـ`router.dart`) | انقل الشاشة والمسار من الخطوة ٤، أو اجعل `decideStartup` يتخطّاها إن لا ترحيب بمشروعك |
| `authMode` يقرّر أين يذهب الخروج بـ`app.dart` (`none` لا يذهب لشيء) | `AuthMode.required` يُبقي السلوكَ الإلزاميّ |
| `crash_reporting`/`analytics` لا يُرسلان بنسخة debug | مقصود — `ModulesBootstrap` يطفئهما هناك |
| رمزُ FCM يُحذف عند الخروج ويُعلَن بعد الدخول التالي | الباك يستقبل `announceToken` ثانيةً — تأكّد أن نقطته تقبل التكرار |
| زرُّ الرجوع بالقشرة بعد «تأكيد الخروج» يُغلق التطبيق فعلاً (`SystemNavigator.pop()`) | لا شيء — `main_shell_screen.dart` من الخطوة ٤ |
| انتقالُ الصفحات `PredictiveBack` بأندرويد، وتبويباتُ القشرة بـ«fade through» | لا شيء، أو `AppMotion` إن أردت غيره |
| الوضع الداكن: `onPrimaryContainer`/`onSecondaryContainer` داكنان فوق حاويتهما | لونٌ بـ`app_palette.dart` يعتمد على القديم يُراجَع (تعارضٌ من `projectEdited`) |
| حذفُ موديولٍ يحذف صفحتَه من جولة المرآة وسطرَها بالكتالوج | `showcase_test` يُفشل ودجةً عامّةً بلا مكان (R42) — حين يبقى الموديول ويُحذف مثالُه |

### ج) أمان وبناء — ملفاتُ المشروع، ولا شيء يذكّر بها

| الملف | ما يُنقل |
|---|---|
| **`.gitignore` بالجذر** | سطورُ المفاتيح: `key.properties` · `**/*.jks` · `**/*.keystore` · `**/*.p12` · `**/*.p8` · `**/*.mobileprovision` — وبعدها `git ls-files` **يجب** ألّا يُظهر مفتاحاً. مفتاحٌ دخل التاريخ يُعدّ مسرَّباً: يُستبدل، لا يُحذف من الشجرة وحسب |
| `android/app/build.gradle.kts` | قراءةُ `android/key.properties` لتوقيع release حين يوجد · `proguardFiles("proguard-kits.pro")` — بلا الثاني تفشل نسخة release بعد أوّل kit |
| `AndroidManifest.xml` | `<uses-permission android:name="android.permission.INTERNET"/>` صريحاً — بلاه نسخةُ release بلا شبكة حين لا تُعلنه حزمة. والأذوناتُ الأخرى `sync_platform_permissions.dart` يكتبها |
| `pubspec.yaml` | `freezed` و`flutter_native_splash` إلى `dev_dependencies` · `mockito` · `bloc_test` · `http_mock_adapter` · `cupertino_icons` لا يستعملها القالب — احذفها إن لا يستعملها مشروعك |

### د) الوثائق

`readme/` بمجلدات موضوعه (`start/` · `rules/` · `architecture/` · `ui/` · `modules/` ·
`scripts/`) والأرقامُ كما هي. `template_update` ينقلها، **وروابطُ مشروعك إليها** (بـ`docs/`
وتعليقاته) يكشفها `check_docs.dart`:

```bash
git grep -nE "readme/[0-9]{2}_" -- . ':(exclude)readme'
```

وما يُضاف بالقالب ولا يحتاج خطوة: موديول `token_inspector` (مطفأ) · حِزَمُ الأجهزة
(`kit.dart add`) · أدواتُ النقل (`port_inventory.dart`) · ودجاتٌ جديدة بالمكتبة — بـ
[`06_CAPABILITIES.md`](../rules/06_CAPABILITIES.md).
