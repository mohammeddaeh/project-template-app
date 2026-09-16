# CLAUDE.md — Flutter Base Template

> **هذا الملف slim — التفاصيل في CLAUDE.md الفرعية داخل lib/.**
> `.cursor/` لا يؤثر على Claude Code — يُقرأ CLAUDE.md فقط.

---

## 🗂️ جدول القرار

| إذا كنت تبني… | اقرأ |
|---|---|
| **Feature** (CRUD/Form/Nav/Widget) | `lib/features/CLAUDE.md` |
| **REST endpoint** جديد | `lib/core/CLAUDE.md` → §API |
| **core/** أو **DI** | `lib/core/CLAUDE.md` |
| **imports / UI rules / localization** | `lib/CLAUDE.md` |
| **أي شيء في lib/** | `lib/CLAUDE.md` أولاً دائماً |
| **صفحة من الفيغما** (سحبٌ أو لصق) | [`readme/05_FIGMA_TO_PAGE.md`](readme/05_FIGMA_TO_PAGE.md) — إلزامي قبل أي سطر |
| **مقاسُ شاشة · لوح · كيبورد · تكبير خط** | [`readme/22_RESPONSIVE.md`](readme/22_RESPONSIVE.md) — `context.screen`، ولا نسبةَ من ارتفاع الشاشة |
| **إقلاع التطبيق · شاشة البدء · شعارُها** | [`readme/23_STARTUP_SPLASH.md`](readme/23_STARTUP_SPLASH.md) — ⛔ **و`android: false` بـ`flutter_native_splash.yaml` بقرار**: موردا أندرويد متجهان باليد، وإعادةُ التوليد تمحوهما |

**وللمرجع البشري** — تفتحه حين تحتاج «لماذا» أو أمراً نسيته:

| تحتاج | افتح |
|---|---|
| **أوّل يوم بالقالب** | [`readme/00_START_HERE.md`](readme/00_START_HERE.md) |
| تجهيزَ جهازك · جعلَ القالب مشروعك | [`readme/01_SETUP.md`](readme/01_SETUP.md) |
| أمراً · مسار import · خطوة | [`readme/02_CHEATSHEET.md`](readme/02_CHEATSHEET.md) |
| القواعد الصارمة بأسبابها | [`readme/03_RULES.md`](readme/03_RULES.md) |
| بناء feature كاملة خطوة بخطوة | [`readme/04_FIRST_FEATURE.md`](readme/04_FIRST_FEATURE.md) |
| الفهرس الكامل | [`readme/README.md`](readme/README.md) |

### Features الموجودة

> **القالب نُظِّف من كل feature تطبيقية (2026-09-08).** ما تبقى هو البنية التحتية
> وحدها. **لا مثال CRUD ولا شاشات demo** — أول feature يكتبها المشروع هي أول
> feature تطبيقية بالمستودع، وتُبنى من `readme/00_START_HERE.md` لا بالنسخ من
> شريحة قائمة. والمحذوف: `features/notes/` (٢٣ ملفاً) · `features/test/` (٢٢ شاشة
> demo) · معرض الودجات · ٢٦٣ مفتاح ترجمة · ٥ مفاتيح صلاحيات · ٣ اختبارات مزامنة.
>
> ⚠️ **ومفاتيح `notes.*` الخمسة قد تعود بـ`permissions.lock.json`** رغم هذا
> الحذف — لأن `backend_template` لا يزال يستخدمها كمثالٍ مرجعي بـwire-contract
> تخصّ `authz` (`test/wire_contract_test.dart` يستشهد بـ`notes.update` صراحةً).
> **هذا توليدٌ صحيح لا انحرافاً**: الملف مولَّدٌ من الباك، لا مصدر حقيقة مستقلاً.


| المسار | ما تفعله |
|---|---|
| `features/auth/` | **دورة الحساب كاملة** — login · register · logout · me · verify_email · forgot_password · change_password · profile. مقابل `/api/v1/account` و`/api/v1/auth` بالباك |
| `features/home/` | التنقل الرئيسي — و`home_screen.dart` **placeholder مقصود** يُستبدل جسدُه كاملاً. وفيه `WelcomeAnnouncer` بالقشرة: يستقبل الداخلَ حديثاً بتحيّةٍ باسمه، ويقرأ علَم `WelcomeGreeting` مرّةً واحدة (`take` تمحو). ⛔ **ولا رافعَ للراية بالقالب** — `raise()` تُنادى ممّن يعرف «متى صار الحساب جاهزاً» |
| `features/settings/` | Theme + Language + Notifications + Version + Cache |
| `features/startup/` | **قرارُ أوّل شاشة — بلا شاشةٍ له.** يُنادى من `main()` قبل `runApp`: يسأل `DataOriginGuard` هل أصلُ ما على الجهاز هو `Env.baseUrl`، ثم يستعيد التوكن **واللقطة المخزَّنة للمستخدم**. ⛔ **ولا `SplashScreen`**: أوّلُ إطارٍ يرسمه فلاتر هو الوجهةُ نفسُها، فلا يرى المستخدم شعارَين — راجع [`readme/23_STARTUP_SPLASH.md`](readme/23_STARTUP_SPLASH.md) |

### Modules الاختيارية البارزة

| المسار | ما تفعله |
|---|---|
| `modules/data_transfer/` | **استيراد/تصدير عام — صفر Dart لكل feature.** الشاشتان تُبنيان من `GET /data-transfer/resources`، فـfeature تُعلن قابليتها بالباك تظهر بنسخة مبنية قبل وجودها. سطر الدخول: `DataTransferSheet.show(context, resource: 'notes')` — **و`'notes'` هنا اسمُ مورد بالباك لا feature بالمستودع**. علَم: `AppFeatures.dataTransfer`. ⚠️ `/export` يردّ **بايتات لا مغلّفاً** — راجع `readme/32_MODULE_DATA_TRANSFER.md` |
| `modules/access_control/` | **صلاحيات عامة — صفر Dart لكل صلاحية.** المفتاح يُعلَن في السطر الذي يحميه بالباك (`requirePermission('notes.update')`)، ويُلمّ تلقائياً، فتظهر بطاقته في شاشة الأدوار المبنيّة من `GET /authz/catalog`. سطر الدخول: `Can(permission: PermKeys.notesDelete, child: …)` — **والمفتاح لا يُكتب نصّاً خاماً أبداً**: `PermKeys` مولَّد من `permissions.lock.json`، فمفتاحٌ يحذفه الباك يكسر البناء بدل أن يُخفي زرّاً للأبد بصمت. علَم: `AppFeatures.accessControl` + `AUTHZ_ENABLED` بالباك. ⚠️ **بوابة العميل ليست حدّ الأمان** — راجع `readme/31_MODULE_PERMISSIONS.md` |
| `modules/multi_device/` | الأجهزة والجلسات النشطة. علَم: `AppFeatures.multiDevice` |
| `modules/sync/` | محرّك المزامنة دون اتصال. علَم: `AppFeatures.offlineSync`. يدفع ويسحب — ⚠️ **وبلا محوّل feature واحد بعد تنظيف 2026-09-08**: `getAll<SyncFeatureContractBase>()` يجد صفراً، فتشغيلُ العلَم يترك التطبيق يعمل بالكامل على الشبكة **بلا انهيار ولا تحذير**. **المرفقات مبنيّة** (تخزين خاص · `Range` · checksum · Cache Manager). ⚠️ بلا Manifest ولا حصّة ولا خلفية. اقرأ [`lib/modules/sync/PLAN.md`](lib/modules/sync/PLAN.md) قبل البناء عليه |

---

## lib/ Top-Level Structure

```
lib/
├── core/         ← shared infrastructure
│   ├── foundation/  ← Pure Dart only
│   ├── platform/    ← Flutter/OS wrappers
│   ├── infra/       ← Implementation + network + errors
│   └── di/          ← Composition root
├── modules/      ← optional bounded runtime modules
├── features/     ← feature slices
├── ui/           ← the whole shared UI layer
│   ├── widgets/     ← widget library (barrel: widgets.dart)
│   ├── theme/       ← colors, fonts, theme
│   ├── state/       ← shared UI cubits: pagination · refresh · sync · connectivity
│   ├── error/       ← FailureUiMapper · UiAction · ErrorView
│   ├── feedback/    ← context.feedback.*
│   ├── locale/      ← LocaleSwitcher
│   └── extensions/  ← BuildContext extensions
├── routes/       ← auto_route router
└── resources/    ← generated locale keys, assets helpers
```

## Dependency Rules (Strict — لا استثناءات)

```
foundation  → nothing                                        ✅
platform    → foundation only                                ✅
infra       → foundation + platform                          ✅
di          → everything (composition root exception)        ✅
modules     → foundation + infra only                        ✅
Features    → foundation + infra + modules (NOT other Features) ✅
presentation → foundation + infra + platform                 ✅

core        → Features      ❌ NEVER (except di/)
core        → presentation  ❌ NEVER (except di/)
Features    → Features      ❌ NEVER
modules     → Features      ❌ NEVER
```

---

## Mandatory Documentation Sync

**لا تنهِ أي مهمة قبل تحديث readme المرتبط.**

| الملف | متى يُحدَّث |
|---|---|
| **`readme/README.md`** | **فهرس المجلد — يُحدَّث عند إضافة/حذف/نقل أي ملف فيه، بنفس التغيير** |
| `readme/03_RULES.md` | إضافة قاعدة صارمة أو فاحص آلي |
| `readme/04_FIRST_FEATURE.md` | تغيير بنية الشريحة أو ترتيب التوليد |
| `readme/05_FIGMA_TO_PAGE.md` | تغيير طريقة تصدير الفيغما · قاعدة تحويل `F##` · جدول المقابلة · **أو أي زوج لون يُفحص تباينه** |
| `readme/10_ARCHITECTURE.md` | أي تغيير هيكلي في lib/ |
| `readme/11_CORE.md` | تغيير core/ أو مبادئ الطبقات |
| `readme/12_REST_API.md` | تغيير REST flow أو network |
| `readme/13_ERROR_FLOW.md` | **ترتيب الـinterceptors · `Failure`/`FailureUiMapper` · `error-handler.ts`/`MESSAGES` · ترتيب middleware بـ`app.ts` · أي حدث بـ`AuthEventBus`** — يشمل النصفين معاً |
| `readme/14_PAGINATION.md` | تغيير PaginationCubit أو PaginationBuilderWdg |
| `readme/20_WIDGETS.md` | تغيير `ui/` أو `ui/widgets/` |
| `readme/40_SCRIPTS.md` | إضافة/تعديل سكربت |
| `readme/00_START_HERE.md` · `01_SETUP.md` | تغيير هيكل المشروع · خطوات الإعداد · onboarding |
| `readme/02_CHEATSHEET.md` | إضافة أمر · مسار import · widget · قيمة enum · سكربت |
| **`readme/41_ROADMAP.md`** | **إضافة اقتراح تطويري جديد أو تغيير حالة اقتراح موجود** — حلّ محلّ `90_archive/template_enhancements.md` المؤرشَف (2026-09-13) لهذا الغرض |
| `readme/90_archive/integration_audit.md` | أي تغيير في عقد الـwire بين الفرونت والباك |
| `readme/32_MODULE_DATA_TRANSFER.md` | تغيير `modules/data_transfer/` أو عقد `/api/v1/data-transfer` |
| `readme/31_MODULE_PERMISSIONS.md` | تغيير `modules/access_control/` أو `core/authz/` أو عقد `/api/v1/authz` |
| `readme/21_WIDGETS_USAGE.md` | إضافة widget للمكتبة أو تغيير أي وسيط عام على واحد موجود |
| `readme/22_RESPONSIVE.md` | تغيير `ui/responsive/` · حدٍّ من حدود الشاشة · معامل التكبير · حدَّي تكبير الخط · **أو نقلِ شاشةٍ جديدة إلى `ResponsiveContentBox`** (جدول §٦) |
| **`readme/23_STARTUP_SPLASH.md`** | **أي سطر بـ`main()` · `ModulesBootstrap.start`/`ready` · `StartupResolver` · `deepLinkBuilder` بـ`app.dart` · أيُّ مورد أندرويد بـ`res/drawable/splash_*` أو `values*/styles.xml` · علَم `android` بـ`flutter_native_splash.yaml`** |
| **`readme/17_SERVED_CONTRACT.md`** | **إضافة/حذف ثابت بـ`ApiUrls` · صيرورةُ نقطةٍ مخدومة · كشفُ عقدٍ يخالف المُعلَن · إعادةُ أي شريحة محذوفة** |
| `readme/90_archive/sync_design_spec.md` | ⛔ **لا يُصان** — أرشيف. حالةُ الموديول بـ`lib/modules/sync/PLAN.md` و`SETUP.md` |
| `readme/90_archive/**` | ⛔ **لا يُصان** — سجلّات مؤرَّخة. الانحراف يُعلَّق عليه بلافتة، لا يُمحى |
| `lib/modules/sync/PLAN.md` | **إنهاء أي مرحلة P0–P9** — الحالة والتاريخ ومعيار القبول. ويُحدَّث معه سجلّ النقل بـ`Qirtas/qirtas_app/lib/modules/sync/PORT_STATUS.md` |
| `lib/modules/sync/ARCHITECTURE.md` | تغيير مخطَّط v4 · دورة حياة حزمة أو ملف · ترتيب الدورة · شروط `SyncGate` |
| `lib/modules/sync/SETUP.md` | تغيير خطوات التركيب · **أو أي منفذ جديد يمسّ عقد الحذف** |
| `lib/modules/sync/LOAD_TEST_PLAN.md` | تغيير سيناريو تجريب أو محور قياس أو عتبة |
| `lib/modules/sync/RULES.md` | **أي رقم يخرج من P8** — لا يُملأ من تقدير |
| `readme/90_archive/realtime_design.md` | أي خطوة نحو بناء `modules/realtime/` (غير موجود اليوم) |
| **`loadtest/README.md`** | **إضافة/تعديل أي سيناريو k6 بـ`loadtest/k6/`** — سطرٌ بجدول «السيناريوهات الموجودة» لكل ملف جديد، بنفس الـcommit |

> **⚠️ ملفٌ خارج هذا الجدول = ملفٌ يتقادم بصمت.** الأربعة الأخيرة كانت خارجه حتى
> 2026-08-17، واثنان منها انحرفا فعلاً. الفهرس بـ[`readme/README.md`](readme/README.md)
> يحمل عمود «الحالة الحقيقية للكود» لكل ملف — أضف الصفّ هناك وهنا معاً.

## 🧟 قاعدة صارمة — تحقّق أن السلسلة موصولة **قبل** أن تبني عليها

**لا تفترض أن صنفاً مبنيّاً وموثَّقاً يعمل.** افتح مستدعيه أولاً: مَن يُسجّله بالـDI؟
مَن يُركّبه بالشجرة؟ مَن يستورده؟ لو كان الجواب «لا أحد»، فأنت أمام **سطح قالبٍ لا
سلسلةٍ عاملة** — والجرد الكامل بـ[`readme/10_ARCHITECTURE.md`](readme/10_ARCHITECTURE.md)
§«المبنيّ بلا مستهلك».

**ولهذه القاعدة وزن خاص بمستودع قالب**: هنا، «مبنيّ بلا مستهلك» هو الوضع **الطبيعي
والمقصود** لمعظم الموديولات — تُشحن مطفأة ليُشعلها المشروع. فالتمييز بين *سطحٍ يُقصد
أن ينتظر* و*سلسلةٍ انقطعت بالخطأ* لا يقوم به المصرِّف ولا التحليل ولا الاختبارات:
**كلها خضراء في الحالتين**. لا يقوم به إلا التوثيق، ولذلك:

| القاعدة | التفصيل |
|---|---|
| كل موديول بـ`lib/modules/` يُولد بثلاثة معاً | علم بـ`AppFeatures` · سطر بـ`ModulesBootstrap` · صف بجدول `10_ARCHITECTURE.md` |
| `✅` بجدول `90_archive/template_enhancements.md` تعني **«له مستهلك هنا»** | لا «الملف وصل». البند #19 كان `✅` بلا مستورِد واحد — صُحِّح إلى `◐` (2026-08-17) |
| ما لا علم له ولا مستدعٍ | يُذكر صراحةً بالجرد، أو يُحذف. `modules/in_app_updates/` كان المثال الحيّ لهذا حتى 2026-09-09 — وصله علَمه وسطرُ `ModulesBootstrap` وحارسُه (`AppUpdateGate`)، فراجع الجرد الحالّ بـ[`readme/10_ARCHITECTURE.md`](readme/10_ARCHITECTURE.md) §«جرد المبنيّ بلا مستهلك» لما هو معلَّق اليوم فعلاً |

## ⛓️ عقد الـwire — قاعدة صارمة

**مفاتيح JSON عقدٌ مع `backend_template`.** خطؤها لا يراه `dart analyze` (مفتاح غائب = `null` = `dynamic` سليم)، ولا `tsc`، ويبتلعه `HandleBodyResponse` فيصل المستخدمَ «حدث خطأ» بينما السيرفر يسجّل `200 OK`. **هذا وقع فعلاً ومنع الدخول كلياً** — راجع [`readme/90_archive/integration_audit.md`](readme/90_archive/integration_audit.md).

**عند تغيير أي مفتاح**: عدّل `test/fixtures/wire/*.json` هنا و`backend_template/src/features/*/__tests__/wire-contract.test.ts` هناك — **بنفس الـcommit**.

**المرجع القاطع للعقد**: `GET /openapi.json` من الباك (مولَّد من نفس zod schemas التي تفرضها `validate()`)، وشرحه النصّي بـ`backend_template/docs/rest_api.md`.

---

## Modification Rules

- تغيير minimal ومعزول — لا refactors واسعة بدون موافقة صريحة
- بعد أي DI · router · API · freezed · ترجمة · أو ملفٍّ بـ`assets/`: `dart run scripts/gen_code.dart` — **خمسُ خطواتٍ بأمرٍ واحد**، وتشغيلُ `build_runner` وحده يترك `codegen_loader.g.dart` و`assets.gen.dart` متقادمين
- تحقق دائماً: `dart analyze lib` **و`flutter test`**
- **وقبل أي تسليم: `dart run scripts/check_structure.dart` بلا مخالفة _جديدة_**

> **الأساس (`.structure_baseline.txt`) سجلُّ دَينٍ لا زرُّ تجاهل.** أُدخل الفاحصُ
> على قالبٍ قائم فوجد ٧٢ مخالفة كلُّها سابقةٌ له؛ إصلاحُها دفعةً واحدة refactor
> واسعٌ يخالف السطرَ الأول أعلاه، وتجاهلُها يجعل الفاحص عديمَ المعنى. فالمسجَّل
> يُعرَض ولا يُفشِل، وأيُّ مخالفةٍ **جديدة** تُفشِل — فلا يزيد الدَّين، ويُحرَق حين
> يُلمَس الملف لسببٍ آخر.
>
> ⛔ **ولا يُعاد توليدُ الأساس لإسكات مخالفةٍ جديدة.** والحارسُ العمليّ أن
> **تُراجَع الفروق** بعد `--baseline`: `git diff .structure_baseline.txt` **يجب**
> أن يكون حذفاً صرفاً. سطرٌ **مضاف** يعني أنك أسكتَّ مخالفةً جديدة لا أنك حرقتَ دَيناً.
