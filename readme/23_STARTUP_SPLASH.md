# 23 · الإقلاع وشاشة البدء

> **تفتحه حين**: تمسّ `main()` · تضيف تهيئةً قبل أول إطار · تغيّر شعار الإقلاع
> أو لونه · تتساءل «أين شاشة السبلاش؟» أو «لماذا `flutter_native_splash` مطفأٌ
> على أندرويد؟».
>
> المرجع المجاور: [`10_ARCHITECTURE.md`](10_ARCHITECTURE.md) لخريطة `lib/`.

---

## ١ · شاشةُ إقلاعٍ **واحدة** — والقرارُ قبل أول إطار

```
ضغطةُ الأيقونة
   ↓
splash النظام  ← الشعارُ كاملاً على #0D3A2F   (طوال ما تحته)
   ↓                 main() : تهيئة + StartupResolver.resolve()
   ↓
أوّلُ إطارٍ من فلاتر = الوجهةُ نفسُها   (welcome · login · shell)
```

**ولا شاشةَ سبلاش بفلاتر.** شاشةٌ تعرض الشعار ثم `replaceAll` إلى الوجهة تُري
المستخدم **شعارَين متتاليَين** — ولو تطابقا بالبكسل يبقى **تلاشي النظام**
بينهما: انخفاضُ عتمةٍ يُقرأ انتقالاً ثانياً. وفلاتر يُبقي splash النظام معلَّقاً
حتى يرسم أوّلَ إطار؛ فإن كان ذلك الإطارُ هو الوجهةَ الصحيحة، لا يبقى شيءٌ بينهما.

### الطبقات

| # | الطبقة | من يملكها | متى تُرى |
|---|---|---|---|
| ١ | `LaunchTheme` بـ`values*/styles.xml` | أندرويد | من الضغطة حتى أول إطار |
| ٢ | `NormalTheme` | أندرويد | خلف النافذة حتى أول إطار — **أرضيةٌ خضراء لا بيضاء** |

### أين يُكتب اللون

`android/app/src/main/res/values/colors.xml` ← `splash_background` = `#0D3A2F`،
وهو `AppColors.bgBrand` نفسُه الذي ترسمه شاشاتُ الهوية بالتطبيق.
**المصدران اثنان ولا ثالث** — وتغييرُ أحدهما بلا الآخر يعيد الوميض.

---

## ٢ · القناعُ الدائري — وهو الذي يقرّر مقاس الشعار

**الشعار ملفٌّ يُستبدل**: `assets/images/brand/app_logo.svg` (وشرطُه بـ
[`../assets/images/brand/README.md`](../assets/images/brand/README.md)). وكلُّ رقمٍ أدناه
يُشتقّ منه بـ`gen_splash_assets.dart` — لا يُكتب باليد.

أندرويد 12+ يعرض الرمز داخل **لوحة ٢٨٨dp**، ويقصّه بدائرةٍ قطرُها **ثلثاها
(١٩٢dp)** — قِيس على جهاز فطابق المواصفة (٠٫٦٥٣ من الضلع؛ والسكربت يأخذ ٠٫٦٥
هامشاً للتنعيم).

### أ · المرساة ليست مركزَ الشعار

المرساةُ **مركزُ أصغر دائرةٍ تسع حبر الشعار**، لا مركزُ صندوقه: القناعُ دائريّ،
فالمركزُ الذي يصغّر نصفَ القطر يسمح بأكبر شعارٍ غير مقصوص. وشعارٌ غير متناظر
(نصٌّ تحت رمز) تقع مرساتُه بعيداً عن منتصف صندوقه.

والطبقتان تُرسيانها بطريقتين: `splash_icon_v31.xml` بـ`<group
android:translateX/Y>` داخل لوحته، و`splash_logo_full.xml` بمدّ ضلعه حولها ثم
`gravity="center"`.

### ب · وسقفُ المقاس

أكبرُ شعارٍ غير مقصوص = `192dp × عرض الحبر ⁄ (2 × نصف قطر الدائرة الحاوية)`،
ثم هامشُ تنعيم. والسكربت يطبع الرقم مع كل تشغيل؛ ورسمةُ ما دون أندرويد 12
(`splash_logo_full.xml`) تُكتب بنفس المقاس **كي تتطابق النسختان على الجهازين**،
لا لأن قناعاً يفرضه هناك.

### ج · ولا يُخمَّن رقمٌ من هذه

```
dart run scripts/gen_splash_assets.dart
```

يقرأ `app_logo.svg`، ويحسب صندوقَ الحبر والدائرةَ الحاوية، ويكتب المتجهتين،
ولونُ كل مسارٍ يُنقل كما هو فوق `splash_background`. تغييرُ الشعار يعني
تشغيلَه — لا أكثر، ولا تقدير.

---

## ٣ · أندرويد **لا يُولَّد** من `flutter_native_splash`

`android: false` بـ[`../flutter_native_splash.yaml`](../flutter_native_splash.yaml) — **بقرار**، وهذه أسبابه:

| ما تفعله الأداة | الأثر |
|---|---|
| تكتب `splash.png` بمقاس الأصل لكل كثافة | ٢٢٧px بـxxxhdpi = **٥٦٫٧dp** عرضاً، بينما رمز أندرويد 12+ ١٣٢dp — نسختان مختلفتان بحسب إصدار النظام |
| تضع الشعار رمزاً بلوحةٍ لا تحسب القناع | الدائرةُ تقصّ سطرَ النصّ أسفلَ الشعار وتهزّ ما بقي — والحلُّ لوحةٌ أوسع لا شعارٌ أصغر |
| لا تكتب `windowBackground` لـ`LaunchTheme` بـv31 | يُورَث أبيضُ `Theme.Light` ⇒ **إطارٌ أبيض** بين splash النظام وأول إطار |
| تترك `NormalTheme` على `?android:colorBackground` | وميضٌ أبيضُ ثانٍ |
| `fullscreen: true` | يُخفي شريط الحالة ثم يعيده `edgeToEdge` ⇒ قفزةُ تخطيط |

**فالبديل ستةُ ملفاتٍ باليد**، ومتجهُها مولَّدٌ من مسارات الـSVG نفسِها:

```
android/app/src/main/res/
├── drawable/launch_background.xml     ← لونٌ + splash_logo_full
├── drawable/splash_logo_full.xml      ← مساراتُ app_logo.svg · المرساةُ بالوسط
├── drawable/splash_icon_v31.xml       ← مساراتُ app_logo.svg · لوحةٌ تسع القناع
├── values{,-night}/styles.xml         ← بلا windowFullscreen · NormalTheme أخضر
├── values{,-night}-v31/styles.xml     ← windowSplashScreen* · AnimationDuration=0
└── values/colors.xml                  ← splash_background
```

> ⛔ **ولا تُعِد `android: true`.** أوّلُ `dart run flutter_native_splash:create`
> بعدها يمحو الستة ويعيد الأعطال الخمسة — **ولا `dart analyze` ولا
> `check_structure` يقول شيئاً**، كلاهما أخضر. الحارسُ هو هذه الصفحة وحدها.

### وحركةُ الخروج لا تُطفأ من XML

`windowSplashScreenAnimationDuration` يمسّ **الدخول** وحده. حركةُ الخروج (تلاشي
الرمز) يملكها النظام، ولا تُزال إلا بـ`setOnExitAnimationListener` بكود Kotlin.
**وهي باقيةٌ بقصد**: لا شعارَ ثانياً بفلاتر تُقارَن به، فهي تلاشٍ واحدٌ بين الشعار والوجهة — لا انتقالٌ بين شعارين.

---

## ٤ · ترتيب `main()` — وكلُّه خلف شعارٍ مرئي

```
WidgetsFlutterBinding.ensureInitialized()
  ↓
Bloc.observer · EquatableConfig · Env.init()          ← متزامنة، بلا كلفة
  ↓
Future.wait: Hive · EasyLocalization · dateFormatting('ar','en')
  ↓
await configureInjection(Env.flavor)
  ↓
ModulesBootstrap.start(getIt)                         ← بلا await
  ↓
Future.wait: قراءةُ الخط · الثيم · edgeToEdge · الاتجاه
  ↓
await StartupResolver(...).resolve()                  ← ينتظر ModulesBootstrap.ready بداخله
  ↓
runApp( App(startAt: …) )                             ← أوّلُ إطار = الوجهة
```

و`StartupResolver` يأخذ `AuthSessionObserver` من الـDI ويُخبره بما قرأه من
التخزين (`onSessionRestored`) — سطرٌ بلا منطق، لا يُنتظر ولا يغيّر الوجهة.
راجع [`33_MODULE_TOKEN_INSPECTOR.md`](33_MODULE_TOKEN_INSPECTOR.md) §٢.

وكلُّه داخل `runZonedGuarded(_bootstrap, _onError)`: خطأٌ لا يلتقطه أحد يصل
`_onError`، فيمرّ بـ`LogService.error` (فيراه `crash_reporting` حين يُشعَل) ثم
يُطبع بـ`debugPrint`.

### القاعدة

> **لا إطارَ مؤقّتاً يُستبدل.** ما يلزم لتحديد الوجهة يُنتظر هنا؛ وما لا يلزمها
> (`_accountContext.refresh` · `_pullOnStart`) يُطلَق بـ`unawaited`.

وكلُّ ذلك يقع و`splash` النظام معروضٌ بالشعار الكامل — فالانتظار **مرئيٌّ
ومبرَّر**، لا شاشةٌ سوداء.

### وما يُنتظر — ولماذا

| المُنتظَر | لماذا قبل أول إطار |
|---|---|
| `Hive.initFlutter` | `configureInjection` يسجّل `Box` |
| `EasyLocalization.ensureInitialized` | الودجة نفسُها بـ`runApp` |
| `configureInjection` | `App.initState`: `AppRouter` · `AppTheme` · `LocaleProvider` · `StorageService` · `ConnectivityCubit` |
| الخط والثيم | يُمرَّران وسيطَين لـ`App` |
| `StartupResolver.resolve` | **يحدّد الوجهة** — وبدونه لا نعرف ماذا نرسم |

### وطباعةُ التوكن بالإقلاع — `STARTUP-TOKEN`

`StartupResolver._printTokenInDebug` يطبع التوكن المخزَّن كاملاً عقب
`loadCachedToken`، **بنسخة التطوير وحدها** (`kDebugMode`). الغرضُ واحد: نسخُ
توكنٍ حيّ إلى Postman بدل تسجيل دخولٍ يدوي بكل تجربة.

```
[STARTUP-TOKEN] Bearer eyJhbGciOi…      ← أو: No cached token on this device.
```

⚠️ **وهو استثناءٌ من سياسةٍ قائمة**: `NetworkLogInterceptor._redact` يستبدل
ترويسة `Authorization` بـ`<present, N chars>` بكل طلب، لأن السجلّات تُلصق
بالمحادثات وتذاكر العمل. فاحذف السطر من أي مخرَجٍ تشاركه. والشرط `const`،
فالسطرُ ونصُّه يسقطان من نسخة الإصدار بالكامل.

### ⚠️ و`ModulesBootstrap.ready` يُنتظر **داخل** `resolve()` لا في `main()`

وقبل فرع `debugSkipLogin` بالذات: ذلك الفرع يدخل الغلاف مباشرةً، والغلافُ يحلّ
مستودعاتٍ لا تُبدَّل إلا بذيل التهيئة (`applySyncRepositoryDecorators`) — ودخولٌ
يسبقها يعني شاشاتٍ تقرأ من المستودع غير المُغلَّف **بصمت**.

و`ready` **لا يرمي بعقده**: موديولٌ يُخفق إقلاعُه يُطفأ ويمضي التطبيق. فلو نفذ
الرمي لَما رُسم إطارٌ أبداً — أي أن إخفاق موديولٍ اختياريّ يصير تطبيقاً لا يقلع.

---

## ٤‑ب · الوجهة — ترحيبٌ مرّةً واحدة، ثم ما يقرّره وضعُ الدخول

`StartupResolver.resolve` يجمع حقيقتين ثم يسلّمهما لدالّةٍ نقيّة `decideStartup`
(مختبَرة بـ`test/startup_decision_test.dart`):

| | `none` (افتراضاً) | `required` | `optional` |
|---|---|---|---|
| أوّلُ تشغيلٍ على الجهاز | الترحيب | الترحيب | الترحيب |
| بلا جلسة | الرئيسية | الدخول | الرئيسية زائراً |
| بجلسةٍ صالحة | — | الرئيسية | الرئيسية |
| انتهاء الجلسة (`AuthEventBus`) | لا جلسة أصلاً | ⇐ الدخول | ⇐ الرئيسية زائراً |
| تبويب الحساب | لا يُعرض | الملف الشخصي | `AccountTab`: دعوةٌ للدخول ⇄ الملف |

**`WelcomeScreen`** (`features/startup/presentation/pages/`) تُعرض حين لم يُعلَّم
`PersistenceKeys.welcomeSeen`، على `bgBrand` — اللونِ نفسِه تحت شعار الإقلاع،
فلا قفزة لون. «ابدأ» يعلّم المفتاح ويسأل `decideStartup` بـ`welcomeSeen: true`
أين يذهب. والمفتاح لا يُمسح بالخروج؛ يمسحه `DataOriginGuard` وحده حين يتبدّل الخادم.

**والوضع يُختار مرّةً عند الإنشاء**: `setup_project.dart --auth none|required|optional`
يكتب `AppFeatures.authMode` ويحفظه بالبيان. وبوضع `none` لا يُقرأ توكنٌ أصلاً،
وشاشاتُ الحساب تبقى بالكود — تبديلُ الوضع لاحقاً سطرٌ واحد.

## ٥ · كيف تصل الوجهةُ إلى الموجّه

`StartupResolver.resolve()` يُعيد [`StartupDestination`](../lib/features/startup/startup_destination.dart)،
ويُمرَّر إلى `App(startAt: …)`، ويتحوّل مساراً بـ`app.dart`:

```dart
routerConfig: _router.config(
  deepLinkBuilder: (platformLink) => resolveDeepLink(
    initial: platformLink.initial,
    path: platformLink.path,
    startRoute: _startRoute,
  ),
)
```

[`resolveDeepLink`](../lib/routes/deep_link_resolver.dart) دالّةٌ
نقيّةٌ مستخرَجةٌ عمداً — قابلةٌ للاختبار المباشر
([`test/deep_link_resolver_test.dart`](../test/deep_link_resolver_test.dart))
بلا تركيب `App` كاملةً. قرارُها:

```
initial && (path فارغ أو "/")  →  DeepLink.single(_startRoute)   ← إقلاعٌ عاديّ، قرارُ StartupResolver يحكم
غير ذلك                        →  DeepLink.path(path)             ← رابطٌ حقيقيّ، يُحلّ عبر شجرة router.dart بحرّاسها
```

`deepLinkBuilder` يُعيد `_startRoute` **دائماً** ⇐ رابطُ تفعيلٍ أو دعوةٍ يصل
والتطبيقُ مغلق يُفتح على وجهة `StartupResolver` العادية لا وجهته.

⚠️ **ولا `AutoRoute(initial: true)` بأيّ مسار.** `initial` يفوز على
`deepLinkBuilder` بالإقلاع البارد، فيدخل كلُّ مستخدمٍ من وجهةٍ واحدة مهما كانت
جلسته — عطلٌ صامت: التطبيق يعمل، لكن صاحبَ الجلسة الصالحة يُردّ إلى الدخول.

والمطابقةُ بـ`_startRoute` بحالة الإقلاع العاديّ **شاملة** بقصد: وجهةٌ جديدة
تصير خطأَ ترجمةٍ هناك، لا سقوطاً صامتاً إلى الدخول.

⚠️ **وربطُ نظام التشغيل بالرابط نفسِه (Android `intent-filter` / iOS
Universal Links) خارج نطاق القالب** — المبنيّ هنا هو جانبُ Flutter وحده
(تحويل `PlatformDeepLink` إلى `PageRouteInfo`)؛ تسجيلُ المخطَّط أو النطاق على
مستوى النظام يبقى على المشروع الذي يستهلك القالب، حسب الروابط الفعلية التي
يحتاجها.

---

## ٦ · ولا مهلةَ عرضٍ دنيا — ولا حركة

مهلةُ عرضٍ ثابتة (`Duration(milliseconds: 2000)` قبل التنقّل) **تُدفع بكل فتحةٍ
للتطبيق** حتى لو انتهى العمل كلُّه في خمسين مللي‑ثانية — وحركةُ شعارٍ تحتاج
وقتاً لتُرى هي عذرُها الوحيد.

⚠️ **ولا تُضَف شاشةُ سبلاشٍ بفلاتر «لتحسين الانتقال».** هي بالضبط ما يُنتج
الانتقالَ الثاني (§١).

---

## ٧ · iOS — منقّطٌ من `app_logo.png`

`ios: true` بـ`flutter_native_splash.yaml`، ومصدرُه `assets/images/brand/app_logo.png`:
**مقاسُه بالبكسل هو مقاسُه بالنقاط على iOS** — فيُصدَّر ١٣٢×١٣٢ ليطابق ١٣٢dp على
أندرويد، ثم `dart run flutter_native_splash:create`. ولونُ `color` بالملف نفسُه
`splash_background` بأندرويد.

⚠️ `LaunchScreen.storyboard` يضع الصورة بـ`contentMode="center"`، **ولا يُرسي
المرساة** كما يفعل موردا أندرويد — فشعارٌ غير متناظر يقع على iOS أعلى أو أسفل قليلاً.

---

## ٨ · بطاقة المراجعة

- [ ] `splash_background` بـ`colors.xml` = `AppColors.bgBrand`
- [ ] `android: false` ما زال بـ`flutter_native_splash.yaml`
- [ ] **لا `AutoRoute(initial: true)`** بـ`router.dart`
- [ ] `deepLinkBuilder` ما زال موصولاً بـ`app.dart` عبر `resolveDeepLink`
- [ ] المتجهتان مطابقتان لما يكتبه `gen_splash_assets.dart`
- [ ] لا `windowFullscreen` بأي `LaunchTheme`
- [ ] `NormalTheme.windowBackground` = `@color/splash_background` بالأربعة
- [ ] `ModulesBootstrap.start` بلا `await` بـ`main()`، و`ready` مُنتظَرٌ داخل `resolve()`
- [ ] **لا شاشةَ سبلاشٍ بفلاتر** — أوّلُ إطارٍ هو الوجهة
- [ ] كلُّ وجهةٍ بـ`StartupDestination` لها فرعٌ بـ`_startRoute` (`app.dart`) وحالةٌ بـ`test/startup_decision_test.dart`
- [ ] `WelcomeScreen` على `bgBrand` = `splash_background`
