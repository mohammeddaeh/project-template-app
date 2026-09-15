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
أوّلُ إطارٍ من فلاتر = الوجهةُ نفسُها   (login · shell)
```

**ولا شاشةَ سبلاش بفلاتر.** حُذفت `SplashScreen` و`SplashCubit` و`SplashState`
والمسارُ `SplashRoute` (2026-08-30).

### ما كان يقع قبلها

`SplashRoute` كان `initial: true`: شاشةٌ تعرض الشعار، تتّخذ القرار، ثم
`replaceAll` إلى الوجهة. فيرى المستخدم **شعارَين متتاليَين** — شعارَ النظام ثم
شعارَ فلاتر. ولو تطابقا بالبكسل (وقد ضُبطا حتى تطابقا) بقيَ **تلاشي النظام**
بينهما: انخفاضُ عتمةٍ يُقرأ انتقالاً ثانياً.

والحلُّ لم يكن ضبطَ الشعارين أكثر — بل **إلغاء الثاني**. فلاتر يُبقي splash
النظام معلَّقاً حتى يرسم أوّلَ إطار؛ فإن كان ذلك الإطارُ هو الوجهةَ الصحيحة،
لم يبقَ شيءٌ بينهما.

### الطبقات الباقية

| # | الطبقة | من يملكها | متى تُرى |
|---|---|---|---|
| ١ | `LaunchTheme` بـ`values*/styles.xml` | أندرويد | من الضغطة حتى أول إطار |
| ٢ | `NormalTheme` | أندرويد | خلف النافذة حتى أول إطار — **أرضيةٌ خضراء لا بيضاء** |

### أين يُكتب اللون

`android/app/src/main/res/values/colors.xml` ← `splash_background` = `#0D3A2F`،
وهو `AppColors.bgBrand` نفسُه الذي ترسمه `BrandBackground` بشاشة الدخول.
**المصدران اثنان ولا ثالث** — وتغييرُ أحدهما بلا الآخر يعيد الوميض.

---

## ٢ · القناعُ الدائري — وهو الذي يقرّر مقاس الشعار

أندرويد 12+ يعرض الرمز داخل **لوحة ٢٨٨dp**، ويقصّه بدائرةٍ قطرُها **ثلثاها
(١٩٢dp)**. وقد رُئي بالقياس لا بالوثيقة: لقطةٌ بالشعار الكامل عند ضلع ٢٧٥
أظهرت النجومَ محذوفة و«ENDOWMENTS» مبتورةً بقوسٍ واضح، ولقطةٌ عند ضلع ٣٨٢
أعطت قطراً ٢٤٩٫٧ وحدة = **٠٫٦٥٣ من الضلع** — أي الثلثين بالضبط.

### أ · المرساة ليست مركزَ الشعار

النقطةُ التي تقع بمركز اللوحة هي **مركزُ أصغر دائرةٍ تسع الشعار كلَّه**:
`(112.893, 160.457)` من صندوقٍ `226.692 × 274.913` — أي **٠٫٥٨٤ من أعلى
الشعار** لا ٠٫٥. وأيُّ مركزٍ آخر يعطي دائرةً أكبر، أي شعاراً أصغر.

والطبقتان تُرسيانها بطريقتين: `splash_icon_v31.xml` بـ`<group
android:translateY>` داخل لوحته، و`splash_logo_full.xml` بمدّ ضلعه حولها ثم
`gravity="center"`.

### ب · وسقفُ المقاس ١٣٢dp

نصفُ قطر الدائرة الحاوية ١٦٠٫٤٥٧ من ٢٧٤٫٩١٣، فأكبرُ شعارٍ **غير مقصوص**:

```
192dp × 226.692 ⁄ (2 × 160.457) ≈ 136dp   →   132dp بعد هامش تنعيم
```

> **وهذا ثمنُ إبقاء الاسم مع النسر، ودُفع بقرار.** نسرٌ بلا نصّ كان يسع
> **١٦٢dp** لأن دائرتَه أصغر بكثير — وقد جُرّب وعُدل عنه: المطلوب الشعارُ
> كاملاً بالاسم. فالفارق مقاسٌ لا هويّة.

و`splash_logo_full.xml` (لما دون أندرويد 12) يُكتب بنفس الـ١٣٢dp **كي تتطابق
النسختان على الجهازين**، لا لأن قناعاً يفرضه هناك.

### ج · ولا يُخمَّن رقمٌ من هذه

```
dart run scripts/gen_splash_assets.dart
```

يقرأ `logo_MOW.svg`، ويحسب صندوقَ الحبر والدائرةَ الحاوية، ويكتب المتجهتين.
تغييرُ الشعار يعني تشغيلَه — لا أكثر، ولا تقدير.

---

## ٣ · أندرويد **لا يُولَّد** من `flutter_native_splash`

`android: false` بـ[`../flutter_native_splash.yaml`](../flutter_native_splash.yaml) — **بقرار**، وهذه أسبابه:

| ما تفعله الأداة | العطل |
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
├── drawable/splash_logo_full.xml      ← ٤١ مساراً · 132dp · المرساةُ بالوسط
├── drawable/splash_icon_v31.xml       ← ٤١ مساراً · لوحة ٤٩٣٫٧ · تسع القناع
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
**ولم تُزل**: بعد حذف شاشة فلاتر لم يبقَ خلفها شعارٌ ثانٍ تُقارَن به، فهي
تلاشٍ واحدٌ بين الشعار والوجهة — لا انتقالٌ بين شعارين.

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

### وطباعةُ التوكن بالإقلاع — `STARTUP-TOKEN` (2026-08-30)

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

[`resolveDeepLink`](../lib/routes/deep_link_resolver.dart) (2026-09-14) دالّةٌ
نقيّةٌ مستخرَجةٌ عمداً — قابلةٌ للاختبار المباشر
([`test/deep_link_resolver_test.dart`](../test/deep_link_resolver_test.dart))
بلا تركيب `App` كاملةً. قرارُها:

```
initial && (path فارغ أو "/")  →  DeepLink.single(_startRoute)   ← إقلاعٌ عاديّ، قرارُ StartupResolver يحكم
غير ذلك                        →  DeepLink.path(path)             ← رابطٌ حقيقيّ، يُحلّ عبر شجرة router.dart بحرّاسها
```

**قبل هذا التاريخ** كان `deepLinkBuilder` يتجاهل `PlatformDeepLink` كلّياً
ويُعيد `_startRoute` **دائماً** — فرابطُ تفعيلٍ أو دعوةٍ وصل والتطبيقُ مغلقاً
كان يُفتَح على وجهة `StartupResolver` العادية لا وجهته، ورابطٌ يصل والتطبيقُ
يعمل لم يكن له مسارٌ تشغيليّ أصلاً.

⚠️ **ولا `AutoRoute(initial: true)` بأيّ مسار.** `initial` يفوز على
`deepLinkBuilder` بالإقلاع البارد، فيدخل كلُّ مستخدمٍ من وجهةٍ واحدة مهما كانت
جلسته — عطلٌ صامت: التطبيق يعمل، لكن صاحبَ الجلسة الصالحة يُردّ إلى الدخول.

والمطابقةُ بـ`_startRoute` بحالة الإقلاع العاديّ **شاملة** بقصد: وجهةٌ جديدة
تصير خطأَ ترجمةٍ هناك، لا سقوطاً صامتاً إلى الدخول.

⚠️ **وربطُ نظام التشغيل بالرابط نفسِه (Android `intent-filter` / iOS
Universal Links) خارج نطاق هذا التغيير** — المبنيّ هنا هو جانبُ Flutter وحده
(تحويل `PlatformDeepLink` إلى `PageRouteInfo`)؛ تسجيلُ المخطَّط أو النطاق على
مستوى النظام يبقى على المشروع الذي يستهلك القالب، حسب الروابط الفعلية التي
يحتاجها.

---

## ٦ · ولا مهلةَ عرضٍ دنيا — ولا حركة

كان بـ`SplashScreen` سطرٌ ينتظر `Duration(milliseconds: 2000)` قبل كل تنقّل:
**ثانيتان تُدفعان بكل فتحةٍ للتطبيق** حتى لو انتهى العمل كلُّه في خمسين
مللي‑ثانية. وعذرُه كان حركةَ تكبيرٍ (`TweenAnimationBuilder` من ٠٫٧٢ إلى ١)
تحتاج وقتاً لتُرى. وقد سقط الاثنان مع الشاشة.

⚠️ **ولا تُعَد شاشةُ سبلاشٍ بفلاتر «لتحسين الانتقال».** هي بالضبط ما كان يُنتج
الانتقالَ الثاني الذي حُذف.

---

## ٧ · iOS — دَينٌ مفتوح

`ios: true` ما زال مولَّداً من `flutter_native_splash`، **وأصولُه منقّطةٌ
محدودةٌ بمقاس المصدر**: `LaunchImage@3x.png` = ١٧٠×٢٠٦px أي **٥٦٫٧pt** عرضاً،
مقابل ١٣٢dp على أندرويد — فالنسختان لا تتطابقان بين المنصّتين.

**وما يلزم**: تصديرُ `logo_MOW.svg` عند **٣٩٦×٤٨٠** (وهو ١٣٢pt × 3) ووضعُه
مصدراً بـ`image:`، ثم `dart run flutter_native_splash:create`. ولا يُحلّ من
الكود: تكبيرُ المنقّطة الحالية يعطي شعاراً ضبابياً — أسوأ من الصغير الحادّ.

كذلك `LaunchScreen.storyboard` يضع الصورة بـ`contentMode="center"`، **ولا يُرسي
المرساة** كما يفعل موردا أندرويد.

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
