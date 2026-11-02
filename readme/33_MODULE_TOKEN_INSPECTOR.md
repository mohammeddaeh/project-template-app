# موديول `token_inspector` — التوكن على الشاشة، بلا كونسول

> أداةُ مطوّر لا ميزة. تُشعَل بعلَمٍ واحد لجلسة اختبار، وتعرض على الجهاز كلَّ ما
> يمرّ على اعتماد الجلسة: الدخول، والاستعادة عند الإقلاع، و`401`، والتجديد وما
> تبدّل، والتحقّق من الحفظ، والانقطاع، والرفض. ومع Keycloak تفحص إعدادات الـrealm
> مما يُرى بالردود.
>
> **الغرض**: أن تعرف أن الجلسة تصمد في الميدان — تطبيقٌ أُغلق ساعة، وتغطيةٌ ضعيفة
> لحظةَ التجديد — **قبل** إصدار الإنتاج، لا بشكوى بعده.

---

## ١. التشغيل

```dart
// lib/core/platform/features/app_features.dart
static const tokenInspector = true;
```

لا شيء آخر. `ModulesBootstrap` يُقلعه، فيظهر زرٌّ عائم بأيقونة مفتاح فوق كل الشاشات:
عددُ الأحداث، ولونُ آخرها. يُسحب بالإصبع، وضغطتُه تفتح الورقة.

ومن الكود، حيث تريد:

```dart
import 'package:app_template/modules/token_inspector/token_inspector.dart';

TokenInspector.mark('Opened orders', ['Filter: today']);  // حدثٌ بعنوانك
TokenInspector.snapshot('before upload');                 // ما بالتخزين الآن
const TokenInspectorPanel()                               // الجلسة الآن داخل شاشة
```

⚠️ **لا تمرّر توكناً إلى `mark`** — السجلّ يُحفظ على الجهاز ويُعرض. `snapshot` يقرأ
التخزين ويحفظ البصمة وحدها.

---

## ٢. البنية — النواة تُخبر ولا تعرف من يسمع (R44)

```
core/foundation/contracts/auth_session_observer.dart
  AuthSessionObserver   ← المنفذ: سبعة أحداث، كلُّها void
  TokenGrant            ← ردُّ نقطة الاعتماد كما أرسله الخادم
  AuthSessionRelay      ← ما يُسجَّل بالـDI — يمرّر إلى مستمعٍ يُعلَّق لاحقاً
  NoAuthSessionObserver ← الافتراضي: لا أحد يسمع

ui/overlays/app_overlays.dart
  AppOverlays.register  ← الموديول يسجّل طبقته؛ AppOverlayHost بـMaterialApp.builder يركّبها

modules/token_inspector/
  token_inspector_plugin.dart   ← يعلّق المستمع على المرحِّل ويسجّل الطبقة
  token_inspector.dart          ← TokenInspector.enabled · mark · snapshot · TokenInspectorPanel
  token_inspector_config.dart   ← مفاتيح التخزين · سقف السجلّ · القيم المتوقّعة
  domain/  integration/  data/  presentation/
```

**ولماذا مرحِّلٌ لا استبدال**: `TokenRefreshInterceptor` يُبنى مع `Dio` **قبل** أن
تُقلع الموديولات، فيمسك المرجعَ الذي وجده. استبدالُ التسجيل بعدها يتركه يُخبر
الافتراضيَّ الصامت للأبد. والمرحِّل مرجعٌ ثابت يتبدّل ما خلفه.

### مواضع الإخبار — سطرٌ واحد بلا منطق

| الحدث | المُخبِر |
|---|---|
| `onSessionRestored` | `features/startup/startup_resolver.dart` — بعد `loadCachedToken` |
| `onSignedIn` | `features/auth/login/.../login_repository_impl.dart` — بعد `saveToken` |
| `onRefreshStarted` | `core/infra/network/interceptors/token_refresh_interceptor.dart` — أوّلُ `401` |
| `onRefreshSucceeded` | `features/auth/shared/token_refresh_gateway_impl.dart` — بعد الحفظ |
| `onRefreshDeferred` | المعترض — لم يُجب خادم، **والجلسة باقية** |
| `onRefreshRefused` | المعترض — أجاب خادمٌ بالرفض، **والجلسة مُسحت** |
| `onUnauthorizedAfterRefresh` | المعترض — الطلب أُعيد بالجديد وعاد `401` |

**العقد**: لا يرمي (كلُّ معالجٍ بالموديول ملفوف ويسجّل)، ولا يُنتظر، ولا يعود
بجواب — فلا مستمع يغيّر مصير جلسة. و`savedOk` يُحسب بالموديول بقراءة
`SecureStorageService` بعد الحفظ، لا بالنواة.

`C20` بـ`check_structure.dart` يُفشل أيَّ استيرادٍ للموديول من `core/` أو `ui/`.

---

## ٣. ما تعرضه الورقة — كلُّها LTR

السياق العربي يقلب ترتيب الأسطر الإنكليزية، فالورقة `Directionality.ltr`.

### Session now

يُقرأ من `SecureStorageService`، ويتحدّث كل ثانية ومع كل حدث. يبدأ بحكمٍ واحد ملوّن:

| الحكم | متى |
|---|---|
| `No session` | لا access بالتخزين |
| `Offline ✓ — survives idle` | refresh بـ`typ=Offline` لم ينتهِ |
| `Alive but NOT offline — dies when idle` | refresh بـ`typ=Refresh` — يموت بـ`SSO Session Idle` |
| `Refresh token expired — login required` | refresh منتهٍ |
| `Session token stored — its expiry is known to the server only` | توكنٌ معتم (توكن القالب) |

تحته عدّادٌ لكل توكن: شريط `AppProgress.linear` بالمدة الباقية، وسطرُ ما يحدث بعد
الانتهاء. عدّاد الـrefresh يظهر حين يُضبط `TokenInspectorConfig.refreshTokenKey`.

### Keycloak checks

**تظهر حين يأتي التوكن من Keycloak** (`iss` بمسار `/realms/`)، وتُعاد مع كل ردٍّ
جديد. لكلٍّ: المرصود، والحكم (`✓` · `✗` · `?` لا يُرصد · `i` بلا قيمةٍ متوقّعة)،
وأين يُصلَح.

| الفحص | يُرصد من | `✗` يعني | أين يُصلَح |
|---|---|---|---|
| `offline_access accepted` | `scope` يحويها، و`typ` الـrefresh = `Offline` | refresh عاديّ يموت بالخمول | Client scopes ← `offline_access` (Optional)، ودور `offline_access` للمستخدم |
| Access token lifespan | `expires_in` | يخالف المتوقَّع | Realm ← Tokens ← Access Token Lifespan (والـclient يتقدّم: Client ← Advanced) |
| Refresh token lifespan | `refresh_expires_in` مع `typ` | `typ=Refresh` والمتوقَّع offline ⇒ القيمة `SSO Session Idle` | Realm ← Sessions |
| Offline Session Max Limited | بعد تجديد: هل تقدّم `exp` الـrefresh؟ وبلا `exp` أصلاً ⇒ بلا سقف | لم يتقدّم ⇒ سقفٌ مطلق، يُطرد المستخدم مهما استعمل التطبيق | Realm ← Sessions ← Offline Session Max Limited |
| Refresh token rotation | هل تبدّلت البصمة مع التجديد؟ | للمعلومة | — |
| Revoke Refresh Token | `?` دائماً — لا يُرصد بلا تجربةٍ تُبطل الجلسة، **ولا تجربةَ كهذه بالموديول** | — | Realm ← Tokens (يُنصح مطفأً) |
| Device clock | `iat` الـaccess مقابل ساعة الجهاز لحظةَ الردّ | أكثر من 30 ثانية ⇒ العدّادات تكذب | إعدادات الجهاز |

**القيم المتوقّعة اختيارية**، من `.env.<flavor>.json`:

```json
"KEYCLOAK_EXPECT_ACCESS_LIFESPAN_S": 300,
"KEYCLOAK_EXPECT_OFFLINE_IDLE_S": 2592000,
"KEYCLOAK_EXPECT_OFFLINE": true
```

غيابُ مفتاح يعني عرضَ المرصود بلا حكم — **لا افتراضَ مخمَّناً**. والقسم يقول ذلك
بسطرٍ تحت عنوانه، بأسماء المفاتيح الغائبة — فـ`i` لا يُقرأ «لا مشكلة».

### History

بطاقةٌ لكل حدث: أيقونة ولون بالمعنى، ووقتٌ مع «منذ كم»، وتفاصيل `Label: value`
بعمودين. `CHANGED` و`✓` بالأخضر، و`EXPIRED` و`✗` بالأصفر. وزرّ **Clear**.

السجلّ بـ`StorageService` (`token_inspector.events`)، سقفه 150 حدثاً، **ويبقى بعد
الإغلاق وبعد الخروج** — ذلك جوهر اختبار «التطبيق المغلق». ⛔ **لا يُضاف إلى
`AccountDataCleaner` ولا `LocalDataWiper`**: الخروج حدثٌ يُراد رؤيته.

وtoast عند الدخول والتجديد والرفض.

---

## ٤. لا يُرى بنسخة الإنتاج — حتى لو نُسي العلَم

```dart
static const bool enabled =
    AppFeatures.tokenInspector && !(kReleaseMode && Env.flavor == 'prod');
```

**ثابتٌ يحسبه المصرِّف.** بنسخة `release` بـflavor `prod`: الموديول لا يُقلع، وكلُّ
نداءٍ (`mark` · `snapshot`) يعود من سطره الأول، و`TokenInspectorPanel` يرسم لا شيء.
فسطرٌ نُسي بشاشةٍ لا يراه المستخدم. ونسخةُ `staging` release تعرضه — للاختبار.

**وقبل البناء — `build_apk.dart`**: ببناء `prod` أو `release` يعدّد العلَمَ إن كان
مُشعَلاً، وكلَّ نداءٍ خارج الموديول بملفّه وسطره، ويسأل `[y/N]`. وبلا طرفية يُفشل،
إلا مع `--allow-token-trace` ([`40_SCRIPTS.md`](40_SCRIPTS.md) §2). تذكيرٌ بالحذف،
لا حارسُ أمان — فالنسخة صامتة أصلاً.

---

## ٥. السرّية

| ما | أين |
|---|---|
| الشاشة والسجلّ المحفوظ | **البصمة وحدها** (آخر 6 أحرف) — `TokenReading` وحدها تلمس التوكن |
| التوكن كاملاً | `debugPrint` بـ`kDebugMode` وحده — **لا `LogService`**: يمرّ إلى Crashlytics متى أُشعل `crashReporting` |
| الشبكة | لا شيء يُرسل إلى أي خدمة |

---

## ٦. مشروعٌ بـKeycloak — ما يضيفه

القالب يُصدر توكن جلسةٍ معتماً واحداً، فلا refresh ولا أعمار. مشروعٌ يستوثق من
Keycloak يُخبر بالردّ كاملاً، فتظهر العدّادات والفحوص:

```dart
// 1. token_inspector_config.dart
static const String? refreshTokenKey = PersistenceKeys.refreshToken;

// 2. الدخول — بعد الحفظ
final grant = TokenGrant.fromOAuthJson(json, receivedAt: DateTime.now())!;
_observer.onSignedIn(grant);

// 3. منفّذ TokenRefreshGateway — بعد الحفظ
_observer.onRefreshSucceeded(grant, oldAccess: oldAccess, oldRefresh: oldRefresh);
```

**و`oldRefresh` ضروريّ** لفحصَي Max Limited والتدوير — بلاه يُقارن بآخر ما حُفظ.

⚠️ **ولكي يكون الـrefresh offline أصلاً**، يرسل طلبُ الدخول
`scope: 'openid offline_access'`. بدونه يتسلّم التطبيق refresh عادياً يموت بـ
`SSO Session Idle` — وهذا إصلاحٌ بالمشروع مستقلٌّ عن الموديول؛ الموديول يكشفه فقط.

---

## ٧. التحقّق على جهاز

⚠️ **قبل التثبيت تأكّد أن الـAPK يحمل التغيير.** Gradle يتخطّى ترجمة Flutter أحياناً
ويقول «Built». نسخة **debug** تحمل `assets/flutter_assets/kernel_blob.bin` — ابحث
فيه عن نصٍّ جديد. ونسخة **release** تحمل `lib/<abi>/libapp.so` بدلاً منه. الحلّ:
احذف `build/app/intermediates/flutter/<variant>` وأعد البناء. وإن ظهر
`cannot overwrite`: `android\gradlew --stop` ثم `cmd /c rd /s /q "\\?\<المسار>\build"`.

إعداد Keycloak للاختبار: `Access Token Lifespan = 1 min` و`SSO Session Idle = 1 min`.
**وأعِده بعد الاختبار.**

| السيناريو | المتوقّع |
|---|---|
| دخول | `Signed in` · `typ=Offline` · `Saved: access ✓ · refresh ✓` · الفحوص خضراء |
| انتظار أكثر من دقيقة ثم فتح تبويب | `401 — asking the server…` ← `Token refreshed` (`CHANGED`، `✓`) |
| إغلاق التطبيق 5 دقائق ثم فتحه | `App opened — session restored` ← تجديدٌ ناجح ← بلا شاشة دخول |
| وضع الطيران ثم طلب | `No network — session KEPT` |
| `Offline Session Idle = 2 min` ثم انتظار 3 دقائق | `Server REFUSED — session cleared` بالـstatus والردّ ← شاشة الدخول |
| `tokenInspector = false` | لا زرّ، ولا سجلّ |
| `prod` release والعلَم `true` | لا زرّ — و`build_apk.dart` سأل قبل البناء |

---

## ٨. الإزالة

**الإطفاء**: `tokenInspector = false`، واحذف نداءاتك اليدوية (`build_apk.dart` يعدّدها).

**الحذف الكامل**: مجلّد `lib/modules/token_inspector/`، وسطره بـ`ModulesBootstrap`،
وعلَمه، و`test/token_inspector/`. **المنفذ والمرحِّل و`AppOverlays` تبقى** — النواة
لا تعرف الموديول، فلا شيء فيها ينكسر.
