# Scripts Reference

> **مرجع معماري:** [`11_CORE.md`](../architecture/11_CORE.md)
> **يُحدَّث هذا الملف** عند إضافة/تعديل/حذف سكربت في `scripts/`.

كل السكربتات موجودة في `scripts/` وتُشغَّل من جذر المشروع:

```bash
dart run scripts/<script_name>.dart
```

سكربتات Dart بـ`scripts/`، و**مُطلِق PowerShell واحد** (`new_project.ps1`) — مجمّعةً بمتى تحتاجها. وما تتشاركه — طباعةُ الأقسام، و`die`، و`runCli` الذي
يحوّل خطأً متوقَّعاً (ملفٌّ غائب · JSON تالف · خادمٌ لا يُجيب) إلى سطرٍ و`exit 2` بدل stack trace —
بـ`scripts/src/cli.dart`:

| السكربت | الغرض |
|---|---|
| **كلَّ يوم** | |
| `gen_code.dart` | توليد الكود (build_runner + مفاتيح الترجمة) |
| `build_apk.dart` | تصدير APK مع إدارة الإصدار تلقائياً |
| **`check_structure.dart`** | **فاحصٌ آليّ لقواعد البنية** (`F04` · `F10` · `F13` · `F19`…`F21` · `F35`…`F37` · `C01`…`C20` · `L01`) — يفشل بمخالفة **جديدة** ويتسامح مع الدَّين المسجَّل |
| **`check_docs.dart`** | **روابط التوثيق المعطوبة** — كل رابط Markdown نسبيّ يصل ملفاً موجوداً، ورابطُ GitHub إلى `_template/` حين يوجد المجلد. حاجبٌ بالـCI. راجع §8‑ح |
| **مشروعٌ جديد — مرّةً واحدة** | |
| **`new_project.ps1`** | **مشروعٌ جديد بأمرٍ واحد من أي مجلد** — يُنادى عبر `irm … \| iex` بلا استنساخٍ مسبق: يفحص الأدوات، ويستنسخ القالب بتاريخٍ نظيف، ثم يسلّم `setup_project.dart` كلَّ القيم ويُنشئ أوّل commit **ويرفعه لمستودع GitHub يُسأل عنه** (ويُنشئه بـ`gh` إن وُجد). راجع §8‑د |
| **`setup_project.dart`** | **الإعداد الأول لمشروع جديد** — الهوية (اسم · Application ID · **اسم حزمة Dart**) + `BASE_URL` + الوحدات الاختيارية ذات الكلفة الخارجية، ثم فحص صحة كامل. تفاعليّ، أو بوسائط بلا أسئلة |
| `sync_flavors.dart` | إعداد/إزالة flavors (ملفات `.env` + Android productFlavors + أسماء + أيقونات + launch.json) |
| **`gen_splash_assets.dart`** | **موردا شاشة الإقلاع لأندرويد** من الـSVG — و`android: false` بـ`flutter_native_splash` بقرار |
| **`prune_project.dart`** | **تنظيف ما لا يستعمله أحد** — مفاتيح ترجمة · أصول (تُحذف بـ`--apply`) · موديولات مطفأة · ملفات بلا مستورِد · حزم بلا import (تُعرض). راجع §8‑ي |
| **مولّدات** | |
| **`scaffold_feature.dart`** | **مولّد شريحة CRUD كاملة** — كل الطبقات (dtos → models → datasources → repositories → entities → params → usecases → cubits → pages) بحقلٍ تجريبي واحد، موصولة (`api_urls.dart` · `injection_module.dart` · `router.dart` · الترجمة) ومُختبَرة صحّتُها تلقائياً. ويربط سلسلة المزامنة/الصلاحية تلقائياً إن كانت مُشعَلة بـ`AppFeatures` |
| **`scaffold_module.dart`** | **مولّد موديول اختياري جديد** — الأركان الثلاثة معاً دائماً: علَم `AppFeatures` · تسجيل `ModulesBootstrap` · صفّ بالجدول الواحد `30_MODULES.md` |
| `gen_assets.dart` | مسح `assets/` وتوليد `lib/resources/assets.gen.dart` |
| `sync_palettes.dart` | البالتات من `palettes/*.json` ⇐ `app_palette.g.dart` + `app_theme_presets.g.dart` + أسماء الثيمات بالترجمة — خطوةٌ بـ`gen_code.dart`. راجع §5‑ب |
| `gen_permission_keys.dart` | يولّد `permission_keys.g.dart` من الصلاحيات التي **يفرضها الخادم** — يرفع كشف المفتاح المطبعي من وقت التشغيل إلى **وقت الترجمة**. اختياري |
| **الأصول والمنصّة** | |
| `sync_fonts.dart` | اكتشاف خطوط `assets/fonts/` وتسجيلها في pubspec + `app_fonts.dart` |
| `svg_inline_styles.dart` | يُنزل قواعد `<style>` بملف SVG إلى سمات مباشرة — `flutter_svg` لا يطبّقها فيرسم أسود. راجع §4 |
| `sync_platform_permissions.dart` | قراءة `AppFeatures` وتحديث أذونات Android/iOS تلقائياً |
| **`kit.dart`** | **حِزَم الأجهزة** — `list` · `add <name>` · `remove <name>` · `test`. التركيب والإزالة بأمرٍ واحد (تبعية · تسجيل · أذونات · قواعد R8)، والجولة لا تترك فرقاً بـgit. راجع [`24_DEVICE_KITS.md`](../modules/24_DEVICE_KITS.md) |
| **`pull_figma.dart`** | **يسحب تصاميم الفيغما** عبر REST إلى `.figma/` — صورةٌ وخلاصةٌ مقروءة وشجرةٌ مُقلَّمة لكل إطار |
| **القالب والمشروع بعد الإنشاء** | |
| **`template_drift.dart`** | **ما غيّره المشروع بملفات القالب ولم يُسجَّل** — يقارن بنسخة القالب حين بدأ المشروع. راجع §8‑ط |
| **`template_update.dart`** | **يجلب نسخةً أحدث من القالب** — يحدّث ما لم يلمسه المشروع، ويضع التعارض جانباً. راجع §8‑ط |
| **`audit_template.dart`** | **تدقيقٌ ذاتيّ استشاريّ للقالب** — وصل الموديولات بإقلاعها · فجوة مزامنة حرجة · مسارات بلا نقطة تنقّل ظاهرة · ملفات readme/ خارج جدول التزامن · تاريخٌ بالملفات التي تصل المشاريع |
| **نقلُ تطبيقٍ قائم** | |
| **`port_inventory.dart`** | **جردُ تطبيقٍ قديم قبل نقله** — المنصّة · الشاشات · الـendpoints · الخطوط · SVG · إشارات القدرات ⇐ ما يقابلها بالقالب. راجع §8‑ك |
| **`device_shot.dart`** | **لقطةٌ من جهاز أندرويد** بجانب لقطة التطبيق القديم، ونصوص الشاشة، والعرض المنطقيّ. راجع §8‑ك |
---

## 1) `gen_code.dart` — توليد الكود

```bash
dart run scripts/gen_code.dart
```

يُشغّل **7 خطوات** بالتسلسل:

1. `build_runner` — Retrofit · Freezed · Injectable · AutoRoute
1‑ب. `sync_palettes.dart` → `app_palette.g.dart` + `app_theme_presets.g.dart` + أسماءُ الثيمات بملفات الترجمة — من `palettes/*.json` (§5‑ب). **بعد** `build_runner`: يمحو `.g.dart` يظنّه مخرَجاً قديماً له
2. `easy_localization:generate` → `locale_keys.g.dart`
3. `easy_localization:generate` → `codegen_loader.g.dart` (القارئ وقت التشغيل)
4. `gen_assets.dart` → `assets.gen.dart` (+ مسارات `pubspec.yaml` الناقصة)
5. `gen_permission_keys.dart` → `permission_keys.g.dart` — يُتخطّى بصمت إن لم يوجد `permissions.lock.json`
6. `dart format` على `lib/resources/` — easy_localization و`gen_assets.dart` لا يُنسّقان ما يولّدانه، وفحصُ التنسيق بالـCI حاجب

> **ملاحظة:** التطبيق يقرأ `assetLoader: const CodegenLoader()` — فتنفيذ الخطوة 2
> بلا 3 يجعل المفاتيح الجديدة **تظهر نصّاً خاماً** بالواجهة.

> **لماذا الخطوة 4 داخل السلسلة**: بدونها، من يضيف صورة ويشغّل «توليد الكود» لا
> يتحدّث عنده `assets.gen.dart`، فيقع على خطأ ترجمة غامض —
> أو يعدّل الملف المولَّد يدوياً فيُمحى بأول تشغيل صحيح.

> **`sync_fonts.dart` يبقى خارجه عمداً** — تفاعليّ يسأل عن اسم الخط وعائلته، فلا
> يصلح ضمن أمر آلي يُشغَّل بالـCI. شغّله يدوياً عند إضافة خط.

### متى تُعيد تشغيله

| الملف/المنطقة المتغيّرة | السبب |
|---|---|
| `*_api_service.dart` | Retrofit يولّد `.g.dart` |
| `@injectable` / `@module` classes | تحديث `injection.config.dart` |
| `@RoutePage` / router | إعادة توليد `router.gr.dart` |
| `*.freezed.dart` models | إعادة بناء state classes |
| `ar.json` / `en.json` | تحديث `locale_keys.g.dart` و`codegen_loader.g.dart` |
| أي ملف بـ`assets/` | تحديث `assets.gen.dart` و`pubspec.yaml` |
| `permissions.lock.json` | تحديث `permission_keys.g.dart` |
| أي ملف بـ`palettes/` | تحديث `app_palette.g.dart` و`app_theme_presets.g.dart` وأسماء الثيمات بـ`ar.json`/`en.json` |

---

## 2) `build_apk.dart` — تصدير APK للإرسال

```bash
dart run scripts/build_apk.dart [options]
```

| Flag | القيم | الافتراضي |
|---|---|---|
| `--flavor` | dev / staging / prod | dev |
| `--mode` | debug / release | debug |
| `--bump` | build / patch / minor / major | build |
| `--no-bump` | — | off |
| `--clean` | — | off |
| `--no-codegen` | — | off |
| `--allow-token-trace` | — | off |

**قبل أي خطوة، ببناء `prod` أو `release`**: يعدّد كلَّ ما تركه المطوّر من أداة
التوكن — العلَم `tokenInspector = true`، وكلَّ نداء `TokenInspector.*` و
`TokenInspectorPanel(` خارج الموديول — بملفّه وسطره. تفاعلياً يسأل `[y/N]`،
و`N` يوقف البناء **قبل رفع الإصدار**. وبلا طرفية (CI) يُفشل، إلا مع
`--allow-token-trace`. والنسخة لا تعرض شيئاً منها على أي حال
([`33_MODULE_TOKEN_INSPECTOR.md`](../modules/33_MODULE_TOKEN_INSPECTOR.md) §٤) — فهذا تذكيرٌ
بالحذف، لا حارسُ أمان.

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
يكتب نتيجة البناء في `.dart_tool/last_build.json` (مُتجاهَل git) — **ولا قارئ له
اليوم** — لا `scripts/install.dart` بالمستودع. يُترك مكتوباً لمن يريد بناء خطوة تثبيت أو رفع أثر
بالـCI، لا لأن شيئاً يستهلكه.

**APK output:** `build/app/outputs/flutter-apk/{displayName}-{mode}-{version}.apk`

### التوقيع — مفتاحُ النشر لا يدخل git

`android/app/build.gradle.kts` يوقّع نسخة release بمفتاح `android/key.properties` حين
يوجد، وبمفتاح debug حين يغيب (يكفي لـ`flutter run --release`، ويرفضه المتجر تحديثاً).
و`build_apk.dart --flavor prod --mode release` ينبّه إن غاب — **يسأل عن وجود الملف
وحده، ولا يفتحه**.

```properties
# android/key.properties — على جهاز البناء وحده
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=C:/keys/upload-keystore.jks   # خارج المستودع أفضل
```

| الحارس | ما يمنعه |
|---|---|
| `.gitignore` (الجذر و`android/`) | `key.properties` · `*.jks` · `*.keystore` · `*.p12` · `*.p8` · `*.mobileprovision` **بأي مكان** |
| `test/signing_secrets_test.dart` | سطرٌ يُحذف من `.gitignore`، أو مفتاحٌ مُتتبَّعٌ أصلاً — يسأل git نفسه |

⛔ **مفتاحٌ دخل git مرّةً بقي بتاريخه** — حذفُه بـcommit لاحق لا يمحو شيئاً، ومن
يملكه يستطيع نشر «تحديث» لكل نسخةٍ مثبَّتة. ونقلُ تطبيقٍ قائم يحتاج **مفتاحَه القديم**
نفسه، وإلا لم يُثبَّت فوقه (skill `port-to-template`).

### بناء يدوي (بدون السكربتات)

```bash
# بدون flavors
flutter build apk --split-per-abi
flutter build appbundle -t lib/main.dart

# مع flavors (يدوي فقط إذا اضطررت)
flutter build apk --split-per-abi --flavor <flavor_name>
flutter build appbundle --flavor <flavor_name>
```

> **تحذير:** البناء اليدوي لا يرفع الإصدار ولا يُشغّل codegen — استخدم `build_apk.dart` دائماً.

---

## 3) `sync_flavors.dart` — إعداد/إزالة الـ Flavors

```bash
dart run scripts/sync_flavors.dart           # إعداد الـ flavors
dart run scripts/sync_flavors.dart --reset   # إزالة كل شيء تابع للـ flavors
```

يقرأ `flavor_settings.json` ويُحدِّث تلقائياً:
1. `.env.{flavor}.json` — يُنشئ الناقص منها من `.env.example.json` (تفصيل أدناه)
2. `android/app/build.gradle.kts` — يحقن `productFlavors` + `applicationId` لكل flavor بين علامتَي `// BEGIN FLAVORS` / `// END FLAVORS`
3. `android/app/src/{flavor}/res/values/strings.xml` — اسم التطبيق (مع رقم الإصدار إذا `showVersion: true`)
4. `flutter_launcher_icons-{flavor}.yaml` — ملف إعداد لكل flavor
5. يُشغّل `flutter_launcher_icons` لكل flavor لتوليد الأيقونات
6. `.vscode/launch.json` — إعدادات تشغيل VSCode لكل flavor

`--reset` يحذف مجلدات `android/app/src/{dev,staging,prod}`، ملفات `flutter_launcher_icons-*.yaml`، كتلة `productFlavors` من `build.gradle.kts`، و`.vscode/launch.json` — إعادة المشروع لوضع Flutter عادي بلا flavors. **لا يحذف ملفات `.env.*.json`** — فهي تحمل روابط حقيقية لا يولّدها شيء.

> ضع أيقونات PNG بحجم 1024×1024 في المسارات المذكورة بـ `flavor_settings.json` (انظر [`assets/app_icons/README.md`](../../assets/app_icons/README.md)) قبل تشغيل السكربت.

### 3.1) ملفات البيئة — تُنشأ تلقائياً

`.env.dev.json` · `.env.staging.json` · `.env.prod.json` **مُتجاهَلة في `.gitignore`** (تحمل روابط API حقيقية)، فمن يستنسخ المشروع لا تصله — و`--dart-define-from-file` ينكسر عند أول `flutter run`. لذلك يضمنها السكربت في كل تشغيل:

| الحالة | ما يفعله السكربت |
|---|---|
| الملف غير موجود | يُنشئه بكل مفاتيح `.env.example.json` بقيمها المثالية — `🆕` |
| موجود لكن ينقصه مفتاح أضافه القالب لاحقاً | يضيف المفتاح الناقص فقط — `➕` |
| موجود وكامل وما زال يحمل قيمة المثال | تحذير `⚠️` بالمفتاح — القيمة لا تُلمس |
| موجود ومعبَّأ | `🔐 ok` |
| موجود لكنه JSON تالف | `❌` ويُترك كما هو — يُصلَح يدوياً |

**قيمة موجودة لا تُعدَّل أبداً** — التشغيل المتكرر آمن. قيمة فارغة `""` في القالب تعني مفتاحاً اختيارياً فلا يُنبَّه عليها.

المصدر هو `.env.example.json` (مرفوع في git) — **أضف كل مفتاح بيئة جديد إليه**، وإلا لن يصل مَن يستنسخ المشروع. الملف الوحيد المطلوب اليوم: `BASE_URL` (يقرأه [`lib/core/infra/config/env.dart`](../../lib/core/infra/config/env.dart)).

فما يحتاجه المطوّر الجديد هو تشغيل السكربت ثم لصق الروابط الحقيقية في الملفات الثلاثة — السكربت يطبع أسماءها في نهاية تشغيله.

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

يحدّث تلقائياً `lib/resources/assets.dart` (barrel) و`pubspec.yaml` — **يضيف** أي مسار مفقود تحت `flutter: assets:` **ويحذف** أي مسارٍ زائل (مجلَّدٌ فرغ من الملفات أو حُذف كلّياً منذ آخر تشغيل) داخل الكتلة المُدارة وحدها، دون لمس المسارات الثابتة `fonts/`/`translations/`/`app_icons/` — ويحذف ملفات قديمة (`vectors.dart`, `icons.dart`, `images.dart`) إذا وُجدت.

**و`<style>` بأي SVG يُنبَّه عليه** — `flutter_svg` لا يطبّق قواعده، فيُرسم الشكل
أسود بلا خطأ. الإصلاح مرّةً لكل ملف:

```bash
dart run scripts/svg_inline_styles.dart assets/images/logo.svg
```

ينقل خصائص كل صنفٍ سماتٍ على عناصره ويحذف `<style>` و`class`، والهندسةُ لا تُلمس.
والحارس الحاجب `test/svg_no_style_test.dart`.

> **لماذا يحذف لا يضيف فقط**: مجلّدٌ حُذف يبقى سطره بـ`pubspec.yaml` فيُشحَن بكل بناء بلا تحذير. فالفحص يقارن الكتلة المُدارة بما مسحه فعلاً، لا بما أُضيف تاريخياً.

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

**والوزن يُقرأ من الملف لا من اسمه** (`OS/2 usWeightClass`). Flutter يختار الوجه
بالوزن المكتوب داخل الملف، ويُسمِّك اصطناعياً حين يزيد الطلب 200 فأكثر: ملفٌّ
اسمُه «Regular» ووزنُه الداخلي 400 مسجَّلٌ بـ600 يرسم كل `w600` مسمَّكاً وكل `w400`
بوجهٍ خطأ — **وكل الشاشات أثقل، ولا شيء يفشل**. حين يخالف الاسمُ الملفَّ يُطبع
تحذير ويُسجَّل وزنُ الملف. و`test/font_weights_test.dart` يُفشل أي سطرٍ بـ`pubspec.yaml`
عُدِّل باليد فخالف ملفَّه.

---

## 5‑ب) `sync_palettes.dart` — البالتات والثيمات

خطوةٌ بـ`gen_code.dart`، فلا يُشغَّل وحده عادةً. **كلُّ ألوان التطبيق من ملفٍّ بـ`palettes/`، وكلُّ ملفٍّ ثيمٌ يختاره المستخدم:**

```
palettes/
  standard.json   ← الإلزاميّ: الثيم الافتراضي ومرجعُ المفاتيح
  ocean.json      ← ثيمٌ ثانٍ بالإعدادات
  examples/       ← لا يُقرأ: sand · midnight · olive · ocean جاهزةٌ للنقل
```

```json
{
  "name": { "ar": "المحيط", "en": "Ocean" },
  "colors": { "brandSurface": "#0D3A2F", "primaryMain": "#002623", "…": "…" }
}
```

| يكتب | من |
|---|---|
| `lib/ui/theme/app_palette.g.dart` — صنفُ `AppPalette` ونسخةٌ بـ`AppPalettes` لكل ملف | `colors` |
| `lib/ui/theme/app_theme_presets.g.dart` — `standard` أوّلاً ثم البقية بالمعرّف | اسمُ الملف |
| `themePreset<Id>` بكل ملف بـ`assets/translations/` (بعد `themePreset`) | `name` — لغةٌ لكل ملف ترجمة، والناقصةُ تُفشل |

- **هويةٌ جديدة**: عدّل درجات `standard.json` ثم التوليد. **ثيمٌ ثانٍ**: انسخه باسمٍ جديد (snake_case) وبدّل درجاته واسمه.
- **كلُّ بالتٍ بمفاتيح `standard.json` نفسها** بلا نقصٍ ولا زيادة — المخالفةُ تُفشل التوليد وتسمّي المفتاح.
  ودرجةٌ جديدة تُضاف إلى كل الملفات، ثم تُقرأ بـ`AppColors.light`/`dark`.
- **الربطُ من الدرجات إلى الأدوار واحدٌ** (`app_colors.dart`)، فالبالتُ تغيّر الهوية كاملةً: الأزرار والأسطح والنصوص.
- **حذفُ الملف يحذف الثيم ومفتاحَ اسمه**، ومستخدمٌ كان اختاره يعود إلى `standard`. واسمُ الملف لا يُغيَّر بعد الشحن: هو ما يُحفظ.
- ثم `flutter test test/color_contrast_test.dart` — يمرّ على كل بالتٍ بالوضعين.
- **القالبُ يُشحن بثلاثة ثيمات** (`standard` · `ocean` بحري · `sand` رملي)، فالمنتقي ظاهرٌ بالإعدادات من أوّل تشغيل.
  ومشروعٌ بهويةٍ واحدة يحذف `ocean.json` و`sand.json` ثم التوليد، فيختفي المنتقي.
- **`palettes/examples/`** بالتتان أخريان (ليلي · زيتوني) — السكربت لا يقرأ المجلدات الفرعية، فلا تظهران حتى يُنقل
  ملفُّهما إلى `palettes/`. وكلُّ بالتٍ غيرِ `standard` بالأساسيّ والبارز لها، ورماديّاتٍ مائلةٍ نحو لونها، وألوانِ
  الحالات كما بـ`standard.json`؛ تمرّ بفحص التباين، لكنها **بُنيت بقاعدةٍ لا بعين مصمّم**: تُراجَع على الجهاز.
- **شاشةُ الإقلاع الأصلية بلون `standard` وحده** (`brandSurface` · `splash_background` · `flutter_native_splash.yaml`): النظام يرسمها قبل أن يعرف التطبيقُ اختيارَ المستخدم.

---

## 6) `sync_platform_permissions.dart` — مزامنة الأذونات

```bash
dart run scripts/sync_platform_permissions.dart
```

يقرأ الأعلام المفعّلة في `lib/core/platform/features/app_features.dart` (كل `static const x = true`) ويكتب الأذونات المطابقة في:
- `android/app/src/main/AndroidManifest.xml` (بين `<!-- SYNC:PERMISSIONS:START/END -->`)
- `ios/Runner/Info.plist` (بين نفس العلامتين)

يدعم حالياً: `camera`, `microphone`, `speechRecognition`, `textToSpeech`, `location`, `locationAlways`, `photos`, `fileStorage`, `contacts`, `bluetooth`, `pushNotifications`, `localNotifications`. الكتل مُدارة بعلامات sync آمنة — لا تلمس أي إدخال يدوي خارجها، وتُحذف/تُضاف تلقائياً في كل تشغيل حسب الأعلام الحالية. و`speechRecognition`/`textToSpeech` يكتبان أيضاً `<queries>` بأندرويد — بلا إعلانٍ لا يرى التطبيقُ المحرّكَ على أندرويد 11+. والكتلة تأخذ إزاحةَ العلامة بالملف (tabs بـ`Info.plist`)، فتشغيلٌ لم يغيّر إذناً لا يترك فرقاً بـgit — `kit.dart` يناديه مع كل تركيب وإزالة.

---

## 7) `check_structure.dart` — فاحص بنية الواجهة

```bash
dart run scripts/check_structure.dart             # يفشل بمخالفة جديدة
dart run scripts/check_structure.dart --stats     # أرقام بلا فشل
dart run scripts/check_structure.dart --baseline  # يثبّت الدَّين القائم
```

**وُجد لأن قاعدةً بلا فاحص اقتراحٌ لا قاعدة (R30).** وكلُّ ما يفحصه **لا يراه**
`dart analyze` ولا `flutter test`: صفحةٌ بألف سطر تُصرَّف، و`Color(0xFF…)` يُرسم،
ونصٌّ عربيٌّ مكتوبٌ بالكود يظهر — والعطل يصل المستخدم وحده.

### قواعد القدرات `C01…C17`

جدول `_capabilities` بأعلى الفحوص: لكل قدرةٍ بالقالب نمطُ ندائها الخامّ (`DateFormat(` ·
`print(` · `Image.network(` · `SharePlus.instance` …) والمسارات المسموح لها به —
غلافُها وحده. النداء خارجها يُفشل البناء ويسمّي البديل. **الجدول البشريّ المقابل**
[`06_CAPABILITIES.md`](../rules/06_CAPABILITIES.md)، ويُحدَّثان معاً. و`lib/modules/` خارج
الفاحص كلّه كبقية القواعد.

### قواعد الطبقات `L##`

`L01` — `@RestApi` بملفٍّ اسمُه `*_api_service.dart` وحده، لا بملف repository أو
datasource ([`lib/features/CLAUDE.md`](../../lib/features/CLAUDE.md) §Feature Structure).

### الأساس (`.structure_baseline.txt`) — سجلُّ دَينٍ لا زرُّ تجاهل

الأساس يسجّل مخالفاتٍ **أقدم من الفاحص نفسه**. إصلاحُها دفعةً
واحدة refactor واسعٌ يخالف R31، وتجاهلُها يجعل الفاحص عديم المعنى. فالملف
**يُلتزَم بالمستودع**: المسجَّل يُعرَض ولا يُفشِل، وأيُّ مخالفةٍ **جديدة** تُفشِل.

**والمفتاح بلا رقم سطرٍ عمداً** — إضافةُ سطرٍ فوق مخالفةٍ قديمة لا تُفشِل بناءً
أخضر.

⛔ **ولا يُعاد توليدُ الأساس لإسكات مخالفةٍ جديدة.** والحارسُ العمليّ:

```bash
dart run scripts/check_structure.dart --baseline
git diff .structure_baseline.txt        # يجب أن يكون حذفاً صرفاً
```

سطرٌ **مضاف** يعني أنك أسكتَّ مخالفةً جديدة لا أنك حرقتَ دَيناً.

| رمز الخروج | يعني |
|---|---|
| `0` | لا مخالفة جديدة |
| `1` | مخالفةٌ جديدة — تُعرَض بمسارها وسطرها |

---

## 8) `pull_figma.dart` — سحب التصاميم

```bash
dart run scripts/pull_figma.dart --file <URL|KEY>  # يحفظ مفتاح الملف مرّة واحدة
dart run scripts/pull_figma.dart --styles          # الأنماط المنشورة (ألوان + نصوص)
dart run scripts/pull_figma.dart --list            # كل الصفحات وإطاراتها
dart run scripts/pull_figma.dart --name "Login"    # إطارٌ باسمه (بحث جزئي)
dart run scripts/pull_figma.dart --node 1:57       # إطارٌ بمعرّفه
dart run scripts/pull_figma.dart --all             # كل الإطارات العليا
```

لكل إطار **ثلاثة ملفات** بـ`.figma/cache/`:

| الملف | ما هو |
|---|---|
| `<slug>.png` | المشهد مرسوماً (2x) — **ليُرى التصميم لا لتُقرأ إحداثياته** |
| `<slug>.md` | خلاصةٌ مقروءة: الشجرة + hex + المقاسات + النصوص + auto-layout |
| `<slug>.json` | الشجرة مُقلَّمة — للمقارنة الدقيقة عند الحاجة |

**و`--styles` يُشغَّل أوّلاً، مرّةً واحدة للمشروع كلّه**: الأنماط المنشورة هي
نظامُ التصميم كما عرّفه المصمّم؛ واستخراجُ الألوان شاشةً شاشة يُنتج ثلاثَ درجاتٍ
من «الرمادي الفاتح» لا أحد يعرف أيَّها المقصود.

### التوكن

يُقرأ بهذا الترتيب: `FIGMA_TOKEN` بالبيئة، ثم `.figma/token`.

⚠️ **ولا يُمرَّر وسيطَ سطر أوامر** — يبقى بسجلّ الصدفة (shell history).
و`.figma/` كلُّه **مُتجاهَل من git**: توكنٌ يُلتزَم مرّةً يبقى بالتاريخ للأبد
حتى لو حُذف بكوميتٍ لاحق.

**الصلاحية المطلوبة**: `File content = Read-only` — لا شيء غيرها.

> والقواعدُ التي يُبنى بها ما يُسحَب: [`05_FIGMA_TO_PAGE.md`](../rules/05_FIGMA_TO_PAGE.md).

---

## 8‑ب) نمطٌ اختياريّ — فاحصُ عقدٍ يسأل الخادمَ الحيّ

> ⬜ **لا سكربتَ له بالقالب، وبقصد**: أيُّ فاحصٍ كهذا يقرأ **جردَ حقول مشروعك**،
> فنقلُه جاهزاً يعني سكربتاً لا يُصرَّف — وهو بالضبط «سطحٌ لا سلسلة» الذي يمنعه
> R28. ما يُنقل **نمطُه**، ويُكتب حين يكون للمشروع عقدُ حقولٍ يستحقّ الحراسة.

### ما يحرسه، وما لا يحرسه `test/wire_contract_test.dart`

| | ملفُّ التثبيت (`fixtures/`) | فاحصٌ حيّ |
|---|---|---|
| يقارن مقابل | **لقطةٍ كتبناها نحن** | `GET /openapi.json` **الآن** |
| يمسك | تغيُّرَ نموذجنا | **تغيُّرَ الباك** |
| يحتاج شبكة | ❌ | ✅ |

فالأول يقول «النموذجُ ما زال يقرأ ما اتّفقنا عليه»، والثاني يقول «**والاتفاقُ ما
زال قائماً**». والثاني وحده يمسك حقلاً بدّله الباك بصمت.

### ما يفحصه النمط

```
١ · كلُّ حقلٍ بجرد المشروع موجودٌ بجسد نقطة الكتابة
٢ · وموجودٌ كذلك بردّ نقطة القراءة
٣ · وكلُّ حقلٍ أعلنّاه **مفقوداً** ما زال غائباً — فإن ظهر أحدُها فشل عمداً
```

**والثالث هو الأهمّ**: دَينُ الباك يُتابَع آلياً لا بالذاكرة. ويومَ يُضاف حقلٌ
منها يقول السكربت اسمَه ويطلب وصلَه — بدل أن يبقى مُعلَناً «مفقوداً» شهوراً بعد
أن صار موجوداً.

⚠️ **وبلا مقارنة**: حقلٌ مخدومٌ لا يُقرأ يُعرض «لم يُدخل»، وحقلٌ **غير** مخدوم
يُشترط لاكتمال قسمٍ يمنع القسمَ من الصعود إطلاقاً — وكلاهما يمرّ حين تقول
**الوثيقة** شيئاً والخادمُ غيره.

### ورموزُ الخروج ثلاثة لا اثنان

| الرمز | يعني |
|---|---|
| `0` | العقد مطابق |
| `1` | **انحراف** — حقلٌ ناقص أو دَينٌ سُدَّ ولم يُوصَل |
| `2` | **لم يقع الفحص** (لا شبكة · لا توكن · المواصفة لا تُقرأ) |

⛔ **و`2` لا تُقرأ نجاحاً.** فاحصٌ لم يعمل يقول «لا أعرف» لا «سليم»، وخلطُهما
بـCI يجعل انقطاعَ الشبكة يبدو عقداً صحيحاً.

> **و`.github/workflows/ci.yml` يحمل تذكيراً بهذا النمط** —
> تعليقٌ بعد خطوة `Test` يشرح لماذا لا سكربت جاهزاً هنا ويوجّه لإضافة خطوة
> مستقلة عند كتابة الفاحص الفعلي. راجع [`_template/roadmap.md`](https://github.com/mohammeddaeh/project-template-app/blob/master/_template/roadmap.md) بند #05
> لسبب اقتصار التنفيذ على تعليقٍ توجيهي لا كودٍ فعلي.

---

## 8‑ج) `gen_splash_assets.dart` — موردا إقلاع أندرويد

```bash
dart run scripts/gen_splash_assets.dart
```

يقرأ `assets/images/brand/app_logo.svg` (ملفٌّ يُستبدل) ويكتب متجهتين:
`res/drawable/splash_logo_full.xml` (ما دون أندرويد 12) و`splash_icon_v31.xml`
(أندرويد 12+، بلوحةٍ تسع القناع الدائري). ويطبع ثوابتَ المقاس والمرساة.

**ولماذا سكربتٌ لا ملفّاتٌ تُحرَّر:** الطبقاتُ الثلاث (رمزُ أندرويد 12+ · رسمةُ
ما دونه · أوّلُ إطارٍ من فلاتر) يجب أن تضع **نفس النقطة** بمركز الشاشة
و**بنفس المقاس**، وإلا قفز الشعار لحظة التسليم. وأرقامُ ذلك مشتقّةٌ من هندسة
الشعار نفسِه، فتحريرُ ملفٍّ منها يدوياً يفكّ العقد بصمت — `dart analyze` نظيف
والشعارُ يقفز.

⛔ **و`android: false` بـ`flutter_native_splash.yaml`** — بقرار: الأداةُ تمحو
هذين الموردَين وملفّاتِ `styles.xml` الأربعة المحرَّرة باليد. الأسبابُ الخمسة
المقيسة: [`23_STARTUP_SPLASH.md`](../architecture/23_STARTUP_SPLASH.md) §٣.

> **وبدّلتَ الشعار؟** بدّل الـSVG، أعد تشغيل السكربت، وحدّث `splash_background`
> بـ`res/values/colors.xml` ليطابق أرضيةَ أوّلِ شاشةٍ يرسمها فلاتر — واختلافُ
> اللون بينهما **وميضٌ يُرى** لا يمسكه تحليلٌ ولا اختبار.

---

## 8‑د) `new_project.ps1` + `setup_project.dart` — مشروعٌ جديد

### الطريق الموصى به — أمرٌ واحد من أي مجلد (PowerShell)

```powershell
irm https://raw.githubusercontent.com/mohammeddaeh/project-template-app/master/scripts/new_project.ps1 | iex
```

يسأل عن: اسم حزمة Dart (= اسم المجلد) · الاسم الظاهر · Application ID ·
`BASE_URL` لـdev · نمط الوحدات · **مستودع GitHub للرفع** (`owner/name` أو رابط؛
فارغ = بلا رفع). ثم:

1. يفحص `git` و`flutter` و`dart`، ويتوقّف برسالةٍ تسمّي الناقص.
2. **يتحقّق من مستودع الرفع قبل الاستنساخ** — رابطٌ خاطئ يُكتشف بإعادة كتابة، لا
   بعد عشر دقائق من الفحوص:
   - موجود **وفارغ** ⇐ يُقبل. **ولا يُقبل مستودعٌ فيه commits** (ولو README أنشأه
     GitHub): تاريخٌ جديد فوقه يُرفض عند الرفع.
   - غير موجود و`gh` مثبَّت ⇐ يعرض إنشاءه (`private` افتراضياً / `public`).
   - غير موجود بلا `gh` ⇐ يطلب إنشاءه فارغاً على GitHub ثم إعادة إدخاله.
3. `git clone --depth 1` **إلى مجلدٍ مؤقّت بـTEMP**، ثم يَنسخ الملفات **بلا `.git`
   ولا `_template/`** (صيانةُ القالب نفسه — راجع [`../_template/README.md`](https://github.com/mohammeddaeh/project-template-app/blob/master/_template/README.md))
   إلى مجلد المشروع — المشروع يبدأ بتاريخٍ نظيف، ونسخةُ القالب تُحفظ بـ
   `.template_manifest.json` (`templateVersion`).
   > ⚠️ **لا استنساخ في المكان ثم حذف `.git`**: VS Code
   > المفتوح على المجلد الأب يرى المستودع الجديد فيُشغّل `git fetch` فيه خلال ثوانٍ،
   > فيُقفل `FETCH_HEAD` و`tmp_pack_*` ويفشل الحذف — **ثم يمضي السكربت** ويقع أوّل
   > commit فوق تاريخ القالب. ومجلدٌ لم يحمل `.git` قطّ لا يُبقي واحداً. وقبل
   > `git init` حارسٌ أخير: `.git` موجود ⇐ يتوقّف.
4. يُنادي `setup_project.dart` بكل القيم كوسائط (`--yes`) — لا سؤالَ مرّتين.
5. `git init` + أوّل commit **فقط إن نجحت الفحوص**؛ وإلا يُترك بلا commit ويقول ذلك.
6. **يرفع** (`git push -u origin master`، أو `gh repo create … --push`) — وفقط بعد
   commit ناجح. فشلُ الرفع (صلاحية) يترك الـcommit محلّياً ويطبع أمر الإعادة.

> ⚠️ **ومخرَجُ `git`/`npm` على stderr يُطبع نصّاً عادياً** عبر `Invoke-Native`.
> Windows PowerShell 5.1 يعرضه بمضيفاتٍ كـVS Code وISE **أخطاءً حمراء**
> (`NativeCommandError`) حتى مع النجاح — `Cloning into…` وحده يبدو فشلاً. والحكم
> لـ`$LASTEXITCODE` لا للّون. الاستثناء: نمط `custom` يُترك بلا أنبوب، لأن الأنبوب
> يحبس سؤالاً لا ينتهي بسطر جديد. **وأثناء الأنبوب يُضبط `[Console]::OutputEncoding`
> على UTF-8** ثم يُعاد: PowerShell 5.1 يفكّ المخرَج الملتقَط بصفحة OEM، وإلا وصل عربيُّ
> `setup_project.dart` رموزاً (`╪Ñ╪╣╪»…`).
>
> **ومن cmd لا PowerShell**: `irm` غير معروف هناك. نادِه عبر PowerShell:
> `powershell -NoProfile -ExecutionPolicy Bypass -Command "irm <الرابط> | iex"`.

**بلا أسئلة** (لفريقٍ أو CI) — كل وسيط اختياري، والغائب يُسأل عنه:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/mohammeddaeh/project-template-app/master/scripts/new_project.ps1))) `
    -Package inventory_app -Name "Inventory" -AppId com.example.inventory -BaseUrl https://api.example.com -Preset simple `
    -Kits scan,voice -Remote my-org/inventory_app
```

الوسائط: `-Package` · `-Name` · `-AppId` · `-BaseUrl` · `-BaseUrlStaging` ·
`-BaseUrlProd` · `-Preset simple|enterprise|custom` · `-Auth none|required|optional` ·
`-Kits voice,scan,…` (غائبٌ ⇐ يُسأل؛ فارغٌ ⇐ لا شيء) · `-Directory` · `-Remote` ·
`-Source` (مستودعٌ أو مسارٌ محلّي بديل — للتجريب) · `-Branch`.

> **ونظيرُه للباك بنفس المسار** بـ`project-template-backend` — بدّل اسم المستودع
> بالرابط ولا شيء غيره. هناك يسلّم `scripts/setup-project.mjs`.

> ⚠️ **الملف رفيعٌ بقصد، وبـASCII فقط.** كل تعديلٍ على الملفات يعيش بـ
> `setup_project.dart` — تنفيذٌ واحد لا نسختان تنحرفان. وWindows PowerShell 5.1
> يقرأ ملف `.ps1` محلّياً بلا BOM كـANSI فيُفسد أي حرف عربي. ولا `exit` فيه:
> تحت `irm | iex` يُغلق نافذةَ من ناداه.

### يدوياً — بعد استنساخٍ عادي

```bash
dart run scripts/setup_project.dart                      # تفاعلي
dart run scripts/setup_project.dart --name "Inventory" --app-id com.example.inventory \
  --package inventory_app --preset simple --auth none --base-url https://api.example.com --yes
```

يُشغَّل **مرّة واحدة**، فور استنساخ مشروع جديد من هذا القالب (راجع
[`_template/roadmap.md`](https://github.com/mohammeddaeh/project-template-app/blob/master/_template/roadmap.md) بند #01 للسياق الكامل والنقاش). كل وسيطٍ غائب
يُسأل عنه، ووسيطٌ مجهول يُفشل بدل أن يُتجاهَل:

1. **الهوية**: اسم التطبيق + Application ID أساسي واحد + **اسم حزمة Dart**
   (الافتراضي: آخر مقطع من Application ID).
1‑ب. **وضع الدخول** (`--auth`): `none` بلا دخول (الافتراضي مع `--yes`) · `required`
   الدخول إلزاميّ · `optional` زائرٌ والدخول من تبويب الحساب ⇐ `AppFeatures.authMode`
   و`authMode` بالبيان. وبـ`new_project.ps1` الوسيط `-Auth`. المعنى كاملاً بـ
   [`23_STARTUP_SPLASH.md`](../architecture/23_STARTUP_SPLASH.md) §٤‑ب.
1‑ج. **حِزَم الأجهزة** (`--kits voice,scan`): ما يبقى مركَّباً، والباقي يُزال بـ`kit.dart remove`
   — **الافتراضي لا شيء** (ومع `--yes`). مجلداتُها تبقى بـ`packages/` فتُركَّب لاحقاً
   بأمرٍ واحد — [`24_DEVICE_KITS.md`](../modules/24_DEVICE_KITS.md).
2. **الوحدات الاختيارية ذات الكلفة الخارجية فقط** — `accessControl` ·
   `dataTransfer` · `offlineSync` · `multiDevice` · `inAppUpdates` ·
   `crashReporting` · `analytics` · `remoteConfig` — عبر نمط جاهز (بسيط/مؤسسي)
   أو سؤال فردي (مخصّص). **باقي الأعلام لا يُسأل عنها عمداً** — بلا كلفة خارجية،
   فتُترك على الافتراضي وتُفعَّل لحظة الحاجة الفعلية بالكود.
3. يكتب: `flavor_settings.json` · `android/app/build.gradle.kts`
   (`namespace`+`applicationId`) · **`MainActivity.kt` منقولاً لحزمة
   `applicationId`** · `ios/Runner.xcodeproj/project.pbxproj` ·
   `ios/Runner/Info.plist` · `pubspec.yaml` (`name` + الوصف) · أعلام
   `app_features.dart` · و`package:app_template/` → `package:<اسمك>/` بكل ملف
   نصّي تحت `lib/` · `test/` · `scripts/` · `readme/` و`CLAUDE.md`.
4. يشغّل `sync_flavors.dart` تلقائياً لتوليد الملفات المشتقّة (strings.xml لكل
   flavor، launch.json، أيقونات، **و`.env.*.json`**) من الهوية الجديدة، ثم يكتب
   `BASE_URL` بملفات البيئة المُعطاة.
5. يكتب `.template_manifest.json` — كل قرار وسببه، ونسخة القالب (`git rev-parse
   --short HEAD`) وقت الإنشاء.
6. يطبع تذكيراً واحداً لكل خيار اختير `نعم` وله كلفة تجهيز خارجية (Firebase،
   تنسيق مع الباك...).
7. يُشغِّل تلقائياً: `flutter pub get` → `dart analyze lib` → `flutter test` →
   `check_structure.dart`، ويقول صراحةً إن فشل أيٌّ منها بدل الصمت. **بلا ضجيج**:
   مخرَجُ `pub get` (قائمةُ ~١٦٦ حزمةً قديمة) يُطبع عند الفشل فقط، و`flutter test`
   بـ`--reporter failures-only` — وإلا طبع خارج الطرفيّة سطراً لكل اختبار (~٤٠٠)
   فدُفن الفشلُ بينها.

**قاعدة صارمة يتّبعها**: لا يحذف كوداً ولا تبعيةً أبداً — يبدّل قيماً فقط. كل
قرار قابل للتراجع بسطر واحد لاحقاً، بحكم أن كل موديول أصلاً بلا كلفة عند
إطفائه.

**وثلاثة أعطالٍ يحرسها** — كلّها خضراء بالتحليل:

| ما يحرسه | لماذا لا يُرى بغيره |
|---|---|
| `_replaceOrDie` يطابق نهاية السطر بالملف — وإلا توقّف على ويندوز عند `build.gradle.kts` | الاستنساخ هناك يُخرج الملفات CRLF، والأنماط مكتوبة بـ`\n` |
| `MainActivity.kt` يُنقل لحزمة `applicationId` — وإلا **انهار التطبيق عند أوّل إقلاع** | الـmanifest يسمّي `.MainActivity` نسبياً إلى `namespace`. التحليل والاختبارات لا تُقلع التطبيق |
| `scripts/` ضمن استبدال اسم الحزمة — وإلا ولّد `scaffold_feature` شرائح لا تُصرَّف | يكتب `package:app_template/` حرفياً |

⛔ **خارج نطاقه عمداً** (وليس سهواً): إعادة توليد لوحة الألوان الكاملة من لون
واحد — التدرّج اليوم يدويّ مدروس، ولا أداة تُنتج تدرّجاً موثوقاً من قيمة واحدة.
يبقى خطوة يدوية موثَّقة بـ[`01_SETUP.md`](../start/01_SETUP.md).

---

## 8‑هـ) `scaffold_feature.dart` — مولّد شريحة CRUD

```bash
dart run scripts/scaffold_feature.dart <feature_name>
# مثال:
dart run scripts/scaffold_feature.dart invoices
```

يبني شريحة CRUD كاملة تحت `lib/features/<feature_name>/` بكل الطبقات
الموصوفة بـ[`lib/features/CLAUDE.md`](../../lib/features/CLAUDE.md) §CRUD-PATTERNS
و[`lib/core/CLAUDE.md`](../../lib/core/CLAUDE.md) §API-GENERATOR — بحقلٍ تجريبي
واحد (`title`) **يُصرَّف ويعمل فوراً**، لا حقولاً مخمَّنة لمشروعك.

**ما يكتبه:**
- ١٨ ملفاً: `domain/{entities,repositories,params,usecases}` ·
  `data/{dtos,models,datasources,repositories}` ·
  `presentation/{cubits,widgets,pages}`.
- يصل الملفات المشتركة تلقائياً: سطر جديد بـ`api_urls.dart` ·
  `injection_module.dart` (ApiService) · مساران بـ`router.dart` (قائمة
  ونموذج) · ٥ مفاتيح ترجمة بـ`ar.json`/`en.json` (مُرتَّبة أبجدياً بعد الإضافة).
- يشغّل `dart run scripts/gen_code.dart` تلقائياً (لازم هنا — على خلاف
  `setup_project.dart` — لأن هذا يمسّ DI وrouter وfreezed وترجمة معاً).
- فحص صحة نهائي: `dart analyze lib` → `flutter test` → `check_structure.dart`.

**افتراض العقد الافتراضي**: صفحة الباك تحت `data.{items, page, limit, total,
total_pages}` (نفس شكل `test/wire_contract_test.dart`). طابِقه مع باكك الفعلي
بـ`{feature}_remote_datasource.dart` إن اختلف.

⛔ **لا اختبارات مولَّدة** — قرارٌ لا سهو: اختبار CRUD حقيقي يحتاج حقولاً
حقيقية لا `title` تجريبياً. أضفها بـ`test/features/<feature>/` بعد تعديل
الحقول، بالاستعانة بأمثلة `auth/`.

### ربط سلسلة العقد تلقائياً

يقرأ `AppFeatures` مباشرةً من `app_features.dart` — **بلا سؤالٍ تفاعلي**، فمشروعٌ
لم يُشعل هذين العلَمين لا يرى فرقاً ولا ملفاً إضافياً واحداً:

| العلَم | ما يُضاف |
|---|---|
| `offlineSync == true` | أربعة ملفات `data/sync/`: عقد الفيتشر (`SyncFeatureContract<Entity>` بـ`toJson/fromJson/localIdOf`) · منفّذ دفعٍ (يعيد استعمال `HandleBodyResponse` نفسه، فمعالجة الخطأ — بما فيها 409 ⇐ `ConflictFailure` — موحَّدة لا مكرَّرة) · ديكور تسجيل (§3d) · `SyncAware<Feature>Repository`. **الكتابة توليدٌ آمنٌ كامل** (تُصفّ بلا اتصال فعلاً)، **والقراءة عبورٌ شبكي عمداً** (`TODO` صريح داخل الملف) — توليد قراءةٍ محلّية-أولاً بلا شريحةٍ حيّةٍ يُقتدى بها يعني مئات الأسطر غير المُتحقَّقة، وهو بالضبط الخطأ الذي يحذّر منه [`lib/modules/sync/STATUS.md`](../../lib/modules/sync/STATUS.md) (توثيقٌ يدّعي اكتمالاً لم يُختبَر) |
| `accessControl == true` | زرّ الإضافة بالقائمة يُغلَّف بـ`Can(permission: PermKeys.<feature>Create, ...)`. **يكسر البناء عمداً** حتى يُعلن الباك المفتاح فعلياً ويُعاد `gen_permission_keys.dart` — لا تخمين صامت لاسم مفتاحٍ قد يخالف ما يفرضه الباك فعلاً |

⚠️ **فشل `dart analyze` بعد التوليد مع `accessControl == true` متوقَّعٌ ومقصود**
(`PermKeys.<feature>Create` لا وجود لها بعد) — السكربت يطبع رسالةً توضّح ذلك
صراحةً بدل تركه يبدو عطلاً بالأداة نفسها.

**والمتوقَّع بكلا العلَمين مُشعَلين**: فشلٌ واحدٌ دقيق (`PermKeys.invoicesCreate`
غير موجودة) قبل إضافة المفتاح، ثم بعد إضافته لـ`permissions.lock.json` وإعادة
`gen_permission_keys.dart`: `dart analyze` نظيف · الاختبارات كلها ناجحة · صفر
مخالفة `check_structure` جديدة · `dart format --set-exit-if-changed` بلا تغيير
(السكربت يُشغّل `dart format` على مجلّد الشريحة تلقائياً).

---

## 8‑و) `audit_template.dart` — تدقيق ذاتي للقالب

```bash
dart run scripts/audit_template.dart
```

**تشخيصيٌّ استشاريّ، لا فاحص CI حاجب** (خلافاً لـ`check_structure.dart`):
يُشغِّل آلياً ما يجري يدوياً بتدقيقٍ كامل للقالب — راجع
[`_template/roadmap.md`](https://github.com/mohammeddaeh/project-template-app/blob/master/_template/roadmap.md) بند #04.

**خمسة فحوص:**
1. **وصل الموديولات بإقلاعها** — لكل مجلَّد بـ`lib/modules/`، هل ملفّ
   `*_plugin.dart`/`*_module.dart` مستورَدٌ فعلاً بـ`modules_bootstrap.dart`؟
2. **الفجوة الحرجة** — `AppFeatures.offlineSync == true` مع صفر تنفيذ لـ
   `SyncFeatureContractBase`. **الفحص الوحيد المؤثّر بكود الخروج**: صفرُ زيفٍ
   إيجابيٍّ ممكنٍ فيه.
3. **مسارات بلا نقطة تنقّل ظاهرة** — كل `@RoutePage()` يُشتقّ اسمُ مساره
   (نمط auto_route الافتراضي: إسقاط لاحقة `Screen`/`Page` وإلحاق `Route`، أو
   الاسم الصريح إن وُجد)، ثم يُبحث عن أي استخدامٍ آخر له بـ`lib/` غير تسجيله
   بـ`router.dart`.
4. **ملفات `readme/` خارج جدول التزامن** — كل ملفٍّ بجذر `readme/` (لا
   `_template/archive/`) يجب أن يُذكر بجدول «Mandatory Documentation Sync» بـ`CLAUDE.md`.
5. **تاريخٌ بالملفات التي تصل المشاريع** (R38) — تاريخ `YYYY-MM-DD` (لا طابعٌ زمنيّ
   كامل `…T08:00:00Z` بمثال JSON) أو اسمُ مشروعٍ
   معروف (من `_template/project_names.txt` — بمستودع القالب وحده، فمشروعٌ مبنيّ يُفحص تاريخُه فقط) بـ`readme/` و`lib/` و`scripts/` و`CLAUDE.md`؛ بالكود
   التعليقاتُ وحدها، و`test/` خارجه (التواريخ هناك بيانات). اسمُ المشروع الحاليّ
   من `.template_manifest.json` يُستثنى. `--verbose` يطبع الأسطر.

⚠️ **الفحصان ٣ و٤ فحصٌ نصّيّ لا تحليلاً دلالياً** — عرضةٌ لزيفٍ إيجابي: مسارٌ
يُركَّب كودجة مباشرة بدل `context.router.push` لن يظهر له استخدام رغم كونه
مستهلَكاً فعلاً (مثاله: `SettingsRoute`). **النتيجة
مرشَّحٌ للمراجعة، لا حكمٌ قاطع** — راجع دائماً
[`10_ARCHITECTURE.md`](../architecture/10_ARCHITECTURE.md) §«جرد المبنيّ بلا مستهلك» قبل
اتخاذ أي إجراء بناءً عليه.

**على القالب نفسه** يكشف الفحص ٣ `UserAccessRoute` — المسار اليتيم المُوثَّق بقصد
بـ`10_ARCHITECTURE.md`.

---

## 8‑ز) `scaffold_module.dart` — مولّد موديول اختياري جديد

```bash
dart run scripts/scaffold_module.dart <module_name>
# مثال:
dart run scripts/scaffold_module.dart audit_log
```

يكتب الأركان الثلاثة معاً لأي موديول تحت `lib/modules/` — ركنٌ يُنسى يترك موديولاً
كامل الكود لا يُقلع، والتوليد الآلي لا يترك خياراً بتخطّي ركن:

1. **ملفّ المدخل** `lib/modules/<name>/<name>_plugin.dart` — نمط الحراسة
   نفسُه بكل موديول قائم (`if (!AppFeatures.x) return;` ثم تسجيل، `LogService`
   بكل خطوة، `reset()` للاختبارات).
2. **العلَم** — سطرٌ جديد بـ`app_features.dart` تحت "Optional modules"،
   افتراضُه `false`.
3. **التسجيل** — سطرٌ جديد بـ`modules_bootstrap.dart` (`if (AppFeatures.x)
   await XPlugin.initialize(di);`) فوق علامة `// scaffold_module:` الثابتة.
4. **صفّ الجدول الواحد** — بـ[`30_MODULES.md`](../modules/30_MODULES.md) فوق علامته. الوصفُ وما
   يحتاجه خارج التطبيق يبقيان `TODO` — يدويّان بقصد، لا شيء يعرفهما قبل كتابة الموديول.

لا يمسّ DI/router/freezed/ترجمة، فلا حاجة لـ`gen_code.dart` — فقط فحص صحة
نهائي: `dart analyze lib` → `flutter test` → `check_structure.dart`.

⛔ **لا محتوى فعلي مولَّد** — قرارٌ لا سهو: كل موديول يفعل شيئاً مختلفاً كلياً
(Firebase، قاعدة محلية، REST...)، فما يُكتب هو **الهيكل الحارس** وحده —
تسجيلات DI الفعلية تعليقٌ `TODO` واحد بانتظارك.

**والمولَّد يمرّ من أول تشغيل بلا إصلاح**: `dart analyze` نظيف، الاختبارات
ناجحة، صفر مخالفة `check_structure` جديدة.

---

## 8‑ح) `check_docs.dart` — روابط التوثيق

```bash
dart run scripts/check_docs.dart
```

يمرّ على كل `.md` بالمستودع (لا `build/` ولا `.dart_tool/`)، ويفشل (`exit 1`) على
أي رابطٍ نسبيّ لا يصل ملفاً أو مجلداً. ورابطُ GitHub الكامل إلى `_template/`
يُفحص محلياً حين يوجد المجلد — بمستودع القالب وحده.

**لا يُفحص:** روابط الويب الأخرى (تحتاج شبكة) · المراسي `#…` · ما داخل كتل الكود.

**لماذا حاجب:** رابطٌ معطوب لا يراه `dart analyze` ولا الاختبارات، ويبقى حتى يضغطه
من يتعلّم القالب. ونقلُ ملفٍّ أو حذفُه هو ما يكسر الروابط عادةً — فيُشغَّل بعد كل نقل.

---

## 8‑ط) `template_drift.dart` + `template_update.dart` — القالب والمشروع بعد الإنشاء

كلاهما يُشغَّل **داخل المشروع**، ويقرأ `templateVersion` (commit القالب الذي بدأ منه)
من `.template_manifest.json`. والقالب يُقرأ من مستنسخٍ محلّي (`--template ../app_template`)
أو يُستنسخ مؤقّتاً من GitHub. **وما يملكه القالب** قائمةُ `templateOwned` بـ
`scripts/src/template_repo.dart`: `lib/core/` · `lib/ui/` · `lib/modules/` · `packages/` ·
`scripts/` · **`test/` بملفات القالب وحدها** · `readme/` · `.claude/skills/` · ملفات `CLAUDE.md` ·
`analysis_options.yaml` · CI · `loadtest/` · `TEMPLATE_VERSION`. وما سواها ملكُ المشروع
(`lib/features/` · `lib/main.dart` · `pubspec.yaml` · `assets/` …). واختبارٌ كتبه المشروع
لا يمسّه تحديث، لأن القائمة تُطبَّق على شجرة القالب.

**`projectEdited`** — ملفاتٌ يملكها القالب **ويُنتظر** أن يعدّلها كل مشروع (`api_urls.dart` ·
`injection_module.dart` · `app_fonts.dart` · `app_colors.dart` ·
`modules_bootstrap.dart`): تعديلُها ليس ملاحظة، وتحديثُها يُراجَع دائماً.

### `template_drift.dart` — ما يعود إلى القالب

```bash
dart run scripts/template_drift.dart [--template DIR] [--write] [--strict] [--base COMMIT]
```

| يعرض | المعنى |
|---|---|
| معدَّل | ملفٌّ من القالب غيّره المشروع — وعددُ الأسطر `+أ −ح` |
| مضاف | ملفٌّ جديد بـ`lib/core/` · `lib/ui/` · `lib/modules/` · `packages/` · `scripts/` — قدرةٌ عامّة على الأرجح |
| محذوف | ملفٌّ من القالب أزاله المشروع |
| متوقَّع | `projectEdited` — يُعرض ولا يُعدّ |

✓ **مسجَّل** حين يُذكر مسارُه بـ`docs/TEMPLATE_FEEDBACK.md`، و◌ غير مسجَّل. `--write`
يضيف مسوّدةً لكل ◌ إلى ذلك الملف؛ `--strict` يخرج بـ`1` إن بقي ◌ (لـCI المشروع).
واسمُ الحزمة الذي بدّله `setup_project.dart` ونهاياتُ الأسطر لا تُعدّ تغييراً.

### `template_update.dart` — ما يأتي من القالب

```bash
dart run scripts/template_update.dart [--template DIR] [--base COMMIT] [--to REF] [--apply]
```

ثلاث نسخٍ لكل ملفٍّ مملوك: القالب حين بدأ المشروع (أو `--base`) · القالب عند `--to`
(افتراضاً `origin/master`) · المشروع. و`--to` لا يُعرف ⇐ يتوقّف، لا يسقط إلى `HEAD`.

| الحالة | مع `--apply` |
|---|---|
| القالب غيّره والمشروع لم يلمسه | يُحدَّث · يُضاف · يُحذف |
| المشروع غيّره والقالب لم يغيّره | لا شيء |
| **كلاهما غيّره** · أو `projectEdited` | **تعارض**: نسخة القالب بـ`.template_update/<المسار>`، والملف لا يُلمس — ادمجه يدوياً ثم احذف المجلد |
| المشروع حذفه | لا شيء |

**ومفاتيحُ الترجمة** (`assets/translations/*.json` — ملكُ المشروع) تُقارَن مفتاحاً مفتاحاً بنفس
النسخ الثلاث (`scripts/src/translation_merge.dart`): الجديدُ يُضاف بجوار جاره بالقالب · قيمةٌ
لم يلمسها المشروع تُحدَّث · قيمةٌ غيّرها الطرفان تبقى للمشروع، وقيمةُ القالب بـ
`.template_update/assets/translations/<اللغة>.json` · مفتاحٌ حذفه القالب يبقى. فكودُ القالب
الجديد لا يقع على `LocaleKeys` ناقص.

**بلا `--apply` يعرض ولا يكتب.** ومع `--apply` يرفض شجرة git غير نظيفة — فالتحديث
commitٌ واحد يُراجَع — ويكتب الـcommit الجديد بالبيان. ثم `gen_code.dart` و`analyze`
و`flutter test`.

**وما يملكه المشروع ولا يلمسه التحديث** (`main.dart` · `app.dart` · `features/` · `pubspec.yaml` ·
`app_features.dart` · `android/`) — ما يُنقل منه باليد لكل إصدار بـ
[`41_UPGRADING.md`](41_UPGRADING.md).

### الحلقة كاملة

```
المشروع: تحسينٌ بملف القالب ⇐ بندٌ بـdocs/TEMPLATE_FEEDBACK.md (template_drift يذكّر)
   ⇓ نهاية مرحلة
القالب: _template/feedback/<المشروع>.md ⇐ skill apply-feedback ⇐ commit لكل بند ⇐ إصدار
   ⇓
المشروع (وكل مشروع): template_update.dart --apply
```

---

## 8‑ي) `prune_project.dart` — تنظيف ما لا يستعمله أحد

```bash
dart run scripts/prune_project.dart            # تقريرٌ فقط
dart run scripts/prune_project.dart --apply    # يحذف المفاتيح والأصول — شجرة git نظيفة
```

| الصنف | يُكتشف حين | مع `--apply` |
|---|---|---|
| مفتاح ترجمة | لا `LocaleKeys.<اسمه>` ولا نصُّه حرفياً بـ`lib/` | يُحذف من كل `assets/translations/*.json` |
| أصل | لا مسارُه ولا getterه بـ`lib/`، ولا مسارُه بـ`scripts/` ولا YAML الجذر (`flutter_native_splash.yaml` …) ولا موارد أندرويد/iOS | يُحذف الملف |
| موديول | علَمه بـ`AppFeatures` مطفأ | يُعرض — الحذف بخطوات `SETUP.md` كل موديول |
| ملف Dart | لا يستورده أحد ولا هو مدخل | يُعرض — قد يكون سطحاً ينتظر بقصد (جرد `10_ARCHITECTURE.md`) |
| حزمة | لا `import` لها | يُعرض — إضافاتُ المنصّة وأدوات التوليد بلا import |

**`.prune_keep`** بجذر المشروع يحمي ما لا يراه الفحص — سطرٌ لكل مفتاح أو مسار أو حزمة
(يقبل `*`). **والمثال الأهمّ مفتاحٌ يرسله الخادم** (`messageKey`): لا يظهر بالكود
أبداً، فيبدو مهجوراً وليس كذلك. وبعد `--apply`: `gen_code.dart` ثم `analyze` و`test`.

---

## 8‑ك) `port_inventory.dart` + `device_shot.dart` — نقلُ تطبيقٍ قائم

يُستعملان مع skill `port-to-template` (`.claude/skills/port-to-template/SKILL.md`)، الذي
يكتب `docs/PORT_PLAN.md` بعد الجرد.

```bash
dart run scripts/port_inventory.dart ../old_app      # ⇐ docs/port/inventory.md
dart run scripts/device_shot.dart home --ref docs/port/reference/home.png
```

**`port_inventory`** يجرد ولا يجتهد: المنصّة (Capacitor · React · Flutter · أندرويد · iOS) ·
**هويّة المتجر** (معرّف الحزمة · رقم البناء · إعداد التوقيع ومسارُ المفتاح، لا محتواه — ما يجب أن
يبقى ليصل التحديث) · **الأذونات** (`AndroidManifest.xml` · `Info.plist` ⇐ علَمُها بـ`AppFeatures`) · الشاشات · الـendpoints **بالـmethod** (`GET /orders` — من نداءٍ باسمه أو تعليقة Retrofit أو
`fetch`، و`?` حين لا يظهر؛ والروابط الكاملة التي ليست API — موقعٌ يُفتح، صفحةُ المتجر، عنوانُ الخادم — بقائمةٍ
منفصلة بأصلها وحده) · ملفات الترجمة · الخطوط **بوزنها من الملف** · SVG بـ`<style>` ·
وإشاراتٍ مربوطةً بما يقابلها: قسمٌ بـ`06_CAPABILITIES.md`، أو kit تُركَّب بـ
`scripts/kit.dart add <name>`، أو موديولٌ بـ`lib/modules/`. والإشارات تُطابَق على الكود
**وملفات الاعتماديات** (`package.json` · `pubspec.yaml` · `build.gradle` · `Podfile` ·
`AndroidManifest.xml` · `Info.plist`) والأنماط — فاسمُ حزمةٍ وحده يكفي. ويتجاوز ناتج
البناء (حزمٌ مضغوطة · نسخة الويب داخل أندرويد/iOS · `build-*` · كودٌ مولَّد) فلا يعدّ
الشيء مرّتين.

**جدول الإشارات بـ`scripts/src/port_signals.dart`** — وكلُّ قدرةٍ تُضاف إلى الكتالوج أو
kit أو موديول تحتاج إشارةً فيه، أو استثناءً بسببه. `test/port_signals_test.dart` يُفشل
الناقص، ويتحقّق أن كلَّ إشارةٍ تُلتقط فعلاً من مشروعٍ قديم وهمي بـ
`test/fixtures/port/old_app/` — فإشارةٌ جديدة تحتاج سطراً هناك يطابقها.

**`device_shot`** يلتقط الشاشة (`adb screencap`) ونصوصها (`uiautomator dump`) إلى
`docs/port/shots/`، ومع `--ref` صفحة HTML باللقطتين متجاورتين. ويطبع **العرض المنطقيّ**:
هاتفان بعرضين مختلفين يجعلان فرق الحجم وحده بلا معنى. ⚠️ اللقطة تحمل ما على الشاشة —
افتح التطبيق على الشاشة المطلوبة قبل التشغيل، وتفريغُ الشاشة يُحذف من الجهاز بعد قراءته.

---

## 9) Troubleshooting

| Issue | Fix |
|-------|-----|
| `*.g.dart` / `*.freezed.dart` errors | Run `dart run build_runner build --delete-conflicting-outputs` (أو `dart run scripts/gen_code.dart`) |
| Routes not found after `@RoutePage` change | Run `gen_code.dart` |
| iOS build fails after flavors change | `flutter clean` + `cd ios && pod install` |
| DI registration errors | Run `gen_code.dart`, تحقق من `injection.config.dart` |
| Localization key shows as raw string at runtime | شغّل `gen_code.dart` كاملاً (يشمل locale_keys.g.dart + codegen_loader.g.dart) |
| `.tr()` text doesn't update on locale switch | أضف `context.locale;` في أعلى `build()` / `BlocBuilder.builder` |
| `injection.config.dart` hash collision (DI fails) | أعد تسمية alias المكرر يدوياً (مثال: `_i693` → `_i6931`) في الملف المولَّد |
| APK غير موجود بعد `build_apk.dart` | تحقق من وجود `.env.{flavor}.json` بجذر المشروع قبل البناء |
| `.env.{flavor}.json` مفقود بعد استنساخ المشروع | طبيعي — مُتجاهَل في git. شغّل `dart run scripts/sync_flavors.dart` فيُنشئها، ثم ضع الروابط الحقيقية |
| `Env.baseUrl` فارغ رغم وجود ملف البيئة | شغّل عبر `--dart-define-from-file=.env.{flavor}.json`، أو من VSCode بإعداد الـflavor المولَّد — `flutter run` المجرَّد لا يقرأ الملف |

## 10) Script Usage Rules

- استخدم السكربتات بدل التعديل اليدوي للإعدادات كلما أمكن.
- أعد تشغيل `gen_code.dart` بعد أي تغيير يمس DI/router/API/الترجمة.
- حدّث هذا الملف عند إضافة أو تعديل أي سكربت في `scripts/`.

## 11) Related Docs

- [`00_START_HERE.md`](../start/00_START_HERE.md) — onboarding + full structure
- [`11_CORE.md`](../architecture/11_CORE.md) — architecture principles
- [`12_REST_API.md`](../architecture/12_REST_API.md) — REST workflow

