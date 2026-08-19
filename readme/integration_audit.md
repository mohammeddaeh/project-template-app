# تدقيق التكامل — القالب كاملاً (Flutter + Node)

> **التدقيق:** 2026-08-11 · **الإصلاح:** 2026-08-12 — كل بنود P0 و P1 و P2 مُنفَّذة.
> **النطاق:** `app_template/lib/**` + `backend_template/src/**` + وثائق المستودعَين.

---

## الحالة

| المحور | قبل | بعد |
|---|---|---|
| عقد الـwire | 🔴 5 أعطال قاطعة | ✅ مُصلَح ومُثبَّت باختبارات الطرفين |
| دورة الحساب | 🟠 لا تسجيل حساب | ✅ `Features/auth/register/` كاملة |
| اختبارات الباك | 🔴 صفر | ✅ 51 وحدة/عقد + 22 تكامل + بوابة CI |
| اختبارات الفرونت | 🟠 4 (بلا تغطية للعقد) | ✅ 34 — منها 11 عقد wire + 3 عقد routes |
| feature CRUD مرجعية | 🔴 غير موجودة | ✅ `notes` بالطرفين — التصفّح مُثبت على سلك حقيقي |
| توثيق الباك | 🔴 خارج المزامنة | ✅ مُزامَن — 19 endpoint موثَّقة |
| قانون المرآة | 🔴 مخروق | ✅ بطاقتان حيّتان بلوحة `Features/test/` |
| حدود المحاولات | 🟠 بالذاكرة، تنهار بنسختين | ✅ مخزن قابل للتبديل + `TRUST_PROXY` |
| السجلّ الأمني | 🟠 يُهمَل صمتاً | ✅ افتراضي يكتب إلى `pino` |
| مسار النشر | 🔴 غير موجود | ✅ `Dockerfile` مبنيّ ومُشغَّل ومُختبَر |

**19 endpoint · 107 اختباراً · `dart analyze` و`tsc` و`eslint` و`check:messages` كلها نظيفة.**

---

## الجزء ١ — الأعطال القاطعة (كانت تمنع أول تطبيق من العمل)

### ✅ B1 — `POST /account/login`: `data.user` مقابل `data.account`

**كان:** [login_model.dart](../lib/Features/auth/login/data/models/login_model.dart) يقرأ `json['user']` والباك يرسل `account`. الـcast لـ`null` يرمي `TypeError`، و`HandleBodyResponse` يبتلعه ويحوّله `Failure` عامّة.

**الأثر الفعلي:** السيرفر يجيب `200 OK` وينشئ جلسة حقيقية وصفّاً بقاعدة البيانات، والشاشة تعرض «حدث خطأ». أسوأ شكل عطل ممكن.

**الآن:** يقرأ `json['account']`، ويلتقط `session_id` الذي كان يُهمَل. مُثبَّت بـ`wire_contract_test.dart` الذي يؤكّد صراحةً غياب مفتاح `user`.

### ✅ B2 — `GET /account/me`: مستوى تداخل زائد

**كان:** `CurrentUserModel` يقرأ `json['user']` والباك يضع الحساب **بجذر `data`**.

**الآن:** `currentUserFromJson()` تقرأ الجذر مباشرةً. و`MeRepositoryImpl` صار ينشر النتيجة على `CurrentUserRepository` بنفسه — فمستدعٍ يجلب `/me` بلا نشر كان سيترك كل المستمعين على سجلٍّ دحضه للتوّ.

### ✅ B3 — `MainShellRoute` غير مسجَّلة بالراوتر

**كان:** `login_screen.dart` ينتقل إليها و`router.dart` لا يسجّلها. `auto_route` يولّد الـclass لكل `@RoutePage()` بغضّ النظر عن شجرة الراوتر، فالكود يُترجم نظيفاً ويفشل **وقت التشغيل** على أكثر انتقال يقوم به كل مستخدم.

**الآن:** مسجَّلة على `/app`، و`splash` و`login` يتّفقان عليها. `router_contract_test.dart` يفحص أن **كل** وجهة يُنتقل إليها بـ`lib/` مسجَّلة فعلاً.

**وأُصلح معها**: `splash` عند غياب التوكن كان يذهب لـ`TestDashboardRoute` (لوحة الـdemo) بدل `LoginRoute` — فبناء إنتاجي بلا `debugSkipLogin` كان يشحن المستخدمين إلى شاشات التجربة.

### ✅ B4 — `AuthUser` يتوقّع حقولاً لا يرسلها الباك

**كان:** 15 حقلاً مقابل 7. ثمانية منها (`first_name`, `last_name`, `phone`, `image`, `address`, `is_admin`, `mfa_enabled`, `rejection_reason`) **لم يرسلها أي endpoint قط** — فكانت فارغة على كل حساب، إلى الأبد.

**الآن:** سبعة حقول تطابق `WireAccount` حرفاً بحرف. و`AuthUserStatus` قُلِّم من ست قيم إلى **الثلاث التي يشحنها `userStatusEnum`** فعلاً. `ProfileScreen` أُعيدت كتابته على الحقول الموجودة + سحب-للتحديث.

> **الاتجاه صار مُلزَماً**: إضافة حقل = عمود بالباك أولاً، ثم `WireAccount`، ثم هنا. والاختبار يحمرّ حتى يتّفق النصفان.

### ✅ B5 — `permission_keys` / `is_super_admin`: عقد لطرف واحد

**كان:** الفرونت يقرأهما ويخزّنهما ويعرض `hasPermission()`. الباك لا يرسل أياً منهما ويعلن RBAC خارج نطاقه صراحةً.

**الأثر:** `hasPermission()` تُجيب `false` لكل مفتاح على كل استدعاء. **بوّابة مغلقة دائماً تُقرأ بالكود تماماً كبوّابة تعمل** — شاشة تخفي زرّاً خلفها كانت ستخفيه للأبد، صحيحةً بالكود وخاطئةً بالقصد.

**الآن:** حُذفا من `LoginEntity` و`CurrentUserRepository` و`PersistenceKeys`، مع توثيق الاتجاه الصحيح عند إضافة RBAC: **السيرفر يصدر الادّعاءات أولاً**.

**وقد أُضيف RBAC بهذا الترتيب فعلاً** — `core/authz/` بالباك أولاً (`requirePermission` + `/authz/me` + `/authz/catalog`)، ثم `modules/access_control/` هنا. والدرس نفسه مبنيّ في الموديول الجديد كحاجز لا كتعليق: بناء التطوير يطلب `?include_declared=true` فيحمل قائمة كل مفتاح يعلنه الخادم، وأي `Can(permission: …)` بمفتاح خارجها يُصدر `LogService.error` + `assert`. راجع [`permissions.md`](permissions.md).

**عقد الـwire الجديد:** `test/fixtures/wire/authz_me.json` · `authz_catalog.json` · `authz_user_access.json` — يقابلها `src/core/authz/__tests__/wire-contract.test.ts`. خطأ المفتاح هنا أخطر منه في أي payload آخر: مجموعة صلاحيات تُحلَّل إلى فارغة لا تُميَّز عن حساب لا يملك شيئاً حقاً.

---

## الجزء ٢ — الفجوات الوظيفية

### ✅ G1 — شريحة `register/` كاملة

12 ملفاً بنمط `login/`: DTO · datasource · repository · use case · cubit بـfreezed · شاشة. مربوطة بـ`RegisterRoute` وبرابط حيّ من شاشة الدخول (كان النصّ «ليس لديك حساب؟» معلّقاً بلا زر).

**قرارات موثَّقة داخلها**: التسجيل يُعيد الحساب **بلا توكن**، فلا يمكن أن يهبط داخل التطبيق — الوجهة `LoginRoute` بالحالتين. و`RegisterRepositoryImpl` لا يمسّ `SessionRepository` ولا `CurrentUserRepository`: كتابة الحساب بلا جلسة كانت ستجعل `currentUser` غير فارغ لمن ليس داخلاً.

### ✅ G2 — اختبارات الباك: من صفر إلى 49

| الملف | يُثبت |
|---|---|
| `features/account/__tests__/wire-contract.test.ts` | مفاتيح `WireAccount` السبعة · غياب `password_hash` · `account` لا `user` · تطبيع البريد · السياسة تُطبَّق عند **تعيين** كلمة المرور لا عند فحصها |
| `features/auth/__tests__/refusal-shapes.test.ts` | 403 بـ`data.account_status` · 422 لا 401 لكلمة مرور حالية خاطئة · `Retry-After` بالثواني · `WireSession` بلا توكن ولا IP · قبول التهجئة القديمة `token` |
| `features/notes/__tests__/wire-contract.test.ts` | غلاف التصفّح · `total_pages` لا يساوي صفراً أبداً · الافتراضيات تطابق `PaginationQuery` بالفرونت |
| `core/auth/__tests__/password-policy.test.ts` | الطول والحرف والرقم · **لا رمز ولا حالة مختلطة عمداً** · التمليح · `verifyPassword` تُجيب false لا ترمي |
| `core/auth/__tests__/rate-limiter.test.ts` | العدّ · استقلال المفاتيح · انتهاء النافذة · `reset()` · الكنس |
| `features/notes/__tests__/notes.int.test.ts` | **تكامل**: الغلاف على السلك · CRUD كاملة · **حصر المِلكية** · `requireAuth` قبل `validate` |

**سويتان بحدٍّ واضح**: الوحدة/العقد بلا قاعدة بيانات (تُشغَّل بالـCI)، والتكامل يحتاج Postgres (خارج الـCI عمداً — CI القالب يجب أن يكون أخضر على نسخة جديدة بلا تجهيز).

> **اكتشاف جانبي**: `env.ts` يستدعي `process.exit(1)` وقت تحميل الموديول، فأي اختبار وحدة يلمس DTO يموت الـrunner عنده أثناء الجمع. الحلّ `src/core/config/test-env.ts` كـ`setupFiles` — **لا** تخفيف `env.ts`، فالفشل الصاخب عند الإقلاع هو ما يجعل تصميمه صحيحاً.

### ✅ G3 — `notes`: الـfeature المرجعية بالطرفين

**الباك** (5 endpoints): جدول + migration `0001` + repository يحصر المِلكية **داخل `WHERE`** لا بفحص بعد القراءة + service + controller + routes + OpenAPI.

**الفرونت** (14 ملفاً): entity · models · DTO · datasource · repository · 3 use cases · `NotesListCubit extends PaginationCubit` · `NoteFormCubit` بـfreezed · شاشتان.

**ما تُثبته فعلاً**: شكل التصفّح `{items, page, limit, total, total_pages}` كان موثَّقاً بـ`rest_api.md`، ومبنيّاً بـ`core/pagination/pagination.ts`، ومنعكساً بـ`PaginationCubit` و`PaginationBuilderWdg` — **ولم يُولَّد ولم يُحلَّل ولا مرّة واحدة**. صار الآن مُولَّداً ومُحلَّلاً ومُثبَّتاً عند الطرفين.

**قرارات تستحق النسخ**: 404 لملاحظة غيرك مطابقة تماماً للمعدومة · PATCH فارغ يجيب 422 لا 200 صامتة · حذف المحذوف يجيب 404 لأن قائمتك قديمة · `ORDER BY` صريح لأن غيابه يجعل `prependItem` يبدو خطأً بالفرونت وسببه بالاستعلام.

#### ⛓️ تغيير عقد مقصود — 2026-08-17 (المرحلة P1 من [`lib/modules/sync/PLAN.md`](../lib/modules/sync/PLAN.md))

**`WireNote` تغيّر، وهذا أول كسر عقدٍ متعمَّد بهذا المستودع.** كان
`{id, title, body, created_at, updated_at}` بـ`id` عدداً تسلسلياً، وصار
`{id, title, body, created_at, updated_at, version, is_deleted}` بـ`id` **uuid**.

**لماذا لم يكن هناك بديل**: صفٌّ يُنشأ دون اتصال يجب أن يملك هوية **لحظة إنشائه** —
يُعرض ويُعدَّل وقد يُحذف قبل أن يراه خادم. ومعرّفٌ يمنحه الخادم لاحقاً يعني ترقيع كل
إشارة محلية إليه بأثر رجعي.

**النصفان تحرّكا معاً**، وهذا بالضبط ما تفرضه §عقد الـwire بـ`CLAUDE.md`:

| الطرف | ما تغيّر |
|---|---|
| الباك | `notes.schema.ts` · الهجرة `0005` (**يدوية** — انظر أدناه) · DTO · repository · service · controller · routes · OpenAPI · `notes.transfer.ts` |
| الفرونت | `NoteModel` · `Note` · `note_params` · retrofit · `NotesListCubit` · `NoteFormCubit` |
| العقد | `wire-contract.test.ts` (22 حالة) · `note.json` · `notes_page.json` · `wire_contract_test.dart` (4 حالات جديدة) |

**والفخّ الذي كاد يمرّ**: `drizzle-kit generate` أنتج
`ALTER TABLE notes ALTER COLUMN id SET DATA TYPE uuid`. Postgres **لا يملك تحويلاً**
من `integer` إلى `uuid` — لا ضمنياً ولا صريحاً. فالهجرة كانت ستفشل عند أول
`db:migrate` في **كل بيئة**، ولا `tsc` ولا `vitest` ولا مراجعةٌ للمخطَّط تراها،
لأن المخطَّط النهائي صحيح تماماً؛ الخطأ في الطريق إليه وحده. الهجرة الآن يدوية
وتشرح ما يحلّ بالمعرّفات القديمة.

**وأُضيف `core/idempotency/`** — جدول ومستودع وmiddleware يخدم كل مورد لا `notes`
وحدها: كتابةٌ تُعاد بنفس المفتاح تُستردّ ردَّها الأول حرفياً بدل أن تصير صفّاً ثانياً.
وهذا العطل — مضاعفات تصل من نفقٍ رديء — أكثر أعطال المزامنة شيوعاً وأقلّها ظهوراً:
الطلبان صحيحان، وكلاهما نجح، ولا سطر في أي سجلّ.

### ✅ G4 — `device_info` مستقلاً عن أي flag

**كان:** يُضاف داخل `MultiDeviceInterceptor` الذي لا يُركَّب إلا عند `AppFeatures.multiDevice = true` — والافتراضي `false`. فكل جلسة يفتحها بناء افتراضي تُوسم بـ`User-Agent` الخام لـDio.

**الآن:** `core/platform/device/device_label_service.dart` و`AuthRemoteDataSource` يُلحقه دائماً. الموديول يحكم **الشاشة** لا السلك.

### ✅ G5 — «إعادة الجلب عند الاستئناف» صارت حقيقية

`api_urls.dart` كان يصف `/account/me` بأنه «يُعاد جلبه عند الاستئناف» — و`AppLifecycleService` موجود و`GetCurrentUserUseCase` موجود و**لا رابط بينهما**. حساب يُعطِّله مسؤول كان يظلّ يعمل على الجهاز حتى ينتهي توكنه.

`SessionSyncService` الآن: مرّة عند الإقلاع + عند كل عودة للمقدّمة، بحدٍّ أدنى دقيقة بين نداءين (الاستئناف يُطلَق لأسباب كثيرة — نافذة أذونات، ورقة مشاركة، كاميرا).

**وأُصلح معه**: `SplashCubit` لم يكن يستدعي `restoreFromCache()` رغم أن التوثيق يقول ذلك — فكانت الشاشات تظهر فارغة بعد كل إقلاع رغم صلاحية التوكن. و`_handleAuthEvent` بـ`app.dart` كان يوجّه لـ`SplashRoute` (فيعيد فحص التوكن الذي فشل للتوّ) بدل `LoginRoute`.

---

## الجزء ٣ — التوثيق

| الملف | كان يقول | صار |
|---|---|---|
| `backend_template/docs/rest_api.md` | «لا يوجد `/login`» · «لا feature module مبني» · «`auth.stub.ts` لا يتحقق» | 19 endpoint بثلاثة جداول + أشكال الـwire الثلاثة + تحذير صريح عن `account` مقابل `user` |
| `backend_template/docs/architecture.md` | «`features/` فارغ حالياً» | الشجرة الحقيقية + دورة الطلب بالـmiddleware الفعلي + جدول طبقتَي الاختبار |
| `backend_template/docs/scripts.md` | بلا قسم اختبارات | `npm test` / `test:int` + سبب الفصل |
| `backend_template/CLAUDE.md` | جدول القرار يشير لملف متقادم | §عقد الـwire الإلزامي + §الاختبارات + `notes` بجدول Modules |
| `app_template/CLAUDE.md` | «لا يوجد auth feature مبني بعد» | جدول Features الحقيقي + §عقد الـwire |
| `app_template/lib/Features/CLAUDE.md` | «`register/` لم تُشحن عمداً» | الشجرة الكاملة + §عقد الـwire بخطواته الثلاث |

**قانون المرآة**: بطاقتان جديدتان بلوحة `Features/test/` — «المصادقة والجلسات» و«الملاحظات (CRUD حيّ)» — وهما **البطاقتان الوحيدتان اللتان تضربان الشبكة فعلاً**، فتفشلان كما تفشل أي شاشة حقيقية عند خطأ `Env.baseUrl`.

**بقايا مُنظَّفة**: `ApiUrls.users = '/users'` (بلا مستهلك) · `test/widget_test.dart` (كان يختبر تطبيق الـdemo لحزمة `shimmer` لا هذا المشروع) · تعليقات تصف عقوداً بأسماء endpoints من مشروع آخر.

---

## الجزء ٤ — P2: جاهزية النشر (نُفِّذت 2026-08-12)

### ✅ P2-13 — `Dockerfile` + خدمة `api`

ثلاث مراحل (deps · build · runtime). **مبنيّة ومُشغَّلة ومُختبَرة فعلاً**: `/health` أجاب، ودخول بكلمة مرور خاطئة أجاب 401 بالعربية، والحاوية بلغت `healthy`.

| القرار | لماذا |
|---|---|
| `CMD ["node","dist/index.js"]` لا `npm start` | npm **لا يمرّر SIGTERM** — الإغلاق السلس لا يعمل وكل نشر يقطع الطلبات الجارية |
| `USER node` | عملية تقرأ كودها وتكلّم Postgres لا تحتاج الكتابة على صورتها |
| `.dockerignore` يستثني `.env` أولاً | بدونه يُنسخ ملف أسرارك داخل الصورة ويشحن لكل من يسحبها |
| `depends_on: service_healthy` | Postgres يقبل TCP قبل أن يقبل استعلاماً بثوانٍ، و`env.ts` يُنهي العملية عند فشل الإقلاع |
| خدمة `api` خلف `profile` | `docker compose up -d` يبقى المسار السريع — تشغيل القاعدة لا يستدعي بناء صورة |

### ✅ P2-14 — `SecurityEventSink` افتراضي

كان الافتراضي **الإهمال الصامت**: 15 حدثاً تُصدر وتُرمى، ومحاولة تخمين لا تترك أثراً. الافتراضي الآن `LogSecurityEventSink` — الفشل بـ`warn`، فـ`level>=40 AND event LIKE 'auth.%'` استعلام صالح من اليوم الأول.

مُثبَت في الحاوية:
```json
{"level":40,"event":"auth.login.failed","account_id":null,
 "email":"docker-probe@example.test","ip":"::ffff:172.19.0.1","device":"curl/8.18.0"}
```

اللوج ليس سجلّ تدقيق (يدور، ولا يُستعلم بعد شهر) — لكنه الفرق بين ثغرة تُلاحَظ وثغرة لا تُلاحَظ.

### ✅ P2-18 — حدود المحاولات عبر النسخ

**بلا Redis وبلا تبعية واحدة.** `RateLimitStore` منفذ بثلاث دوال:

```
RateLimitStore ← MemoryRateLimitStore    (افتراضي — Map بالعملية)
               ← PostgresRateLimitStore  (جدول rate_limits — migration 0002)
```

`RATE_LIMIT_STORE=postgres` يجعل العدّادات مشتركة وتنجو من إعادة التشغيل. المشروع يشغّل Postgres أصلاً، وبنية تحتية ثانية لعدّ محاولات دخول ثمنٌ لا يستحقه معظم النشر.

**والتنفيذ بعبارة SQL واحدة** (`INSERT … ON CONFLICT DO UPDATE`): القراءة والقرار والكتابة ذرّياً. البديهي (اقرأ ← قرّر ← اكتب) مكسور بالضبط بالسيناريو الذي وُجد الحدّ لأجله — محاولتان متزامنتان تقرآن «4» وتمرّان معاً. مُثبَت باختبار يُطلق 10 نداءات متوازية ويتحقق أن الأعداد 1..10 بلا فقد.

### ✅ P2 (إضافي) — `TRUST_PROXY`

كان تحذيراً بتعليق. صار متغيّر بيئة. خلف موزّع بلا ضبطه: `req.ip` يصير عنوان الموزِّع، فيقع كل المستخدمين بسلّة واحدة والمحاولة السادسة **من أي شخص** تُرفض — عطل على مستخدميك الحقيقيين والمهاجم غير متأثر.

عدد قفزات لا `true`: الوثوق بسلسلة `X-Forwarded-For` كاملةً يجعل المتصل يُقدّم أي عنوان ويختار سلّته.

### 🔴 وعطل حقيقي كشفته هذه الجولة

تحويل حدود المحاولات إلى async استدعى لفّها بـ`asyncHandler` — **وهو لا يستدعي `next()`**، لأنه للـcontrollers الطرفية. النتيجة: **كل endpoint محميّ توقّف عن الردّ نهائياً.**

`tsc` مرّ · `eslint` مرّ · 51 اختبار وحدة مرّت.

الشيء الوحيد الذي رآه: اختبار تكامل يُرسل طلباً حقيقياً وينتظر جواباً. الحلّ `asyncMiddleware` — guard **لا يُعطى `next` أصلاً**، فلا يمكنه نسيانها.

---

## الجزء ٥ — الاستيراد/التصدير: الاستثناء الوحيد المسموح عن المغلّف (أُضيف 2026-08-12)

`modules/data_transfer/` ↔ `backend_template/src/core/data-transfer/`.

`GET /data-transfer/:resource/export` و`/template` يردّان **بايتات ملف**، لا `{status, message, data}`. وهذا أول وأخير خرقٍ للمغلّف في هذا القالب — وقد أُدخل بعينٍ مفتوحة على أنه **إعادة إنتاجٌ محتمل لعطل B1 نفسه**:

> `HandleBodyResponse` يحلّل كل جسم كـJSON. توجيهه إلى CSV يرمي `FormatException` → يُلتقط → يُحوَّل إلى `Failure` → يقرأ المستخدم «حدث خطأ»، **بينما السيرفر سجّل `200 OK` وأرفق ملفاً سليماً**. لا `dart analyze` يراه، ولا `tsc`، ولا الـCI.

**الحاجز البنيوي المُتّخذ** — لا تعليق تحذيري، ولا علَم على الـrepository:

| القرار | الأثر |
|---|---|
| صنف مستقل باسم صريح `TransferFileDownloader` | لا يمكن بلوغ مسار البايتات بالخطأ، ولا مسار الـJSON بالخطأ |
| الأخطاء تظل بالمغلّف، وكلها **قبل أول بايت** | سطر الحالة وحده يفرّق بين الشكلين؛ لا استجابة تبدأ ملفاً وتنتهي خطأً |
| فكّ جسم الخطأ من البايتات (`_messageFromBytes`) | 413 يصل كـ«42 000 صف — الحد 50 000»، لا «فشل التنزيل» |
| ثلاث fixtures + 12 حالة عقد بالطرفين | `transfer_resources.json` · `import_report.json` · `import_result.json` |

**فخّان إضافيان مُغطَّيان باختبارات**، وكلاهما يفشل بصمت لا بخطأ:

1. **`row` مقابل سطر الجدول.** السيرفر يعدّ صفوف البيانات من 1؛ عدّاد Excel يعدّ الرأس سطراً 1. `ImportRowError.spreadsheetLine` يضيف الإزاحة — بدونه كل إشارة خطأ تذهب للسطر الخطأ، لكل مستخدم، بلا أي فشل مرئي.
2. **`token: null` مقابل مفتاح غائب.** السيرفر يحجب الـtoken حين لا يصلح أي صفّ. تعويض المفقود بـ`''` يضع زرّ تأكيد مفعّلاً على شاشة لا شيء فيها للاستيراد، ويردّ الـcommit `inserted: 0` كنجاح.

> **BOM الـCSV** ليس مسألة عميل، لكنه من العائلة ذاتها: بدون `﻿` يفتح كل تصدير عربي بـExcel كـ`Ø§Ù„Ø¹Ù†ÙˆØ§Ù†`، **ولا شيء بالسيرفر يبلّغ** — الاستجابة UTF-8 صحيحة تماماً. يفرضه اختبار وحدة بالباك.

التفاصيل: [`data_transfer.md`](data_transfer.md) · `backend_template/docs/rest_api.md` §data-transfer.

---

## الجزء ٦ — ما بقي فعلاً

| البند | ملاحظة |
|---|---|
| `AppFeatures.debugSkipLogin = true` افتراضياً | مقصود للتجربة، يستحق قراراً قبل أول إصدار |
| ترقية `dart format` لبوابة | 137 من 327 ملفاً غير منسَّقة؛ تحتاج commit تنسيق منفصلاً |
| `.env.example.json` بالفرونت | يشير إلى `api.example.com` — يحتاج عنوانك |
| `RedisRateLimitStore` | المنفذ جاهز؛ ملف واحد إن احتجت أداء أعلى من Postgres |

---

## الدرس البنيوي

الأعطال الخمسة القاطعة كانت كلها من **نوع واحد**: العميل والخادم يصفان نفس الحقيقة بمفاتيح مختلفة، ولا شيء في المستودعَين يفحص ذلك.

- `dart analyze` يمرّ — مفتاح غائب يساوي `null`، و`null` نوعٌ `dynamic` سليم.
- `tsc --noEmit` يمرّ — الباك لا يعرف بوجود عميل.
- الـCI بالطرفين خضراء.
- والـenvelope يُغلّف الاستثناء فيصل كـ«200 OK» ورسالة عامّة.

**الإصلاح البنيوي ليس تصحيح المفاتيح** — بل `test/fixtures/wire/*.json` عند الطرفين: ملفات JSON واحدة، يحلّلها الفرونت بمحلّلاته الحقيقية، ويؤكّد الباك مجموعة مفاتيحها بـzod schemas نفسها. تغيير مفتاح بجانب واحد يُحمِّر الطرف الآخر.

وبعبارة `.github/workflows/ci.yml` بالباك، المكتوبة قبل هذا التدقيق بشهر:

> **قاعدة مكتوبة بلا فحص هي اقتراح.**

---

## الملفات المرجعية

| ما تريده | اقرأ |
|---|---|
| العقد القاطع | `GET /openapi.json` أو `/docs` (Swagger) |
| شرحه النصّي | `backend_template/docs/rest_api.md` |
| قواعد محرّك المصادقة | `backend_template/src/core/auth/CLAUDE.md` |
| نمط بناء feature (فرونت) | `app_template/lib/Features/CLAUDE.md` |
| نمط بناء feature (باك) | `backend_template/src/features/CLAUDE.md` |
| اقتراحات تطوير القالب | [template_enhancements.md](template_enhancements.md) |
