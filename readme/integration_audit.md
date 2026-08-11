# تدقيق التكامل — القالب كاملاً (Flutter + Node)

> **تاريخ التدقيق:** 2026-08-11 — بعد commit `bb41c1f` (حزمة `auth` بالفرونت + إعادة توجيه `multi_device`).
> **النطاق:** `app_template/lib/**` + `backend_template/src/**` + وثائق المستودعَين.
> **السؤال المطروح:** هل هذا القالب جاهز لبدء إنتاج تطبيقات حقيقية؟

---

## 🔴 الحكم في سطر واحد

**البنية جاهزة. العقد ليس كذلك.**

الطبقات، الفصل بين `core/foundation/platform/infra`، محرّك المصادقة بالباك، الـenvelope، الـi18n، الـCI بالمستودعَين، وOpenAPI الكامل (14 endpoint) — كلّها على مستوى إنتاجي فعلاً.

لكن **مسار الدخول لا يعمل**: الفرونت يقرأ مفاتيح JSON لا يرسلها الباك. مشروع جديد يُبنى على هذا القالب اليوم سيُسجّل الدخول بنجاح على السيرفر ثم يعرض رسالة خطأ عامة على الشاشة — وهو أسوأ شكل عطل، لأن السجلّ يقول «200 OK».

| المحور | الحالة |
|---|---|
| بنية الطبقات والفصل | ✅ جاهز |
| محرّك المصادقة (باك) | ✅ جاهز — 14 endpoint موثّقة بـOpenAPI |
| **عقد الـwire بين الطرفين** | 🔴 **مكسور — 3 أعطال قاطعة** |
| اكتمال دورة الحساب | 🟠 ناقص — لا تسجيل حساب بالفرونت |
| الاختبارات | 🟠 صفر بالباك · 6 ملفات بالفرونت |
| توثيق الباك | 🔴 خارج المزامنة تماماً |
| جاهزية النشر | 🟠 ناقص — لا Dockerfile للتطبيق |

---

## الجزء ١ — أعطال قاطعة (Blockers)

> هذه ليست ملاحظات جودة. كلٌّ منها يمنع أول تطبيق يُبنى على القالب من العمل.

### 🔴 B1 — عقد `POST /account/login`: `data.user` مقابل `data.account`

**الباك يرسل** ([account.dto.ts](../../backend_template/src/features/account/dtos/account.dto.ts)، `loginResponseSchema`):

```json
{ "status": true, "message": "...", "data": { "account": {…}, "token": "…", "session_id": 12 } }
```

**الفرونت يقرأ** ([login_model.dart:20](Features/auth/login/data/models/login_model.dart#L20)):

```dart
user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
```

`json['user']` تساوي `null`، والـcast إلى `Map<String, dynamic>` يرمي `TypeError`.

**لماذا هذا العطل هو الأسوأ في القائمة:** الاستثناء لا يصل المستخدم كـcrash — `HandleBodyResponse.body()` يلتقط كل استثناء ويحوّله عبر `FailureMapperRegistry` إلى `Failure` عامّة. فالنتيجة: **السيرفر يجيب 200 وينشئ جلسة فعلية، والشاشة تعرض «حدث خطأ»**. لا سجلّ خطأ بالسيرفر، ولا رسالة مفيدة بالعميل.

كذلك `session_id` الذي يرسله الباك يُهمَل تماماً بالفرونت.

---

### 🔴 B2 — عقد `GET /account/me`: مستوى تداخل زائد

**الباك يرسل** `data` = كائن الحساب مباشرةً (`toWireAccount(row)` — بلا أي تغليف).

**الفرونت يقرأ** ([current_user_model.dart:19](Features/auth/me/data/models/current_user_model.dart#L19)) نفس المفتاح غير الموجود `json['user']`، مع تعليق داخل الملف يقول «نفس شكل `POST /users/login`» — وهو endpoint لا وجود له بهذا الباك.

**الأثر:** `profile_screen` — المستهلك الوحيد لـ`GetCurrentUserUseCase` — يفشل دائماً. وبما أن `/me` هي أيضاً الطريق الوحيد لاكتشاف تغيّر حالة الحساب من جهة السيرفر، فحالة `suspended` أو `disabled` لن تصل العميل أبداً.

---

### 🔴 B3 — `MainShellRoute` غير مسجَّلة بالراوتر

[login_screen.dart:87](Features/auth/login/presentation/pages/login_screen.dart#L87) ينتقل بعد الدخول الناجح إلى `MainShellRoute()`.
[router.dart](routes/router.dart) لا يسجّل هذه الصفحة إطلاقاً — القائمة فيها `HomeRoute` فقط.

**لماذا لم يلتقطها `dart analyze`:** `auto_route` يولّد class لكل widget يحمل `@RoutePage()` بغضّ النظر عن وجوده في شجرة الراوتر، فالكود يُترجم بلا شكوى ويفشل **وقت التشغيل** فقط.

وهناك تناقض إضافي بنفس الموضع: `splash_screen` ينتقل إلى `HomeRoute`، و`login_screen` إلى `MainShellRoute`. وجهتان مختلفتان لنفس المعنى — وواحدة منهما غير موجودة.

> **فحص شامل:** الطرق المستخدَمة وغير المسجَّلة هي `MainShellRoute` (كود حيّ) + `ProfileRoute`/`DetailsRoute`/`EditRoute`/`RegisterRoute`/`RegistrationStatusRoute` (داخل تعليقات فقط — غير مؤذية).

---

### 🔴 B4 — `AuthUser` يتوقّع حقولاً لا يرسلها الباك

| ما يقرأه [auth_user_model.dart](Features/auth/shared/models/auth_user_model.dart) | ما يرسله `WireAccount` |
|---|---|
| `first_name` · `last_name` · `phone` | ❌ غير موجودة |
| `image` · `address` · `is_admin` · `mfa_enabled` · `rejection_reason` | ❌ غير موجودة |
| `id` · `email` · `full_name` · `email_verified` · `email_verified_at` · `status` · `created_at` | ✅ موجودة |

النتيجة — حتى بعد إصلاح B1 — مستخدم باسم أول فارغ، اسم أخير فارغ، هاتف فارغ، و`isAdmin = false` دائماً.

هذا **ليس عطلاً بالمعنى الكامل**: الملف موثَّق صراحةً بأنه «الملف الوحيد الذي يُعدَّل بكل مشروع ولا يُزامَن». لكن **قالباً يشحن الطرفين معاً يجب أن يتطابق طرفاه افتراضياً** — وإلا فأول تجربة لأول مطوّر تنتهي بشاشة ملف شخصي فارغة، وهو أسوأ انطباع أول ممكن.

---

### 🔴 B5 — `permission_keys` / `is_super_admin`: عقد لطرف واحد

`LoginModel` و`CurrentUserModel` و`CurrentUserRepository` كلها تقرأ وتخزّن `permission_keys` و`is_super_admin`.
الباك لا يرسل أياً منهما، و`CLAUDE.md` الخاص به ينصّ صراحةً على أن **RBAC خارج نطاق القالب بقصد**.

الافتراضات (`const []` و`false`) تمنع الانهيار، فالضرر ليس تشغيلياً — بل أن القالب يشحن **بنية صلاحيات فارغة دائماً** قد يبني عليها مطوّر شاشاتٍ تخفي أزراراً لن تظهر أبداً.

---

## الجزء ٢ — فجوات وظيفية

### 🟠 G1 — لا شاشة تسجيل حساب بالفرونت

`ApiUrls.register` معرّفة ([api_urls.dart:15](core/infra/network/rest/api_urls.dart#L15)) و**بلا مستهلك واحد** في `lib/` كلّه. والباك يملك `POST /account/register` كاملاً مع rate-limit ساعيّ وإرسال رمز التحقق.

`login_screen` يعرض نصّ «ليس لديك حساب؟» **بلا أي زر بجانبه** — وهو موثَّق بتعليق يشرح القرار، لكن النتيجة العملية: **تطبيق يُبنى من هذا القالب لا يستطيع إنشاء حساب واحد** إلا عبر Swagger أو curl.

هذه أكبر فجوة وظيفية في القالب: حزمة `auth` تغطّي الدخول · الخروج · نسيان كلمة المرور · تغييرها · تأكيد البريد · الجلسات — وتُسقط الخطوة **الأولى** في دورة حياة أي حساب.

### 🟠 G2 — صفر اختبارات بالباك

`package.json` لا يحوي vitest ولا jest ولا supertest، ولا يوجد ملف `*.test.ts` واحد. الـCI يشغّل `typecheck` و`check:messages` و`lint` و`build` — أربعتها تثبت أن الكود **يُترجم**، ولا تثبت أن `signIn` يرفض كلمة مرور خاطئة.

ومحرّك المصادقة تحديداً هو آخر ما يجوز أن يبقى بلا اختبارات: قواعده أمنية (توحيد ردود الرفض · تجزئة كل رمز · سقف محاولات لكل رمز)، وكسرها **لا يظهر كخطأ** — يظهر كـ«يعمل» مع ثغرة.

الفرونت أفضل حالاً (6 ملفات) لكن ولا واحد منها يغطّي مسار المصادقة أو تحليل الـwire — ولو وُجد اختبار `LoginModel.fromJson` واحد لَما مرّ العطل B1.

### 🟠 G3 — لا feature CRUD مرجعية من طرف إلى طرف

`core/pagination/pagination.ts` بالباك مبني بالكامل (`items` + `page` + `limit` + `total` + `total_pages`)، و`PaginationCubit` + `PaginationBuilderWdg` بالفرونت مبنيان بالكامل — **ولا endpoint واحد يستخدم الأول، ولا feature حقيقية تستهلك الثاني**.

الشاشة الوحيدة التي تعرض القوائم (`TestPaginationDemoScreen`) تعمل على بيانات وهمية. فالنتيجة: **شكل الـpagination لم يُختبر مرّة واحدة على سلك حقيقي**، وهو بالضبط نوع التطابق الذي انكسر في B1 و B2.

feature مرجعية واحدة (`notes` أو `items`) بالطرفين — قائمة مُصفّحة + إنشاء + تعديل + حذف — تُثبت الـpagination والـ422 والـ404 و`ConflictError` وتصير المرجع الحيّ الذي يُنسخ منه.

### 🟠 G4 — `SecurityEventSink` بلا وجهة

المنفذ جاهز ويُصدر 15 حدثاً، و`app.ts` يستدعي `configureAuth()` **بلا `securityEventSink`** — والتعليق هناك يقرّ بذلك. فالنتيجة الافتراضية: **محاولة تخمين كلمة مرور لا تترك أثراً واحداً**. القالب يوثّق هذا كقرار، لكن sink افتراضي يكتب إلى `pino` سطر واحد — لا أكثر — يحوّله من «مقصود» إلى «آمن افتراضياً».

### 🟠 G5 — `device_info` مرهون بـflag مطفأ

`MultiDeviceInterceptor` هو الوحيد الذي يضيف `device_info` لطلب الدخول، وهو لا يُركَّب إلا عند `AppFeatures.multiDevice = true` — والافتراضي `false`.

فشاشة «الأجهزة» — عند تفعيلها — تعرض `User-Agent` الخام لـDio (`Dart/3.x (dart:io)`) لكل صفّ. الحلّ لا يستدعي تفعيل الموديول كله: إضافة `device_info` إلى `LoginRequestDto` مباشرةً تجعل الوسم يعمل دائماً، ويبقى الموديول مسؤولاً عن الشاشة فقط.

### 🟠 G6 — ادّعاء «إعادة الجلب عند الاستئناف» غير منفَّذ

[api_urls.dart:19](core/infra/network/rest/api_urls.dart#L19) يقول عن `/account/me`: «Re-fetched on resume، فتغيّر الحالة من جهة السيرفر يصل العميل بلا انتظار الدخول التالي».

`AppLifecycleService` مبني ومسجَّل، و`GetCurrentUserUseCase` موجود — **ولا رابط بينهما**. المستهلك الوحيد للـusecase هو `profile_screen`. الوثيقة تصف سلوكاً غير موجود.

---

## الجزء ٣ — توثيق خارج المزامنة

> `backend_template/CLAUDE.md` يفرض «Mandatory Documentation Sync». **الخرق واقع في الوثيقتين المرجعيتين نفسيهما.**

| الملف | ما يقوله | الواقع |
|---|---|---|
| `backend_template/docs/rest_api.md` | «لا يوجد `/login` بهذا الـskeleton بعد» · «لا يوجد أي feature module مبني بعد» · «لا يوجد Auth حقيقي — `auth.stub.ts` يقرأ الـheader ولا يتحقق» | 14 endpoint · موديولان · `core/middleware/auth.ts` يتحقّق فعلاً، و`auth.stub.ts` غير موجود |
| `backend_template/docs/architecture.md` | «`features/` فارغ حالياً» · يذكر `auth.stub` بشجرة الملفات | `features/auth` + `features/account` مبنيّان |

**لماذا هذا خطير أكثر من كونه إهمالاً:** `CLAUDE.md` يسمّي `docs/rest_api.md` «المرجع الوحيد الذي يُفحص عنده أي تغيير بالعقد». فمطوّر (أو وكيل) يتبع القاعدة حرفياً سيفتح ملفاً يخبره أن لا مصادقة هنا. **وهذا بالضبط ما يُنتج B1 و B2.**

### ملاحظات مرافقة

- **مراجع Qirtas متبقية** — 15 موضعاً بالفرونت + 19 ملفاً بالباك تذكر `features/identity` أو `/users/login` أو `/users/me`. أغلبها تعليقات تشرح «لماذا»، لكن بعضها يصف **العقد نفسه** (`current_user_model.dart`) فيضلّل مباشرةً.
- **`ApiUrls.users = '/users'`** — بقيّة ميتة بلا endpoint مقابل.
- **قانون المرآة مخروق** — `CLAUDE.md` يوجب أن يقابل كل تغيير في القالب control تفاعلي في `Features/test/`. أُضيفت **7 شاشات مصادقة** ولوحة `TestDashboardScreen` فيها 17 بطاقة، **ولا واحدة** تخصّ المصادقة أو الجلسات.
- **`readme/architecture.md`** لا يذكر شرائح `Features/auth/*` السبع.

---

## الجزء ٤ — جاهزية التشغيل والنشر

| البند | الحالة | الملاحظة |
|---|---|---|
| `Dockerfile` للتطبيق | ❌ غير موجود | `docker-compose.yml` يشغّل Postgres فقط. لا مسار نشر معرّف |
| `RateLimiter` | 🟠 بالذاكرة | موثَّق صراحةً: عملية واحدة فقط. **أول نشر بنسختين يُبطل كل حدود المحاولات** |
| `debugSkipLogin` | 🟠 `true` افتراضياً | مع `splash → TestDashboardRoute` عند غياب التوكن. أول build إنتاجي بلا تعديل يشحن لوحة الـdemo |
| `EMAIL_VERIFICATION_MODE` | ✅ `off` افتراضياً | قرار سليم — لا SMTP مطلوب للبدء |
| CI | ✅ بالمستودعَين | الباك 4 بوابات · الفرونت analyze + test + format |
| OpenAPI | ✅ كامل | 14 endpoint، Swagger على `/docs` مع تعديل CSP صحيح |
| Migrations | ✅ | `drizzle/0000_auth_baseline.sql` + سكربتات كاملة |
| `.env.example` | ✅ الباك | الفرونت: 3 ملفات flavor بعناوين `example.com` |

---

## الجزء ٥ — ما هو صحيح فعلاً (لا يُلمس)

يستحق التسجيل، لأن حجم القائمة أعلاه قد يُخفيه:

- **`POST /auth/refresh`** ↔ `TokenRefreshGatewayImpl` — يتطابقان تماماً (`data.token` + `data.rotated`). ومنطق «Dio عارٍ لتفادي إعادة الدخول للـinterceptor» صحيح ومعلَّل.
- **`GET/DELETE /auth/sessions`** ↔ `DeviceSessionModel` — تطابق كامل بالحقول السبعة. أُصلح في آخر commit (كان يضرب `/auth/devices` غير الموجود).
- **`POST /auth/verify-email`** ↔ `VerifiedAccountModel` — تطابق تام بالحقول الثلاثة، ومنطق الدمج (`applyTo`) لا الاستبدال صحيح.
- **الـenvelope** — `{status: bool, message, data}` / `{status: false, message, code, errors?, data?}` — متطابق ومحترَم بكل مكان.
- **`SafeCubit`** — يحلّ `emit after close` بلا شرط، ومثبَّت باختبار.
- **i18n مزدوج الاتجاه** — `req.lang` بالباك + `check:messages` بالـCI يمنع رسالة رفض إنجليزية لقارئ عربي. هذه أعلى من المتوسط بكثير.
- **CORS** — قائمة بيضاء صريحة بدل `cors()` المفتوح، مع تعليل صحيح لتمرير الطلبات بلا `Origin`.
- **فصل `core/auth` عن `features/account`** — الحدّ الصحيح: المحرّك ينتقل بين التطبيقات، والحساب ملك التطبيق.

---

## الجزء ٦ — خطة الإصلاح المقترحة

### P0 — قبل بناء أي تطبيق على القالب (يوم عمل واحد)

| # | الإجراء | الملف |
|---|---|---|
| 1 | **قرار العقد أولاً**: `account` أم `user`؟ التوصية — **توحيد الفرونت على `account`** (الباك هو مصدر الحقيقة وموثَّق بـOpenAPI) | قرار |
| 2 | إصلاح `json['user']` → `json['account']` | `login_model.dart:20` |
| 3 | `CurrentUserModel.fromJson` تقرأ الجذر مباشرةً (لا `['user']`) | `current_user_model.dart:19` |
| 4 | `MainShellRoute` → تسجيلها بالراوتر **أو** استبدالها بـ`HomeRoute` (وتوحيدها مع splash) | `router.dart` / `login_screen.dart:87` |
| 5 | مواءمة `AuthUser` مع `WireAccount` الفعلي: حذف `first_name`/`last_name`/`phone`/`is_admin` أو إضافتها لجدول `users` بالباك | `auth_user_model.dart` أو `users.schema.ts` |
| 6 | **اختبار وحدة واحد** لكل `fromJson` مقابل مثال OpenAPI حرفي — هذا ما يمنع تكرار 1–3 | `test/` |

### P1 — لاكتمال القالب كمنتج (أسبوع)

| # | الإجراء |
|---|---|
| 7 | **شريحة `Features/auth/register/`** كاملة + `RegisterRoute` + تفعيل رابط «ليس لديك حساب؟» |
| 8 | **إصلاح توثيق الباك**: `docs/rest_api.md` + `docs/architecture.md` — جدول الـ14 endpoint وشكل كل wire |
| 9 | **vitest + supertest بالباك** + إضافة `test` لبوابات الـCI. أولوية التغطية: `core/auth/services/*` |
| 10 | **feature CRUD مرجعية بالطرفين** تُثبت الـpagination والأخطاء على سلك حقيقي |
| 11 | `device_info` إلى `LoginRequestDto` مباشرةً — مستقلاً عن flag الـmultiDevice |
| 12 | **قانون المرآة**: بطاقة «Auth & Sessions» بلوحة `Features/test/` |

### P2 — تحسينات (حسب الحاجة)

| # | الإجراء |
|---|---|
| 13 | `Dockerfile` متعدد المراحل + خدمة `api` بـ`docker-compose.yml` |
| 14 | `SecurityEventSink` افتراضي يكتب إلى `pino` |
| 15 | ربط `AppLifecycleService` بـ`GetCurrentUserUseCase` — أو حذف الادّعاء من التوثيق |
| 16 | تنظيف مراجع Qirtas التي تصف **العقد** (لا تلك التي تشرح «لماذا») |
| 17 | حذف `ApiUrls.users` · مراجعة `debugSkipLogin` كافتراضي |
| 18 | Redis خلف `RateLimiter` — أو توثيق حدّ «نسخة واحدة» في دليل النشر |

---

## الدرس البنيوي

الأعطال الخمسة القاطعة كلها من **نوع واحد**: العميل والخادم يصفان نفس الحقيقة بمفاتيح مختلفة، ولا شيء في المستودعَين يفحص ذلك.

- `dart analyze` يمرّ — الأنواع سليمة، المفتاح الخاطئ يبقى `dynamic`.
- `tsc --noEmit` يمرّ — الباك لا يعرف بوجود عميل.
- الـCI بالطرفين خضراء.
- والـenvelope يُغلّف الخطأ فيصل كـ«200 OK» ورسالة عامّة.

**الاستنتاج:** بند P0 رقم 6 (اختبار `fromJson` مقابل مثال OpenAPI) ليس بند جودة — هو **الفحص الوحيد الذي يجعل هذه الفئة من الأعطال مستحيلة**. والباك يملك أصلاً `openapi.json` كامل، فالمادة الخام للفحص موجودة ولم تُستعمل.

وبعبارة القالب نفسه، المكتوبة في `.github/workflows/ci.yml` بالباك:

> **قاعدة مكتوبة بلا فحص هي اقتراح.**

---

## الملفات المرجعية

| ما تريده | اقرأ |
|---|---|
| عقد REST المقصود | `backend_template/docs/rest_api.md` ⚠️ خارج المزامنة |
| العقد الفعلي | `GET /openapi.json` أو `/docs` (Swagger) |
| قواعد محرّك المصادقة | `backend_template/src/core/auth/CLAUDE.md` |
| نمط بناء feature (فرونت) | `app_template/lib/Features/CLAUDE.md` |
| نمط بناء feature (باك) | `backend_template/src/features/CLAUDE.md` |
| اقتراحات تطوير القالب | [template_enhancements.md](template_enhancements.md) |
