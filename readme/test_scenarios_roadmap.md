# Test Scenarios Roadmap — خارطة سيناريوهات التجربة

> ملف المقترحات التنفيذية لـ `Features/test/` — كل سيناريو مرتبط بموديوله ومستقل للتنفيذ.
> **القاعدة:** راجع كل سيناريو بعد تنفيذه، ثم استئناف الملف لاختيار التالي.

---

## حالة التنفيذ

| # | العنوان | النوع | الموديول | الحالة |
|---|---|---|---|---|
| 01 | Feature Creation Wizard | تفاعلي | `Features/` architecture | ✅ مُنفَّذ |
| 02 | Navigation Stack Visualizer | تفاعلي | `routes/` + AutoRoute | ✅ مُنفَّذ |
| 03 | Pagination Live Demo | تفاعلي | `PaginationCubit` | ✅ مُنفَّذ |
| 04 | CRUD Full Simulation | تفاعلي | `BaseRepository` + Optimistic | ✅ مُنفَّذ |
| 05 | Form Validation Showcase | تفاعلي | `§FORMS-GUIDE` + validators | ✅ مُنفَّذ |
| 06 | BLoC States Visualizer | تفاعلي | `Freezed` + `BlocConsumer` | ✅ مُنفَّذ |
| 07 | Failure & Error Scenarios | تفاعلي | `FailureUiMapper` + `BaseRepository` | ✅ مُنفَّذ |
| 08 | Auth Flow Simulator | تفاعلي | `auth/` + `AuthEventBus` | ⬜ معلق |
| 09 | Dependency Injection Inspector | عرض | `core/di/` + Injectable | ⬜ معلق |
| 10 | Sync Module Monitor | تفاعلي | `modules/sync/` (محاكاة) | ✅ مُنفَّذ |
| 11 | Platform Services Demo | تفاعلي | `core/platform/` + AppFeatures | ✅ مُنفَّذ |
| 12 | REST API Inspector | تفاعلي | `core/infra/network/` + Retrofit (محاكاة pipeline) | ✅ مُنفَّذ |
| 13 | Connectivity & Lifecycle Monitor | تفاعلي | `NetworkStateMonitor` + `AppLifecycleService` | ✅ مُنفَّذ |

---

## تفاصيل كل سيناريو

---

### 01 — Feature Creation Wizard
**النوع:** شاشة تفاعلية خطوة بخطوة (Stepper)
**الموديول المرتبط:** `lib/Features/CLAUDE.md` (لا يوجد feature حي مبني بعد بهذا التيمبليت)

**ما تُظهره الشاشة:**
- Stepper مرئي: Domain → Data → DI → Route → Screen
- كل خطوة: كود حقيقي جاهز للنسخ (Code Block قابل للتحديد)
- زر "انسخ الكود" لكل snippet
- مؤشر يبيّن أين يقع الملف في شجرة المشروع

**الخطوات الخمس:**
1. `domain/entities/` + `domain/repositories/` (abstract)
2. `data/models/` + `data/datasources/` + `data/repositories/`
3. `domain/usecases/` + DI (`@injectable`)
4. `routes/router.dart` + `build_runner`
5. `presentation/cubits/` + `presentation/pages/`

**الربط الدائم:** إذا تغيّر نمط `Features/CLAUDE.md` → راجع هذا السيناريو وحدّث snippets الكود.

---

### 02 — Navigation Stack Visualizer
**النوع:** تفاعلي مرئي
**الموديول المرتبط:** `lib/routes/router.dart` · `lib/routes/router.gr.dart`

**ما تُظهره الشاشة:**
- مكدس بصري (Stack) يمثّل حالة `context.router`
- 4 أزرار: `push / replace / replaceAll / pop`
- عند الضغط: animation تُظهر دخول/خروج شاشة من المكدس
- جدول مقارنة: "متى تستخدم كل دالة؟"
- مثال Session Expired → `getIt<AppRouter>().replaceAll([LoginRoute()])`

**الربط الدائم:** `lib/Features/CLAUDE.md` §NAVIGATION-PATTERNS

---

### 03 — Pagination Live Demo
**النوع:** تفاعلي مع بيانات وهمية
**الموديول المرتبط:** `lib/presentation/shared/pagination/pagination_cubit.dart`

**ما تُظهره الشاشة:**
- `PaginationBuilderWdg` يعمل بـ Fake data source (بدون API)
- تحكم في: حجم الصفحة · وقت التأخير · احتمال الخطأ (Slider)
- زر "Simulate Error" → يُشغّل `ErrorStateWidget`
- زر "Simulate Empty" → يُشغّل `EmptyStateWidget`
- عداد يُظهر: الصفحة الحالية · إجمالي العناصر · حالة الـ Cubit

**الربط الدائم:** `readme/pagination.md` — أي تغيير في `PaginationCubit` يستدعي تحديث الشاشة وهذا الملف.

---

### 04 — CRUD Full Simulation
**النوع:** تفاعلي كامل
**الموديول المرتبط:** `lib/Features/CLAUDE.md` §CRUD-PATTERNS

**ما تُظهره الشاشة:**
- قائمة عناصر وهمية (in-memory, بدون API)
- Add Form → `prependItem()`
- Edit Form → `replaceEntityItem()` مع Optimistic Update مرئي
- Delete → `AppConfirmDialog` → `removeItemWhere()` مع Optimistic + Rollback
- زر "Simulate Server Error after Delete" → يُظهر rollback بصرياً (العنصر يعود)
- Overlay يُظهر تسلسل الاستدعاءات (Event Log)

**الربط الدائم:** `lib/Features/CLAUDE.md` §CRUD-PATTERNS

---

### 05 — Form Validation Showcase
**النوع:** تفاعلي
**الموديول المرتبط:** `lib/Features/CLAUDE.md` §FORMS-GUIDE

**ما تُظهره الشاشة:**
- نموذج حقيقي: Email + Password + Required Field
- Toggle: `autovalidateMode` ON/OFF (يُشرح `_submitted` flag)
- Toggle: `_isLoading` guard (يُظهر منع Double Submit)
- زر "Simulate API Error" → `context.feedback.error`
- مؤشر يُظهر حالة النموذج: Valid/Invalid/Loading/Submitted
- بعد نجاح الإرسال: `pop(entity)` مرئي

**الربط الدائم:** `lib/Features/CLAUDE.md` §FORMS-GUIDE

---

### 06 — BLoC States Visualizer
**النوع:** تفاعلي مرئي
**الموديول المرتبط:** `lib/Features/CLAUDE.md` §FREEZED + `presentation/cubits/`

**ما تُظهره الشاشة:**
- State Machine بصرية: `initial → loading → loaded/error`
- أزرار لكل انتقال حالة
- كود الـ Freezed state يُعرض جانبياً
- المخرجات الثلاثة: `state.when / maybeWhen / map`
- Demo: Cubit حقيقي يعمل مع Fake data

**الربط الدائم:** كل `@freezed` state جديد في المشروع → يمكن إضافة Tab له هنا.

---

### 07 — Failure & Error Scenarios
**النوع:** تفاعلي
**الموديول المرتبط:** `lib/core/foundation/errors/failure.dart` · `FailureUiMapper`

**ما تُظهره الشاشة:**
- قائمة بكل أنواع الـ Failures الموجودة
- ضغط على كل نوع → يُشغّل المعالج المناسب:
  - `ShowError` → `context.feedback.error`
  - `NavigateToLogin` → `AuthEventBus.emit(sessionExpired)` مرئي
  - `Silent` → لا شيء (مع شرح لماذا)
- HTTP Status Simulator: أدخل status code → اعرف الـ Failure المناظر

**الربط الدائم:** `lib/core/foundation/errors/failure.dart` · `lib/core/infra/network/`

---

### 08 — Auth Flow Simulator
**النوع:** تفاعلي كامل
**الموديول المرتبط:** `core/infra/session/session_repository.dart` + `AuthEventBus` (بنية تحتية جاهزة — ينتظر بناء أول auth feature فعلية لربط الشاشة بها، راجع `lib/Features/CLAUDE.md`)

**ما تُظهره الشاشة:**
- رسم تسلسلي (Sequence Diagram) مبسّط للـ Auth Flow
- أزرار: Login / Logout / Session Expired (manual trigger)
- مؤشر حالة الجلسة الحالية (mock)
- `SessionRepository` Inspector: اقرأ/احذف الجلسة المخزّنة
- زر "Expire Session" → يُطلق `AuthEvent.sessionExpired` → يُظهر انتقال `replaceAll([SplashRoute()])`

**الربط الدائم:** `core/infra/session/session_repository.dart` + `AuthEventBus`

---

### 09 — Dependency Injection Inspector
**النوع:** عرض (Read-only)
**الموديول المرتبط:** `lib/core/di/` + `injection.dart` + `injection.config.dart`

**ما تُظهره الشاشة:**
- قائمة بكل الـ services المسجّلة في GetIt
- تصنيف: `@singleton / @lazySingleton / @injectable`
- مؤشر: هل تم إنشاؤه (lazy initialized)?
- `AppFeatures` flags inspector: ما هي الـ Platform Services المفعّلة
- شرح: لماذا `di/` يملك حق import كل شيء

**الربط الدائم:** `lib/core/di/` — أي service جديد يُضاف يظهر تلقائياً لأن القائمة تُقرأ من GetIt.

---

### 10 — Sync Module Monitor
**النوع:** تفاعلي
**الموديول المرتبط:** `lib/modules/sync/` + `readme/sync.md`

**ما تُظهره الشاشة:**
- قائمة بـ Pending Sync Operations (mock)
- أزرار: Add Operation / Retry Failed / Clear All
- مؤشر: Online/Offline (toggle يدوي)
- عند Offline: العمليات تتراكم
- عند Online: تنفيذ تلقائي مرئي

**الربط الدائم:** `readme/sync.md` + `modules/sync/data/`

---

### 11 — Platform Services Demo
**النوع:** تفاعلي
**الموديول المرتبط:** `lib/core/platform/` + `lib/core/infra/config/app_features.dart`

**ما تُظهره الشاشة:**
- قائمة كل الـ Platform Services المتاحة
- لكل service: زر "Test" (يعمل فقط إذا كان `AppFeatures.X = true`)
- إذا معطّل: يُظهر شرح كيفية التفعيل (سطر واحد في `app_features.dart`)
- خدمات: Biometrics · Clipboard · Share · File · AppLifecycle

**الربط الدائم:** `lib/core/infra/config/app_features.dart` — أي flag جديد → يُضاف تلقائياً.

---

### 12 — REST API Inspector
**النوع:** تفاعلي
**الموديول المرتبط:** `lib/core/infra/network/` + `readme/rest_api.md`

**ما تُظهره الشاشة:**
- قائمة كل الـ API endpoints المعرّفة (`ApiUrls`)
- لكل endpoint: Method · URL · Auth required?
- Request/Response flow مرئي: Controller → UseCase → Repository → DataSource → Dio → API
- Interceptors المفعّلة: Auth · Logging · Certificate Pinning
- زر "Simulate 401" → يُشغّل session expiry flow

**الربط الدائم:** `lib/core/infra/network/rest/api_urls.dart` + `readme/rest_api.md`

---

## قواعد الربط الدائم

> عند تعديل أي موديول مرتبط بسيناريو → يجب مراجعة السيناريو المقابل وتحديثه.

| عند تعديل... | راجع السيناريو |
|---|---|
| `PaginationCubit` أو `PaginationBuilderWdg` | #03 |
| `FailureUiMapper` أو أنواع `Failure` | #07 |
| `AuthEventBus` أو `SessionRepository` | #08 |
| `AppFeatures` flags | #11 |
| `ApiUrls` أو network layer | #12 |
| `app_features.dart` platform services | #11 |
| `lib/Features/CLAUDE.md` patterns | #01, #04, #05 |
| AutoRoute configuration | #02 |

---

## ترتيب التنفيذ المقترح

```
أولاً (قيمة فورية للمطور):
  #05 Form Validation → #03 Pagination → #04 CRUD

ثانياً (فهم البنية):
  #01 Feature Wizard → #06 BLoC States → #07 Failures

ثالثاً (متقدم):
  #02 Navigation → #08 Auth Flow → #09 DI Inspector

رابعاً (اختياري - حسب الموديولات المفعّلة):
  #10 Sync → #11 Platform Services → #12 API Inspector
```
