# 01 — الإعداد

> المرحلتان 1 و2 من [`00_START_HERE.md`](00_START_HERE.md) بتفصيلهما ومزالقهما.
> **يُحدَّث** عند تغيير خطوات الإعداد أو ملفات الهوية.

---

## المتطلّبات

| الأداة | النسخة |
|---|---|
| Flutter SDK | يطابق `environment.sdk: ^3.8.1` بـ`pubspec.yaml` |
| Dart | يصل مع Flutter |
| Android Studio / Xcode | حسب المنصّة المستهدفة |
| CocoaPods | لبناء iOS (macOS فقط) |

```bash
flutter --version
flutter doctor
```

---

## 1) التبعيات وملفات البيئة

```bash
flutter pub get
dart run scripts/sync_flavors.dart
```

`sync_flavors.dart` يفعل ستّة أشياء:

1. يُنشئ الناقص من `.env.{dev,staging,prod}.json` انطلاقاً من `.env.example.json`
2. يحقن `productFlavors` و`applicationId` بـ`android/app/build.gradle.kts`
3. يكتب اسم التطبيق بـ`android/app/src/{flavor}/res/values/strings.xml`
4. يولّد `flutter_launcher_icons-{flavor}.yaml`
5. يشغّل `flutter_launcher_icons` لكل flavor
6. يكتب `.vscode/launch.json` بإعداد تشغيل لكل flavor

### ⚠️ ملفات البيئة لا تصل مع الاستنساخ

`.env.dev.json` وأخواتها **مُتجاهَلة في `.gitignore`** لأنها تحمل روابط API حقيقية.
من يستنسخ المستودع لا تصله، و`--dart-define-from-file` ينكسر عند أول تشغيل. لهذا
يضمنها السكربت بكل تشغيل:

| الحالة | ما يفعله |
|---|---|
| غير موجود | يُنشئه بكل مفاتيح `.env.example.json` — `🆕` |
| ينقصه مفتاح أضافه القالب لاحقاً | يضيف الناقص فقط — `➕` |
| كامل وما زال يحمل قيمة المثال | تحذير `⚠️` — **القيمة لا تُلمس** |
| معبَّأ | `🔐 ok` |
| JSON تالف | `❌` ويُترك — يُصلَح يدوياً |

**القيمة الموجودة لا تُعدَّل أبداً** — التشغيل المتكرر آمن.

**مفتاحٌ إلزاميّ واحد** — يقرؤه `lib/core/infra/config/env.dart`، **ويُخفق
الإقلاع إن نقص**:

```jsonc
// .env.dev.json
{
  "BASE_URL": "https://api.your-real-server.com"
}
```

> ### ⚠️ ولماذا يُخفق الإقلاع بدل أن يُخفق الطلب
>
> مفتاحٌ ناقص لا يُخفق شيئاً من تلقائه: `String.fromEnvironment` يردّ `''`،
> فيُبنى الطلبُ ويُرسَل ويُردَّ عليه — بنجاحٍ بروتوكوليٍّ تامّ، أو بخطأٍ
> **يتحدّث عن شيءٍ آخر**. فيُرسَل من يبحث إلى الخادم وإلى بيانات المستخدم، لا
> إلى السطر الناقص بملفّ البيئة.
>
> ولا شيء بالمسار يكشفه: `dart analyze` نظيف، والاختباراتُ تمرّ (تحقن قيَمَها
> بنفسها)، والسجلُّ يطبع `baseUrl=` فارغاً بسطرٍ لا يقرؤه أحد.
>
> فصار `Env.init()` **يُخفق قبل أول طلب** برسالةٍ تسمّي الملفَّ والمفتاح.
> **وكلُّ مفتاحٍ تضيفه بلا `defaultValue` يُضاف إلى `Env._required`** — وإلا
> عاد غيابُه `''` يمضي بصمت.
>
> **وأعد التشغيل تشغيلاً كاملاً بعد أي تعديل على الملف**:
> `--dart-define-from-file` تُقرأ وقت البناء، وhot reload لا يلتقطها.

> **أضف كل مفتاح بيئة جديد إلى `.env.example.json`** (المرفوع في git) — وإلا لن يصل
> مَن يستنسخ المشروع. **والقيمةُ السرّية تبقى فارغة هناك**: الملف مرفوع، وسرٌّ
> يُلتزَم مرّةً يبقى بالسجلّ ولا يمحوه حذفُه بـcommit لاحق.
### 🔑 حارسُ أصل البيانات — `DataOriginGuard`

**بُدّل `BASE_URL` وأُعيد التشغيل، فعرض التطبيق بيانات الخادم القديم.** ولا
انهيار ولا شاشة خطأ: ما خُزِّن محلّياً بقي كما هو، وكلُّ قارئٍ يقرأ منه ولا
يسأل الشبكة.

وأخطرُ من العرض **التوكن**: توكنٌ يحمل مُصدِرَه، وخادمٌ آخر يرفضه — فترتدّ
الشاشات ٤٠١ واحدةً واحدة، ولا واحدة منها تقول السبب.

فصار قرارُ أوّل شاشة يسأل **قبل أن يقرأ التوكن**: هل أصلُ ما على هذا الجهاز هو
`Env.baseUrl` الحالي؟ وإن خالفه:

| يُمحى | لماذا |
|---|---|
| الجلسة (توكن + تحديث) | توكنُ مصدرٍ آخر لا يصلح لهذا |
| كلُّ بيانات الحساب | صفوفُ خادمٍ آخر، ولقطاتُه، ومسوّداتُه المؤقّتة |

ثم يُكتب الأصل الجديد، ويعود التطبيق إلى شاشة الدخول بجهازٍ نظيف.

> ⚠️ **وشغلٌ محلّيٌّ لم يُرفع يضيع بذلك — وهو مقصود**: مسوّدةٌ كُتبت مقابل
> خادمٍ آخر لا مكان لها هنا، ورفعُها يُنشئ سجلاً بمكانٍ خاطئ. وضياعُ إدخالٍ
> يُعاد أهونُ من رفعٍ يقع بالمكان الغلط.
>
> **ولا يقع إلا حين يتبدّل الأصل فعلاً**: إعادةُ تشغيلٍ عادية تقرأ نفسَ الأصل
> فتمرّ بلا مسح، والفحص قراءةُ مفتاحٍ واحد.

> 📍 **وموضعُه `StartupResolver`** — يُنادى من `main()` **قبل `runApp`**، فلا
> يرى المستخدم شاشةً مبنيّةً على بياناتٍ ستُمحى بعد لحظة.
> راجع [`23_STARTUP_SPLASH.md`](23_STARTUP_SPLASH.md).
## 2) التوليد والتشغيل

```bash
dart run scripts/gen_code.dart
flutter run --flavor dev --dart-define-from-file=.env.dev.json
```

أو من VSCode: اختر إعداد الـflavor من `launch.json` المولَّد.

### ⚠️ المزلق الأول

```bash
flutter run                 # ❌ Env.baseUrl فارغ — كل طلب يفشل بلا سبب ظاهر
```

`flutter run` المجرَّد لا يقرأ ملف البيئة. الأعراض: شاشة الدخول تفتح، وكل محاولة
تفشل برسالة عامّة، ولا شيء بالسجلّ يقول «الرابط فارغ».

---

## 3) اجعله مشروعك

القالب يصل باسم `app_template` وهوية `com.example.app_template`.

> ★ **أسرع طريق للهوية**: `dart run scripts/setup_project.dart` — يسأل عن اسم
> التطبيق وApplication ID تفاعلياً، ويكتب كل ما يصفه §الهوية أدناه دفعة واحدة
> (بما فيها iOS)، ثم يشغّل `sync_flavors.dart` والفحوصات النهائية تلقائياً.
> راجع [`40_SCRIPTS.md`](40_SCRIPTS.md) §8‑د. **الفقرات أدناه تشرح ما يفعله
> يدوياً** — لمن يفضّل التحكّم اليدوي أو يريد فهم الآلية.

### الهوية

```jsonc
// flavor_settings.json
{
  "flavors": {
    "dev":     { "displayName": "مشروعي DEV",     "applicationId": "com.company.myapp.dev",     "showVersion": true  },
    "staging": { "displayName": "مشروعي STAGING", "applicationId": "com.company.myapp.staging", "showVersion": true  },
    "prod":    { "displayName": "مشروعي",          "applicationId": "com.company.myapp",         "showVersion": false }
  }
}
```

`applicationId` يُضبط أيضاً بـ`android/app/build.gradle.kts`.

### الأيقونات

ضع PNG **مربّعة 1024×1024** في:

```
assets/app_icons/icon_dev.png
assets/app_icons/icon_staging.png
assets/app_icons/icon_prod.png
```

ثم:

```bash
dart run scripts/sync_flavors.dart
flutter clean && flutter pub get
cd ios && pod install          # macOS فقط
```

### الألوان والخطوط

| ما تغيّره | كيف |
|---|---|
| الألوان | `lib/ui/theme/app_palette.dart` (خام) ثم `app_colors.dart` (دلالي) |
| الخطوط | ضع الملفات بـ`assets/fonts/` ثم `dart run scripts/sync_fonts.dart` (تفاعلي) |
| شعار شاشة الإقلاع | SVG بـ`assets/images/` ثم `dart run scripts/gen_splash_assets.dart` — راجع [`23_STARTUP_SPLASH.md`](23_STARTUP_SPLASH.md) |

> ⚠️ **وتبديلُ الألوان يُتبَع بـ`flutter test test/color_contrast_test.dart`.**
> الفاحص يشهد على **نسبة تباينٍ ٤٫٥:١** لكلّ زوجٍ (نصٌّ على أرضيّته) بالثيمين —
> وخمسةُ أزواجٍ بالقالب كانت دون الحدّ، **أسوأُها ١٫١٧:١**: نصٌّ فاتح على أرضيّةٍ
> فاتحة بالوضع الداكن، يُقرأ بالشاشة الساطعة بلا شيء.

### ⚠️ اسم الـpackage — مرّةً واحدة أو أبداً

`app_template` مثبَّت بكل `import` بالمستودع وبـ`CLAUDE.md`. فإن بدّلته، بدّله
**بأوّل يوم واستبدالاً شاملاً** — راجع المرحلة 2 بـ[`00_START_HERE.md`](00_START_HERE.md).
مستودعٌ نصفُه باسمٍ ونصفُه بآخر يُصرَّف ويعمل، ثم يكسر كلَّ ملفٍّ يُنسخ بينهما.

---

## 4) تحقّق أن الإعداد سليم

```bash
dart analyze lib test             # ← No issues found
flutter test                      # ← All tests passed!
dart run scripts/check_structure.dart
```

الثلاثةُ تمرّ ⇒ الإعداد سليم. يفشل واحدٌ منها على نسخةٍ لم تُلمس ⇒
[`40_SCRIPTS.md`](40_SCRIPTS.md) §9.

> 📐 **و`check_structure` يطبع «دَينٌ مسجَّل: N مخالفة» ولا يُفشل عليها.** المسجَّل
> بـ`.structure_baseline.txt` دَينٌ سابقٌ للفاحص؛ المُفشِل هو المخالفةُ **الجديدة**
> وحدها. راجع [`03_RULES.md`](03_RULES.md) §R37.

---

## 5) هيكل المستودع

```
lib/
  core/          البنية التحتية
    foundation/    Dart خالص — Failure · BaseUseCase · SafeCubit · العقود
    platform/      أغلفة Flutter/OS — تخزين · اتصال · أذونات · سجلّ
    infra/         التنفيذ — شبكة · بيئة · أخطاء · جلسة
    di/            جذر التركيب (الوحيد الذي يستورد كل شيء)
  modules/       موديولات اختيارية — تُشحن مطفأة
  features/      شرائح العمل — auth · home · settings · startup
  ui/            طبقة الواجهة المشتركة كاملةً
    widgets/       مكتبة الودجات (barrel: widgets.dart)
    theme/ responsive/ extensions/ feedback/ locale/ error/
    state/         كيوبتس حالة الواجهة — pagination · refresh · sync · connectivity
  routes/        auto_route
  resources/     مولَّد — locale_keys · assets · permission_keys

readme/          توثيق القالب  ← أنت هنا
docs/            توثيق مشروعك (فارغ بقصد)
scripts/         عشرة سكربتات
test/            287 اختباراً
```

الحدود بين الطبقات وقواعدها: [`10_ARCHITECTURE.md`](10_ARCHITECTURE.md) ·
[`03_RULES.md`](03_RULES.md) §R16

---

## التالي

المرحلة 3 من [`00_START_HERE.md`](00_START_HERE.md) — ابدأ بـ
[`03_RULES.md`](03_RULES.md).
