# CLAUDE.md — Flutter Base Template

> **هذا الملف slim — التفاصيل في CLAUDE.md الفرعية داخل lib/.**
> `.cursor/` لا يؤثر على Claude Code — يُقرأ CLAUDE.md فقط.

---

## 🗂️ جدول القرار

| إذا كنت تبني… | اقرأ |
|---|---|
| **Feature** (CRUD/Form/Nav/Widget) | `lib/Features/CLAUDE.md` |
| **REST endpoint** جديد | `lib/core/CLAUDE.md` → §API |
| **core/** أو **DI** | `lib/core/CLAUDE.md` |
| **imports / UI rules / localization** | `lib/CLAUDE.md` |
| **أي شيء في lib/** | `lib/CLAUDE.md` أولاً دائماً |
| **تعديل موديول Template** | `lib/Features/test/CLAUDE.md` → جدول المرآة |
| **إضافة شاشة Demo جديدة** | `lib/Features/test/CLAUDE.md` → كيفية الإضافة |

### Features الموجودة

| المسار | ما تفعله |
|---|---|
| `Features/auth/` | **دورة الحساب كاملة** — login · register · logout · me · verify_email · forgot_password · change_password · profile. مقابل `/api/v1/account` و`/api/v1/auth` بالباك |
| `Features/notes/` | **الـfeature المرجعية لـCRUD — احذفها.** قائمة مُصفَّحة + إنشاء + تعديل + حذف تفاؤلي، مقابل `/api/v1/notes`. المكان الوحيد الذي تُرى فيه §CRUD-PATTERNS و`PaginationCubit` على endpoint حقيقي |
| `Features/home/` | التنقل الرئيسي |
| `Features/settings/` | Theme + Language + Notifications + Version + Cache |
| `Features/splash/` | شاشة البداية — يستعيد التوكن **واللقطة المخزَّنة للمستخدم** قبل التنقّل |
| `Features/test/` | **Template Showcase** — demo بصري (Widgets · Forms · States · Theme) — debug فقط |

> `Features/test/` **لا تُبنى في production** — `AppFeatures.debugSkipLogin = false` يخفيها تماماً.

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
├── Features/     ← feature slices
├── presentation/ ← shared UI: theme, error, feedback, locale, pagination
├── shared/       ← shared widgets
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
| `readme/architecture.md` | أي تغيير هيكلي في lib/ |
| `readme/core_architecture.md` | تغيير core/ أو مبادئ الطبقات |
| `readme/rest_api.md` | تغيير REST flow أو network |
| `readme/pagination.md` | تغيير PaginationCubit أو PaginationBuilderWdg |
| `readme/widgets.md` | تغيير presentation/ أو shared/widgets/ |
| `readme/scripts.md` | إضافة/تعديل سكربت |
| `readme/new_developer_guide.md` | تغيير هيكل المشروع أو onboarding |
| `readme/template_enhancements.md` | إضافة اقتراح تطويري جديد أو تغيير حالة اقتراح موجود |
| `readme/integration_audit.md` | أي تغيير في عقد الـwire بين الفرونت والباك |

## ⛓️ عقد الـwire — قاعدة صارمة

**مفاتيح JSON عقدٌ مع `backend_template`.** خطؤها لا يراه `dart analyze` (مفتاح غائب = `null` = `dynamic` سليم)، ولا `tsc`، ويبتلعه `HandleBodyResponse` فيصل المستخدمَ «حدث خطأ» بينما السيرفر يسجّل `200 OK`. **هذا وقع فعلاً ومنع الدخول كلياً** — راجع [`readme/integration_audit.md`](readme/integration_audit.md).

**عند تغيير أي مفتاح**: عدّل `test/fixtures/wire/*.json` هنا و`backend_template/src/features/*/__tests__/wire-contract.test.ts` هناك — **بنفس الـcommit**.

**المرجع القاطع للعقد**: `GET /openapi.json` من الباك (مولَّد من نفس zod schemas التي تفرضها `validate()`)، وشرحه النصّي بـ`backend_template/docs/rest_api.md`.

---

## ⚡ Mandatory Dashboard Sync — قانون المرآة (صارم)

> **كل تغيير في Template Module يستوجب تحديث الـ Dashboard التفاعلي فوراً — بدون استثناء.**

### القاعدة الأساسية

**كل خيار/شكل/نمط قابل للتخصيص في الـ Template → يجب أن يكون له control تفاعلي في `Features/test/`:**

| نوع التغيير | ما يُضاف للـ Dashboard |
|---|---|
| `enum` جديد أو قيمة جديدة لـ enum موجود | خيار في `SegmentedButton` أو قائمة منسدلة |
| parameter اختياري جديد | Toggle / Slider / Color picker |
| Widget variant جديد | Card أو Tab مستقلة بمثال حي |
| خدمة أو موديول جديد | زر "Test" مع عرض النتيجة |
| سلوك متعدد الأشكال | مقارنة جنب لجنب (side-by-side) |

### جدول الربط الدائم

| الموديول / الملف | الشاشة المرتبطة | ما يُزامَن فوراً |
|---|---|---|
| `presentation/feedback/feedback_style.dart` | `WidgetLibraryDemoScreen` → `_FeedbackStyleSelector` | كل `FeedbackStyle` value → segment جديد |
| `presentation/feedback/app_feedback_service.dart` | `WidgetLibraryDemoScreen` | كل method جديدة → زر تجربة |
| `presentation/shared/pagination/pagination_cubit.dart` | سيناريو #03 | كل loading variant → Toggle في الـ demo |
| `shared/widgets/widgets.dart` (widget جديد) | `WidgetLibraryDemoScreen` | section جديد بكل variants الـ widget |
| `presentation/theme/app_palette.dart` | `TestThemeDemoScreen` | الألوان تظهر تلقائياً (لا تعديل) |
| `presentation/theme/app_colors.dart` | `TestThemeDemoScreen` | semantic token جديد → سطر في جدول الألوان |
| `core/platform/` + `app_features.dart` | سيناريو #11 | خدمة جديدة → زر test مع حالة enabled/disabled |
| `core/foundation/errors/failure.dart` | سيناريو #07 | failure type جديد → صف في القائمة |
| `routes/router.dart` (route جديد) | `TestDashboardScreen` | أضف card إذا كانت للـ test feature |
| `modules/sync/` | سيناريو #10 | أي operation جديدة → تظهر في المراقب |

### Checklist إلزامي قبل إغلاق أي مهمة

```
[ ] هل المُعدَّل موجود في جدول الربط أعلاه؟
[ ] هل تم تحديث الشاشة التفاعلية المقابلة؟
[ ] هل تم تحديث readme/test_scenarios_roadmap.md؟
[ ] dart analyze lib → لا warnings
```

> التفاصيل الكاملة لكيفية تنفيذ كل شاشة: `lib/Features/test/CLAUDE.md`

---

## Modification Rules

- تغيير minimal ومعزول — لا refactors واسعة بدون موافقة صريحة
- بعد DI/retrofit/freezed: `dart run build_runner build --delete-conflicting-outputs`
- تحقق دائماً: `dart analyze lib`
