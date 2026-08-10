# Template Enhancements — خارطة تطوير القالب

> **الغرض:** توثيق كل اقتراح تطويري للقالب — ما هو، لماذا، كيف يُدمَج، وكيف يبقى منفصلاً.
> **القاعدة الذهبية:** كل إضافة = **feature flag** أو **abstract service** — لا تأثير على المشاريع التي لا تحتاجها.

---

## 📍 كيف تُقرأ هذه الوثيقة

**عمودان للحالة، لا عمود واحد** — وهذا ليس تفصيلاً شكلياً:

| العمود | يعني |
|---|---|
| **قرطاس** | نُفِّذ بمشروع Qirtas (`qirtas_app`/`qirtas_backend`) — **حيث وُلد الدليل** |
| **القالب** | وصل كودُه هذا المشروع فعلاً |

**السبب**: البنود 13–43 كلها مستنتَجة من تطبيق عملي، وكُتبت أول مرة بملف قرطاس بعمود حالة **واحد**. فكانت `✅ مُنفَّذ` تعني «بقرطاس» بينما عنوان الوثيقة «خارطة تطوير القالب» — وقارئٌ هنا يظنّ الكود موجوداً وهو ليس كذلك. **وثيقةٌ صحيحة الشكل تصف واقعاً غير موجود هي بالضبط شكل العطل الذي تجمعه هذه الوثيقة كلها** — فلم يجز أن تقع فيه هي.

**ومصدر الأدلة**: مسارات مثل `Features/admin/roles/...` تخصّ **قرطاس**، وتُذكر شاهداً على أن العطل وقع فعلاً — لا تعليماتِ تنفيذ داخل القالب. أما «طريقة الدمج» بكل بند فمكتوبة للقالب.

**آخر مزامنة من قرطاس: 2026-08-10** — الطبقة الأساسية (18 · 19 · 23 · 24 · 27 · 28 · 43)، ثم الفرونت (13 · 14 · 17 · 25 · 26 · 32)، ثم الباك (20 · 21 · 33)، ثم CI (09)، ثم **حزمة `auth`** (15 · 16 بمستهلك حيّ).

> **قاعدة الاتجاه — تمنع التباعد الصامت**: أي ملف مشترك بين القالب ومشروع قائم يُعدَّل **بالقالب أولاً** ثم يُنسخ للمشروع، لا العكس. العكس هو ما جعل القالب يتأخّر ٣١ بنداً منذ تموز.
>
> **والاستثناء الوحيد المعلن**: `Features/auth/shared/entities/auth_user.dart` — يطابق شكل الـAPI بكل مشروع، وموثَّق داخله بأنه **لا يُزامَن**.

---

## مبدأ الاستقلالية (Opt-in Architecture)

القالب يتبع نمط واحداً صارماً لكل إضافة اختيارية:

```
1. Abstract interface  →  core/platform/{service}/
2. Concrete impl       →  core/infra/{service}/
3. Feature flag        →  app_features.dart: static const X = false
4. DI registration     →  تلقائي عند تفعيل الـ flag
5. Usage               →  context.X.method() أو getIt<XService>()
```

المشروع الذي لا يحتاج الخدمة → `static const X = false` → لا يُسجَّل شيء → صفر أثر.

---

## جدول الحالة

| # | الاقتراح | الأولوية | قرطاس | **القالب** | نوع الدمج |
|---|---|---|---|---|---|
| 01 | Predictive Back (Android 14+) | 🔴 عالية | — | ✅ | Widget مستقل |
| 02 | Haptic Feedback Service | 🔴 عالية | ✅ | ✅ | Platform Service + feature flag |
| 03 | Lottie Animations | 🔴 عالية | ✅ | ✅ | State Widgets بديلة |
| 04 | Adaptive / Responsive Layout | 🔴 عالية | ⬜ | ⬜ | Breakpoint utility |
| 05 | Crash Reporting (Sentry/Crashlytics) | 🟡 متوسطة | ⬜ | ⬜ | Abstract service + feature flag |
| 06 | Screenshot Prevention | 🟡 متوسطة | ⬜ | ⬜ | Platform Service + feature flag |
| 07 | Deep Linking | 🟡 متوسطة | ⬜ | ⬜ | Router pattern |
| 08 | App Lifecycle Service | 🟡 متوسطة | ⬜ | ⬜ | Platform Service + feature flag |
| **09** | GitHub Actions CI | 🔴 **رُفعت** | ⬜ | **✅** | `.github/workflows/ci.yml` بكل مستودع |
| 10 | Skeleton Widget Variants | 🟢 تجميلي | ✅ | ✅ | shared/widgets/ |
| 11 | Hijri Calendar Support | 🟢 تجميلي | ⬜ | ⬜ | Utility + Widget |
| 12 | Error Boundary Widget | 🟢 تجميلي | ⬜ | ⬜ | shared/widgets/wrappers/ |
| **13** | Split 401/403 Failure Types (`ForbiddenFailure`) | 🔴 عالية | ✅ | **✅** | Sealed hierarchy addition |
| **14** | PaginationCubit Optimistic-Update Methods | 🔴 عالية | ✅ | **✅** | Base class methods + CLAUDE.md fix |
| **15** | CurrentUserRepository (RBAC state) | 🔴 عالية | ✅ | **✅** | auth/shared/ addition |
| **16** | `ApiError.data` — حمولة إضافية اختيارية | 🔴 عالية | ✅ | **✅** | حقل اختياري + **مستهلك حيّ** بـ`login/` |
| **17** | فلترة/ترتيب اختياريان لكل قائمة (Backend + `AppFilterSheet`) | 🔴 عالية | ✅ | **✅** | عقد Backend عام + نمط Frontend موثّق |
| **18** | `SafeCubit` — حارس `emit` بعد `close` | 🔴 عالية | ✅ | **✅** | Base class بـ`foundation/` + اختبار |
| **19** | `MutationResult` — نتيجة الطفرة تُرجَع ولا تُبَثّ | 🔴 عالية | ✅ | **✅** | نوع صغير بـ`presentation/shared/` |
| **20** | `message_key` — سبب الرفض يُقرأ آلياً لا نصّياً | 🔴 عالية | ✅ | **✅** | حقل اختياري بالطرفين + فاحص ثابت — **`backend_template`** |
| **21** | `queryBooleanSchema` — البوليان بالـquery لا يُكرَه | 🔴 عالية | ✅ | **✅** | Zod schema مشترك — **`backend_template`** |
| 22 | Contract Smoke Test — يؤكد العلاقات لا الأرقام | 🔴 عالية | ✅ | ◐ | `npm run smoke` — **`backend_template`** |
| **23** | `NetworkLogInterceptor` — سطر لكل نجاح، كل شيء عند الفشل | 🔴 عالية | ✅ | **✅** | Interceptor بديل + feature flag |
| **24** | كاش الطلبات **opt-in** لا opt-out | 🔴 عالية | ✅ | **✅** | قلب افتراضي بـInterceptor موجود |
| 25 | مفردات شاشة التفاصيل + `PermissionsPanel` | 🟡 متوسطة | ✅ | ◐ | `shared/widgets/layout/` |
| **26** | البحث الحرّ — `ListFilterBar` + `likeTerm` | 🟡 متوسطة | ✅ | **✅** | امتداد #17 بالطرفين |
| **27** | `bottomContentInset` — آخر عنصر بالقائمة يجب أن يُرى | 🔴 عالية | ✅ | **✅** | extension + اختبار انحدار |
| **28** | أقسام ذاتية التحميل داخل `ListView` (keep-alive) | 🟡 متوسطة | ✅ | **✅** | نمط + اختبار مزدوج |
| 29 | سجل التدقيق هو الماضي — لا جداول `*_history` | 🟡 متوسطة | ✅ | ❌ | قرار معماري — **خاص بقرطاس، لا يُنقل** |
| 30 | طبقة الترجمة البعيدة: كاش عند الإقلاع + تحرير داخل التطبيق | 🟡 متوسطة | ✅ | ⬜ | توسيع `modules/dynamic_localization/` |
| 31 | حرّاس المسار: `requirePermission` + `RateLimiter` عام | 🔴 عالية | ✅ | ◐ | middleware — **`backend_template`** |
| **32** | `{Entity}DetailOutcome` — ثلاثة أجوبة لا اثنان | 🟢 تجميلي | ✅ | **✅** | نمط تنقّل (sealed class) |
| **33** | `common-schemas.ts` — قاعدة الحقل تُكتب مرة | 🟡 متوسطة | ✅ | **✅** | Zod schemas — **`backend_template`** |
| **43** | ميزات OpenType للعناوين (`ss01`) — طبقة بالثيم | 🟡 متوسطة | ✅ | **✅** | خريطة بـ`AppFonts` + `_textTheme` + اختبار |

> `❌` = **لا يُنقل عمداً** (قرار موثَّق بالبند نفسه)، لا «لم يُنفَّذ بعد».
>
> `◐` = **جزئي، والناقص مُسمّى** — لا «شبه منتهٍ»:
> - **#22** المِنصّة وقواعدها الثلاث وصلت (`npm run smoke`)، **وفحوص الوحدات لا** — القالب بلا `features/`، فالفحوص الحقيقية تُكتب مع أول موديول. الملف يحمل المثالين الأهمّ معلَّقين جاهزين.
> - **#25** `DetailHeaderCard`/`DetailFact`/`DetailSectionHeader` وصلت **مع انعكاس المرآة**؛ **`PermissionsPanel` لا** — تحتاج مجالَ صلاحيات لا يملكه القالب (مثل #15). وهذا كل الناقص.
> - **#31** `RateLimiter` وصل؛ **`requirePermission` لا** — يستورد `user-role-assignments.repository` من موديول غير موجود بالقالب. يُنقل مع أول نظام صلاحيات.
> - **انعكاس المرآة اكتمل** (2026-08-10): أقسام «مفردات شاشة التفاصيل» و«البحث والفلترة» و«شكل البطاقة» بـ`WidgetLibraryDemoScreen`، وكل صفوف جدول المرآة مُغلقة.
>
> `—` = لا ينطبق: البند #01 تغييرٌ بـ`AndroidManifest.xml` وُلد بالقالب أصلاً.

> **البنود 18–33 مستنتَجة من التطبيق العملي لمشروع قرطاس (٢٦ تموز – ١٠ آب ٢٠٢٦)** — لا اقتراحات نظرية. كل بند هنا سببه عطل حقيقي شُحن ثم اكتُشف، والسبب مذكور بنصّه داخل الكود المُشار إليه.

### مرشَّحات من مختبر الودجات (34–42)

> هذه **غير منفَّذة بأي مكان** — لا بقرطاس ولا بالقالب — فعمود واحد يكفيها.

| # | الاقتراح | الأولوية | الحالة | نوع الدمج |
|---|---|---|---|---|
| 34 | Guided UX — جولات إرشادية بأهداف مُسجَّلة | 🟡 متوسطة | ⬜ مرشَّح | محرّك + overlay + تخزين تقدّم |
| 35 | Session Guard — قفل بعد خمول / عند الخلفية | 🔴 عالية | ⬜ مرشَّح | Wrapper + config + feature flag |
| 36 | `MicroFeedbackController` + `AnimatedTapButton` | 🟡 متوسطة | ⬜ مرشَّح | Controller + widget بـ`shared/` |
| 37 | Feature Flags وقت التشغيل (أسبقية + مصدر القيمة) | 🟡 متوسطة | ⬜ مرشَّح | طبقة فوق `modules/remote_config/` |
| 38 | مركز إشعارات داخل التطبيق (قواعد + تجميع + مقروء) | 🟡 متوسطة | ⬜ مرشَّح | طبقة فوق `modules/push_notifications/` |
| 39 | Smart Form — نموذج متعدد الخطوات تعريفي | 🟢 تجميلي | ⬜ مرشَّح مشروط | بديل اختياري لـ§FORMS-GUIDE بالنماذج الطويلة |
| 40 | Fuzzy Search — ترتيب بالصلة وتسامح مع الأخطاء | 🟡 متوسطة | ⚠️ مرشَّح بعد إصلاح | دالة نقيّة — **لا تعمل بالعربية حالياً** |
| 41 | Smart Input — منافذ QR/OCR بتدرّج آمن | 🟢 تجميلي | ⬜ مرشَّح (منافذ فقط) | interfaces بلا محوّلات حقيقية |
| 42 | طبقة UX للمصادقة الحيوية (تصنيف أخطاء + cubit) | 🟡 متوسطة | ⬜ مرشَّح | فوق `BiometricsService` الموجود |

> **⚠️ فئة الدليل مختلفة عن 18–33.** تلك أعطالٌ شُحنت بقرطاس واكتُشفت بالإنتاج. أما 34–42 فمصدرها مختبر مستقل (`D:\awqaf_app\Archive\test_apps\widgets`) بُنيت فيه ٩ وحدات بشاشة عرض لكلٍّ منها — **كودٌ قائم ومقروء، لكنه لم يُشغَّل بمشروع حقيقي بعد**. فلا تُنقل أيٌّ منها كما هي: كل بند أدناه يذكر ما يجب أن يتغيّر قبل الدمج.

---

## التفاصيل الكاملة

---

### 01 — Predictive Back (Android 14+)

**ما هو:**
ميزة Android 14 تتيح للمستخدم معاينة الشاشة التي سيعود إليها أثناء سحب إيماءة الرجوع — الشاشة الحالية تتحرك مع الإصبع قبل تأكيد القرار.

**الفائدة للقالب:**
- يُعطي التطبيق شعور التطبيقات الرائدة (Google, Samsung, etc.)
- يقلل الـ accidental back navigation
- يعمل مع AutoRoute بدون تغيير المنطق

**طريقة الدمج:**
```yaml
# android/app/src/main/AndroidManifest.xml
<application android:enableOnBackInvokedCallback="true" ...>
```
```dart
// في كل شاشة تحتاج animation مخصصة:
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    // منطق الرجوع المخصص
  },
  child: Scaffold(...),
)
// Flutter يتكفل بالـ animation تلقائياً
```
**ملاحظة:** Flutter 3.22+ يدعم هذا تلقائياً مع `PopScope` — لا حاجة لكود إضافي.

**الاستقلالية:**
تغيير في `AndroidManifest.xml` فقط — لا تأثير على الكود. يمكن تعطيله بحذف السطر.

**التطوير المستقبلي:**
- إضافة custom transition animation عند الـ predictive back
- Hero animations مرتبطة بالـ back gesture

---

### 02 — Haptic Feedback Service

**ما هو:**
اهتزازات خفيفة مُزامَنة مع تفاعلات المستخدم: ضغط زر، نجاح عملية، خطأ، تحديد عنصر. تُعطي التطبيق "وزناً" وإحساساً باستجابة فورية.

**الفائدة للقالب:**
- يرفع جودة الـ UX من "جيد" إلى "احترافي" بسطور قليلة
- مدمج مع `context.feedback.*` الموجود — لا API جديد للمطور
- قابل للتعطيل الكامل من إعدادات المستخدم

**طريقة الدمج:**
```
core/platform/haptics/haptic_service.dart       ← abstract
core/infra/haptics/haptic_service_impl.dart     ← impl
app_features.dart: static const haptics = true  ← flag
```
```dart
// الاستخدام المقترح — يُضاف لـ AppFeedbackService:
context.feedback.success('تم');  // ← يُشغِّل HapticFeedback.mediumImpact() تلقائياً
context.feedback.error('خطأ');   // ← يُشغِّل HapticFeedback.vibrate()
```
أو مباشرة:
```dart
getIt<HapticService>().light();    // ضغط زر عادي
getIt<HapticService>().medium();   // إجراء مهم
getIt<HapticService>().heavy();    // خطأ / تحذير
getIt<HapticService>().success();  // تأكيد ناجح
getIt<HapticService>().error();    // فشل
```

**الاستقلالية:**
```dart
// app_features.dart
static const haptics = false; // ← يُعطِّل كل شيء بسطر واحد
```
عند `false` → `HapticService` = `NoOpHapticService` (لا تفعل شيئاً).

**التطوير المستقبلي:**
- إعداد في صفحة Settings: "تفعيل الاهتزازات"
- patterns مختلفة لكل نوع إشعار
- دعم خاص لـ watchOS إذا كان التطبيق يدعمه

---

### 03 — Lottie Animations (Empty / Error / Success States)

**ما هو:**
استبدال الأيقونات الثابتة في `EmptyStateWidget` / `ErrorStateWidget` / `SuccessStateWidget` بـ animations من Lottie — ملفات JSON خفيفة تُحرَّك بسلاسة.

**الفائدة للقالب:**
- الشاشات الفارغة والأخطاء تصبح "حيّة" بدل مملة
- حجم ملفات `.json` أصغر من GIF/Video
- تتكيف مع اللون (tintColor) والثيم تلقائياً
- المطور يمر ملف JSON فقط — الـ widget يتكفل بالباقي

**طريقة الدمج:**
```yaml
# pubspec.yaml
dependencies:
  lottie: ^3.x.x
```
```
assets/lottie/
  ├── empty.json
  ├── error.json
  ├── success.json
  ├── loading.json
  └── no_internet.json
```
```dart
// EmptyStateWidget يحتفظ بـ icon fallback إذا لم يوجد ملف:
EmptyStateWidget(
  titleKey: LocaleKeys.noItems,
  lottieAsset: 'assets/lottie/empty.json',  // ← اختياري
  icon: Icons.inbox_outlined,               // ← fallback
)
```

**الاستقلالية:**
- `lottieAsset` parameter اختياري — الـ widget يعود للـ icon تلقائياً
- المشروع الذي لا يحتاج Lottie → لا يمرر `lottieAsset` → لا dependency فعلية
- ملفات الـ JSON في `assets/lottie/` منفصلة عن الكود

**التطوير المستقبلي:**
- Lottie مخصصة لكل Feature (inventory empty ≠ chat empty)
- تحريك بالـ scroll (Lottie.controller مرتبط بـ ScrollController)
- دعم Dark Mode tinting

---

### 04 — Adaptive / Responsive Layout

**ما هو:**
نظام breakpoints يجعل التطبيق يتكيف مع أحجام الشاشات المختلفة (هاتف / تابلت / desktop) بدون تغيير الشاشات الموجودة.

**الفائدة للقالب:**
- الـ template يعمل على Tablet دون تعديل
- المطور يكتب كود واحد لكل الأجهزة
- جاهز لـ foldable phones (Galaxy Fold, etc.)

**طريقة الدمج:**
```dart
// lib/presentation/layout/breakpoints.dart
enum ScreenSize { compact, medium, expanded }

extension ScreenSizeX on BuildContext {
  ScreenSize get screenSize {
    final w = MediaQuery.sizeOf(this).width;
    if (w < 600) return ScreenSize.compact;
    if (w < 840) return ScreenSize.medium;
    return ScreenSize.expanded;
  }
  bool get isTablet => screenSize != ScreenSize.compact;
  bool get isCompact => screenSize == ScreenSize.compact;
}
```
```dart
// AdaptiveLayout widget:
AdaptiveLayout(
  compact: () => const _MobileLayout(),     // هاتف
  medium:  () => const _TabletLayout(),     // تابلت
  expanded: () => const _DesktopLayout(),   // desktop (اختياري)
)
```
```dart
// في MainShellScreen — tablet يعرض side navigation بدل bottom bar:
isTablet
  ? NavigationRail(...)      // sidebar
  : NavigationBar(...)       // bottom bar
```

**الاستقلالية:**
- `AdaptiveLayout` widget اختياري — يمكن استخدام `context.isTablet` مباشرة
- الشاشات الموجودة لا تتغير — فقط `MainShellScreen` يتكيف
- كل شاشة تختار بنفسها إذا أرادت تخطيطاً مختلفاً

**التطوير المستقبلي:**
- two-pane layout (قائمة + تفاصيل في نفس الشاشة على Tablet)
- دعم landscape orientation
- docking على Desktop Linux/Windows

> **حالة البند بعد قرطاس (2026-08-10)**: ما زال ⬜ معلقاً — لا `ScreenSize` ولا `AdaptiveLayout` بالكود. لكن `presentation/extensions/screen_sizes_extensions.dart` (المكان الطبيعي لهذا النظام) نما بمقياس واحد حقيقي أخرجه المشروع: `bottomContentInset` — راجع **#27**. الدرس أن أول ما احتاجه تطبيق فعلي من "التكيّف" لم يكن حجم الشاشة بل **ما يعلو المحتوى من أشرطة**، وهي حالة تصيب الهاتف نفسه لا التابلت.

---

### 05 — Crash Reporting (Sentry / Firebase Crashlytics)

**ما هو:**
نظام يُسجِّل الـ crashes والأخطاء غير المتوقعة تلقائياً ويُرسلها لـ dashboard خارجي — بدونه لا تعرف إذا تطبيقك يتعطل عند المستخدمين.

**الفائدة للقالب:**
- المطور يعلم بالأخطاء قبل أن يشكو المستخدمون
- يتكامل مع `runZonedGuarded` الموجود في `main.dart`
- يدعم breadcrumbs (تتبع خطوات المستخدم قبل الـ crash)

**طريقة الدمج:**
```
core/platform/observability/crash_reporter.dart      ← abstract
core/infra/observability/sentry_crash_reporter.dart  ← Sentry impl
core/infra/observability/crashlytics_reporter.dart   ← Firebase impl
app_features.dart: static const crashReporting = false
```
```dart
// main.dart — يُدمَج مع الموجود:
void _onError(Object error, StackTrace stack) {
  debugPrint('Uncaught error: $error\n$stack');
  if (AppFeatures.crashReporting) {
    getIt<CrashReporter>().recordError(error, stack, fatal: true);
  }
}
```
```dart
// في Cubits — تسجيل أخطاء غير مميتة:
res.fold(
  (failure) {
    getIt<CrashReporter>().recordError(failure, StackTrace.current);
    // ...
  },
  ...
)
```

**الاستقلالية:**
```dart
static const crashReporting = false; // ← بدون Sentry DSN تماماً
```
`CrashReporter` يُسجَّل كـ `NoOpCrashReporter` عند `false`.

**التطوير المستقبلي:**
- إضافة User context (user ID, email للمستخدم المسجل)
- Custom breadcrumbs لكل navigation event
- Performance monitoring (page load time)
- Session replay (Sentry)

---

### 06 — Screenshot Prevention

**ما هو:**
منع المستخدم من أخذ لقطة شاشة في شاشات حساسة (بيانات الحساب، المعاملات المالية، الوثائق السرية).

**الفائدة للقالب:**
- متطلب أمني في التطبيقات البنكية والحكومية
- يُفعَّل per-screen لا globally
- iOS + Android بنفس الـ API

**طريقة الدمج:**
```yaml
dependencies:
  flutter_windowmanager: ^0.x.x  # Android
  # iOS: handled via UIScreen.main.isCaptured
```
```
core/platform/security/screen_capture_service.dart   ← abstract
core/infra/security/screen_capture_service_impl.dart ← impl
app_features.dart: static const screenshotPrevention = false
```
```dart
// Widget مشترك للشاشات الحساسة:
SecureScreen(
  child: Scaffold(...),
)
// أو مباشرة في initState:
getIt<ScreenCaptureService>().preventCapture();
```

**الاستقلالية:**
- `SecureScreen` wrapper اختياري — لا يُستخدم إلا حيث يلزم
- `screenshotPrevention = false` → `NoOpScreenCaptureService`
- لا تأثير على الشاشات العادية

**التطوير المستقبلي:**
- global mode (كل التطبيق محمي) بسطر واحد
- منع الـ screen recording أيضاً
- إشعار للمستخدم "لا يمكن أخذ لقطة شاشة في هذه الصفحة"

---

### 07 — Deep Linking

**ما هو:**
فتح شاشة معينة داخل التطبيق عبر URL — مثل `myapp://product/123` أو `https://myapp.com/profile`.

**الفائدة للقالب:**
- يُتيح مشاركة روابط داخل التطبيق
- ضروري للـ push notifications التي تفتح صفحة محددة
- AutoRoute يدعمه بشكل طبيعي

**طريقة الدمج:**
```dart
// router.dart — يُضاف path لكل route:
AutoRoute(page: ProductRoute.page, path: '/product/:id'),
AutoRoute(page: ProfileRoute.page, path: '/profile'),
```
```xml
<!-- AndroidManifest.xml -->
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <data android:scheme="https" android:host="myapp.com"/>
</intent-filter>
```
```dart
// app.dart — معالجة الـ deep link:
routerConfig: _router.config(
  deepLinkBuilder: (link) => DeepLink.path(link.path),
),
```

**الاستقلالية:**
- الـ routes الموجودة لا تتغير — فقط يُضاف `path`
- `deepLinkBuilder` اختياري في AutoRoute config
- يُفعَّل فقط بإضافة `intent-filter` في AndroidManifest

**التطوير المستقبلي:**
- Firebase Dynamic Links (روابط تعمل حتى قبل تثبيت التطبيق)
- Universal Links (iOS)
- Analytics على كل deep link

---

### 08 — App Lifecycle Service

**ما هو:**
الاستجابة لأحداث دورة حياة التطبيق: `resumed` (عاد من الخلفية)، `paused` (ذهب للخلفية)، `detached` (أُغلق).

**الفائدة للقالب:**
- refresh البيانات عند العودة بعد فترة طويلة
- إيقاف/استئناف الـ network calls عند الخلفية
- قفل التطبيق تلقائياً بعد وقت محدد في الخلفية
- يتكامل مع `AppFeatures.appLifecycle` الموجود

**طريقة الدمج:**
```dart
// AppLifecycleService الموجود يُوسَّع:
abstract class AppLifecycleService {
  Stream<AppLifecycleState> get stateStream;
  bool get isInForeground;
  Duration get backgroundDuration; // ← مدة الخلفية
}
```
```dart
// استخدام في أي cubit:
@injectable
class HomeListCubit extends PaginationCubit<Item> {
  HomeListCubit(this._lifecycle) {
    _lifecycle.stateStream
      .where((s) => s == AppLifecycleState.resumed)
      .listen((_) {
        // refresh إذا مضى أكثر من 5 دقائق في الخلفية
        if (_lifecycle.backgroundDuration > const Duration(minutes: 5)) {
          refresh();
        }
      });
  }
}
```

**الاستقلالية:**
```dart
static const appLifecycle = false; // ← service لا يُسجَّل
```

**التطوير المستقبلي:**
- auto-lock screen بعد 3 دقائق في الخلفية
- "مرحباً بعودتك" greeting عند الرجوع
- pause/resume video/audio تلقائياً

---

### 09 — GitHub Actions CI/CD

**ما هو:**
pipeline تلقائي يُشغَّل عند كل pull request: `dart analyze` + `flutter test` + `flutter build`.

**الفائدة للقالب:**
- لا يصل كود معطوب للـ main branch
- يُوثِّق للمطور الجديد ما يجب أن يمر (analyze + tests)
- يُنتج APK/IPA جاهزة للاختبار تلقائياً

**طريقة الدمج:**
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.x.x' }
      - run: flutter pub get
      - run: dart analyze lib
      - run: flutter test

  build_android:
    needs: analyze
    runs-on: ubuntu-latest
    steps:
      - run: flutter build apk --flavor dev
```

**الاستقلالية:**
ملفات YAML في `.github/workflows/` — خارج `lib/` تماماً. لا تأثير على الكود.

---

### ✅ ما نُفِّذ فعلاً (2026-08-10) — ورُفعت أولويته من 🟢 إلى 🔴

**لماذا تغيّرت الأولوية**: كُتب هذا البند حين كان الفحص الوحيد `dart analyze`. واليوم صار بالمشروعين **ستة فواحص** بُني كلٌّ منها لأن عطلاً حقيقياً مرّ من المراجعة — ولا شيء يشغّلها إلا الذاكرة. وموضوع هذه الوثيقة كلها أن **القاعدة بلا فاحص اقتراح**؛ فالفواحص بلا مُشغِّل هي نفس المشكلة بطبقة أعلى.

| المستودع | الوظائف |
|---|---|
| `app_template` | `analyze` → `test` → `format` (استشاري) · ثم **بناء APK** لأن `analyze` لا يرى Gradle مكسوراً ولا manifest لا يندمج |
| `backend_template` | `typecheck` → **`check:messages`** → `lint` → `build` |

**ثلاثة قرارات مقصودة:**

1. **`check:messages` قبل `lint`** — مفتاح ترجمة ناقص يصل مستخدماً، واستيراد غير مستعمل لا يصل أحداً.
2. **`format` غير حاجب** — قيس ولم يُخمَّن: **١٣٧ من ٣٢٧ ملفاً** غير مُنسَّقة (المستودع أقدم من `dart format` الحالي). لو حَجَب لصار كل PR أحمر لحظة فتحه، **وبناءٌ أحمر دائماً بناءٌ لا يقرؤه أحد**. الترقية لبوابة: `dart format .` مرة بكوميت مستقل، ثم احذف `continue-on-error`.
3. **`npm run smoke` ليس بالـCI** — يحتاج خادماً يعمل وقاعدة مبذورة. يُضاف حين تصير للقالب موديولات فعلية تستحق عقودها الحراسة؛ الطريقة موصوفة بتعليق آخر الملف.

**والدرس المرافق**: كان بالقالب ملف اختبار **فارغ (٢ بايت)** يُفشل `flutter test` كلّه منذ ١٢ تموز. أي أن الاختبارات كانت حمراء دائماً، فتوقف الناس عن تشغيلها — **وحارسٌ ضدّ عطل صامت يصير صامتاً هو نفسه حين يتوقف عن العمل**. حُذف، والمجموعة الآن خضراء بـ٢١ اختباراً. لا معنى لـCI فوق مجموعة مكسورة.

**التطوير المستقبلي:**
- نشر تلقائي لـ Firebase App Distribution عند merge لـ main
- `smoke` بمواجهة بيئة مؤقتة (`services: postgres:16`)
- تشغيل integration tests على device farm

---

### 10 — Skeleton Widget Variants

**ما هو:**
توسيع `SkeletonWidget` الموجود بـ templates جاهزة لأشكال الـ widgets الشائعة — بدلاً من بناء skeleton من الصفر لكل صفحة.

**الفائدة للقالب:**
- توحيد مظهر الـ loading placeholders في كل التطبيق
- المطور يختار template جاهز بدل بناء كل شيء يدوياً
- يتكامل مع `ShimmerLoadingWidget` الموجود

**طريقة الدمج:**
```dart
// shared/widgets/placeholders/skeleton_templates.dart
class SkeletonListTile extends StatelessWidget {
  // avatar + عنوان + سطر ثانوي
}

class SkeletonCard extends StatelessWidget {
  // صورة + عنوان + نص متعدد الأسطر
}

class SkeletonGridItem extends StatelessWidget {
  // مربع + عنوان في الأسفل
}

class SkeletonProfile extends StatelessWidget {
  // دائرة كبيرة + خطوط أفقية
}

// الاستخدام:
ShimmerLoadingWidget(
  child: Column(
    children: List.generate(6, (_) => const SkeletonListTile()),
  ),
)
```

**الاستقلالية:**
مجرد widgets إضافية — لا تُغيِّر الموجود. كل مشروع يستخدم ما يناسبه.

**التطوير المستقبلي:**
- Skeleton مخصص لكل Feature (e.g., `SkeletonProductCard`)
- SkeletonBuilder يولد skeleton تلقائياً من widget موجود (experimental)

---

### 11 — Hijri Calendar Support

**ما هو:**
دعم عرض وتحويل التواريخ الهجرية — ضروري للتطبيقات الحكومية والإسلامية والعربية.

**الفائدة للقالب:**
- حاجة شائعة في المنطقة العربية
- يُوحِّد طريقة التعامل مع التاريخ الهجري في المشروع
- يتكامل مع EasyLocalization الموجود

**طريقة الدمج:**
```yaml
dependencies:
  hijri: ^2.x.x
```
```dart
// lib/core/foundation/utils/date_utils.dart
extension HijriDateX on DateTime {
  String toHijriString({String locale = 'ar'}) {
    final hijri = HijriCalendar.fromDate(this);
    return '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';
  }
  HijriCalendar toHijri() => HijriCalendar.fromDate(this);
}
```
```dart
// Widget جاهز:
HijriDateText(date: DateTime.now())
// → "١٥ رجب ١٤٤٦"

HijriDatePicker(
  onDateSelected: (hijri) { ... },
)
```

**الاستقلالية:**
- Extension على `DateTime` — لا تغيير على الكود الموجود
- `HijriDateText` widget اختياري بالكامل
- Dependency اختيارية في `pubspec.yaml`

**التطوير المستقبلي:**
- عرض التاريخين (ميلادي/هجري) معاً
- حساب الأشهر والأيام الهجرية
- مواقيت الصلاة

---

### 12 — Error Boundary Widget

**ما هو:**
مستوحى من React Error Boundaries — يلتقط أخطاء `build()` غير المتوقعة ويعرض widget بديل بدلاً من crashing التطبيق.

**الفائدة للقالب:**
- يمنع crash كامل بسبب خطأ في widget ثانوي
- يُظهر للمستخدم رسالة واضحة بدل شاشة سوداء
- يُرسل تقرير الخطأ لـ CrashReporter تلقائياً

**طريقة الدمج:**
```dart
// shared/widgets/wrappers/error_boundary.dart
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    required this.child,
    this.fallback,
    super.key,
  });

  final Widget child;
  final Widget? fallback;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void didUpdateWidget(ErrorBoundary old) {
    super.didUpdateWidget(old);
    if (old.child != widget.child) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ??
          ErrorStateWidget(
            messageKey: LocaleKeys.somethingWrong,
            onRetry: () => setState(() => _error = null),
          );
    }
    return widget.child;
  }
}

// ErrorWidget.builder في main.dart:
ErrorWidget.builder = (details) {
  getIt<CrashReporter?>()?.recordError(details.exception, details.stack);
  return const _ErrorFallback();
};
```
```dart
// الاستخدام في شاشات:
ErrorBoundary(
  fallback: const Text('فشل تحميل هذا القسم'),
  child: ComplexWidget(),
)
```

**الاستقلالية:**
- `ErrorBoundary` wrapper اختياري تماماً
- يعمل بدون `CrashReporter` إذا لم يُفعَّل
- لا يُغيِّر أي شاشة موجودة

**التطوير المستقبلي:**
- retry with exponential backoff
- تقرير تفصيلي للمطور في debug mode
- boundary على مستوى المشروع (يلفّ كل الشاشات)

---

### 13 — Split 401/403 Failure Types (`ForbiddenFailure`)

**ما هو:**
فصل `UnauthorizedFailure` (401 — لا توكن/توكن غير صالح، يستوجب تسجيل خروج قسري) عن `ForbiddenFailure` جديد (403 — جلسة صالحة لكن بدون الصلاحية المطلوبة). القالب حالياً يدمجهما بنفس النوع، وكلاهما يُخرج المستخدم للدخول فوراً — سلوك خاطئ لأي مشروع RBAC.

**الفائدة للقالب:**
- أي مشروع صلاحيات (RBAC) يحتاج التمييز بين "يجب تسجيل الدخول" و"ممنوع عليك تحديداً بسبب عمل" — دمجهما يُخرج المستخدم من التطبيق حتى لمجرد نقص صلاحية على زر واحد.
- يتكامل مع `CurrentUserRepository` (#15) لاحقاً — إخفاء العنصر مسبقاً بدل الاعتماد فقط على رفض السيرفر.
- تفعيل الـ compiler exhaustiveness (`Failure` نوع `sealed`) لضمان معالجة الحالة الجديدة بكل مكان مطلوب، بدون تفويت صامت.

**طريقة الدمج:**
```
core/foundation/errors/failure.dart        ← إضافة ForbiddenFailure (final class جديد)
core/infra/errors/dio_failure_mapper.dart  ← فصل 401→UnauthorizedFailure عن 403→ForbiddenFailure
presentation/error/failure_ui_mapper.dart  ← حالة جديدة: ForbiddenFailure → ShowError (لا NavigateToLogin)
```
```dart
// failure.dart
/// 403 أثناء جلسة صالحة — توكن سليم لكن صلاحية ناقصة.
/// يختلف عن UnauthorizedFailure (401 = لا توكن/توكن غير صالح).
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({this.serverMessage});
  final String? serverMessage;
  @override
  String? get diagnosticMessage => serverMessage;
}
```
```dart
// dio_failure_mapper.dart — داخل _fromBadResponse
if (status == 401) return UnauthorizedFailure(serverMessage: serverMessage);
if (status == 403) return ForbiddenFailure(serverMessage: serverMessage);
```
```dart
// failure_ui_mapper.dart
ForbiddenFailure(:final serverMessage) => ShowError(
    title: LocaleKeys.error.tr(),
    message: serverMessage?.isNotEmpty == true ? serverMessage! : LocaleKeys.forbiddenAction.tr(),
  ),
```

**الاستقلالية:**
المشاريع التي لا تستخدم صلاحيات دقيقة على السيرفر (403 لا يحدث أبداً عملياً) لا ترى أي فرق — `ForbiddenFailure` ببساطة لا يُبنى أبداً. لا تغيير سلوكي على أي كود موجود يعتمد على `UnauthorizedFailure` (لا يزال يمثّل 401 فقط، كما كان).

**التطوير المستقبلي:**
- زر "طلب صلاحية" يظهر تلقائياً على `ForbiddenFailure` بدل الرسالة العامة.
- أسباب 403 خاصة بمنطق عمل معيّن (مثل حالات حساب متعددة) تبقى أنواع Failure مستقلة خاصة بميزتها (نفس نمط `LoginFailure` الموجود أصلاً) — لا تُدمَج بـ`ForbiddenFailure` العام.

---

### 14 — PaginationCubit Optimistic-Update Methods

**ما هو:**
إضافة `removeItemWhere`/`restoreItems`/`prependItem` إلى `PaginationCubit` الفعلي. كانت موثّقة بـ`Features/CLAUDE.md`§CRUD-PATTERNS كمفردات متوقعة، لكنها لم تكن موجودة فعلياً بالكلاس الحقيقي — فقط `replaceEntityItem` كانت مبنية. أول استخدام إنتاجي حقيقي لـ`PaginationCubit` بمشروع فعلي كشف الفجوة.

**الفائدة للقالب:**
- توحيد مفردات التحديث المتفائل (optimistic update: حذف/إضافة فوري بالواجهة قبل تأكيد السيرفر، مع إمكانية التراجع عند الفشل) بدل أن يبنيها كل Feature يدوياً بأسلوب مختلف.
- يجعل توثيق `Features/CLAUDE.md` الحالي **صحيحاً فعلياً** بدل وصف methods غير موجودة.

**طريقة الدمج:**
```
presentation/shared/pagination/pagination_cubit.dart  ← 3 methods جديدة على الـ base class
```
```dart
/// يحذف عناصر تطابق [test] من الحالة الحالية — نداء قبل await الحذف
/// للتحديث المتفائل؛ استدعِ [restoreItems] بالنسخة الأصلية لو فشل الطلب.
void removeItemWhere(bool Function(E) test) { ... }

/// يستعيد لقطة محفوظة — للتراجع بعد فشل [removeItemWhere]/[replaceEntityItem] المتفائل.
void restoreItems(List<E> backup) { ... }

/// يضيف عنصراً جديداً بأعلى القائمة (مثلاً بعد إنشاء ناجح يرجع الكيان الكامل من السيرفر).
void prependItem(E entity) { ... }
```

**الاستقلالية:**
3 دوال إضافية على base class موجود — لا تغيير على `call()`/`getPage()`/`refresh()`/`replaceEntityItem()` الحالية. أي Feature قائم لا يتأثر لأنه لا يستدعيها.

**التطوير المستقبلي:**
- `moveItem(from, to)` لإعادة الترتيب اليدوي (drag & drop قوائم).
- دعم batch operations (حذف/تحديث متعدد بنداء واحد).

---

### 15 — CurrentUserRepository (حالة RBAC تفاعلية)

**ما هو:**
مستودع reactive جديد، بجانب `SessionRepository` الموجود (الذي يخزّن التوكن فقط) — يحمل `AuthUser` الحالي + مجموعة مفاتيح صلاحياته الفعّالة، مع `Stream` للتغيّرات. يُستخدم لإخفاء/تعطيل عناصر واجهة حسب صلاحية المستخدم الحالي (مثال: زر "إدارة الأدوار" لا يظهر إلا لمن يملك `roles.edit`).

**الفائدة للقالب:**
- أي تطبيق RBAC يحتاج هذا فوراً — بدونه كل شاشة تعيد بناء نفس منطق "هل هذا المستخدم مخوَّل؟" بطريقتها الخاصة من بيانات مخزّنة محلياً بشكل غير موحّد.
- يتكامل مباشرة مع `ForbiddenFailure` (#13) — إخفاء الزر مسبقاً بدل الاعتماد فقط على رفض السيرفر بعد الضغط.

**طريقة الدمج:**
```
Features/auth/shared/current_user_repository.dart   ← ملف جديد، بجانب session_repository.dart
```
```dart
@singleton
class CurrentUserRepository {
  AuthUser? _user;
  Set<String> _permissionKeys = const {};
  final _controller = StreamController<AuthUser?>.broadcast();

  Stream<AuthUser?> get userStream => _controller.stream;
  AuthUser? get currentUser => _user;
  bool hasPermission(String key) => _permissionKeys.contains(key);

  void setCurrentUser(AuthUser user, {Set<String> permissionKeys = const {}}) {
    _user = user;
    _permissionKeys = permissionKeys;
    _controller.add(_user);
  }

  void clear() {
    _user = null;
    _permissionKeys = const {};
    _controller.add(null);
  }
}
```
`@singleton` (eager) — نفس تسويغ `SessionRepository` بالضبط: يجب أن يكون جاهزاً فوراً بعد نجاح الدخول، قبل أول بناء لشاشة رئيسية قد تسأل `hasPermission()`. يُستدعى `setCurrentUser()` من `LoginRepositoryImpl` بجانب `SessionRepository.saveToken()`، و`clear()` من `LogoutRepositoryImpl` بجانب `clearSession()`.

**الاستقلالية:**
ملف جديد بالكامل — لا يُعدَّل أي كود قائم عدا سطرين إضافة/مسح بـ`LoginRepositoryImpl`/`LogoutRepositoryImpl`. المشروع الذي لا يحتاج RBAC ببساطة لا يستدعي `hasPermission()` بأي شاشة، ويبقى `permissionKeys` فارغة دائماً بدون أي أثر سلبي.

**التطوير المستقبلي:**
- `PermissionGate(requires: 'users.manage', child: ...)` widget عام بـ`shared/widgets/` يلف أي عنصر واجهة ويخفيه تلقائياً بدل تكرار `if (hasPermission(...))` بكل شاشة.
- ربط `permissionKeys` بمصدر فعلي بعد تسجيل الدخول (endpoint "effective permissions" مخصص، أو تجميع من `role-assignments` + تفاصيل كل دور) — تفصيل تنفيذي لكل مشروع حسب عقد الـAPI الخاص به.

---

### 16 — `ApiError.data` (حمولة إضافية اختيارية)

**ما هو:**
`ApiError` (`core/foundation/contracts/api_response.dart`) يحمل حالياً `code`/`message` فقط. بعض الـAPIs (مثال حقيقي: `POST /login` بمشروع Qirtas) ترجع حقل `data` إضافي مع رد الخطأ لتمييز السبب الدقيق برمجياً (مثلاً `data.account_status`) بدل الاعتماد على مطابقة نص `message` الهش. `ApiError.data` حقل اختياري جديد (`Map<String, dynamic>? data`) يحمل هذه الحمولة الخام — التحويل لـ`Failure` مخصصة يبقى مسؤولية الـrepository، لا `ApiError` نفسه.

**الفائدة للقالب:**
- أي مشروع يحتاج تمييز أسباب رفض متعددة بنفس كود HTTP (401/403/422 بأسباب مختلفة) يقدر يمررها برمجياً بدل تكرار مطابقة نص.
- لا يفرض أي التزام — المشاريع اللي لا تحتاجه ببساطة لا تمرر `data` عند بناء `ApiError`، ويبقى `null` دائماً.

**طريقة الدمج:**
```dart
// core/foundation/contracts/api_response.dart
class ApiError extends Equatable {
  const ApiError({this.code, this.message = '', this.data});

  final int? code;
  final String message;
  final Map<String, dynamic>? data;

  @override
  List<Object?> get props => [code, message, data];
}
```
الاستهلاك (مثال حي، `AuthRemoteDataSource.login()`):
```dart
final dataJson = json['data'] as Map<String, dynamic>?;
// عند status=false: dataJson هنا هو حمولة الخطأ (account_status ...)، ليس بيانات النجاح
return ApiResponse<LoginModel>(
  status: 'error',
  message: message,
  data: null,
  error: ApiError(code: code, message: message, data: dataJson),
);
```
ثم بالـrepository:
```dart
final accountStatus = res.error?.data?['account_status'] as String?;
return switch (accountStatus) {
  'pending_approval' => Left(LoginPendingApprovalFailure(serverMessage: res.message)),
  'rejected' => Left(LoginRejectedFailure(
      reason: res.error?.data?['rejection_reason'] as String?,
      serverMessage: res.message,
    )),
  'suspended' => Left(LoginSuspendedFailure(serverMessage: res.message)),
  'disabled' => Left(LoginDisabledFailure(serverMessage: res.message)),
  _ => Left(LoginFailure(serverMessage: res.message)),
};
```

**الاستقلالية:**
حقل اختياري بقيمة افتراضية `null` — كل استدعاء موجود لـ`ApiError(code: ..., message: ...)` بالمشروع يبقى يعمل بدون أي تعديل (named parameter اختياري لا يكسر أي constructor call قائم).

**التطوير المستقبلي:**
- تعميم النمط: `FailureMapperRegistry`/`DioFailureMapper` (مسار الاستثناءات العام، غير مسار `ApiError` اليدوي المستخدم بـ`AuthRemoteDataSource`) يقدر يُوسَّع لاحقاً لقراءة `data` من `error.response?.data` تلقائياً لو مشروع معين احتاج نفس النمط على نطاق أوسع من الأخطاء اليدوية.

---

### 17 — فلترة/ترتيب اختياريان لكل قائمة (Backend عام + `AppFilterSheet`)

**ما هو:**
عقد موحّد يجعل **كل** list endpoint بالباك إند يدعم فلترة + ترتيب اختياريَّين من الأساس، مع widget فرونت عام جاهز (`AppFilterSheet`) يُربط بأي قائمة بضغطة زر — بدل أن يبني كل مشروع منطق فلترة خاصاً به من الصفر، أو يكتشف متأخراً أن `findManyPaginated` بلا `orderBy` يُرجع ترتيباً غير مضمون من PostgreSQL. اكتُشفت هذه الفجوة بمشروع Qirtas الفعلي عبر مشكلة حقيقية: عنصر جديد يُضاف بأول القائمة محلياً (`prependItem`) لكن يظهر بموضع مختلف بعد أي `refresh()` — التتبع كشف أن السبب الجذري هو غياب `ORDER BY` أصلاً بالباك إند، وليس خطأ بمنطق الفرونت.

**الفائدة للقالب:**
- **الباك إند**: `findManyPaginated()` يفرض `options.orderBy` **إلزامياً على مستوى النوع** (TypeScript) — أي موديول جديد لا يقدر يفوّت هذا بالخطأ، البناء يرفض التصعيد. هذا وحده يمنع تكرار نفس علة Qirtas بأي مشروع مستقبلي يُبنى على القالب.
- **الفرونت**: `AppFilterSheet` (`shared/widgets/dialogs/app_filter_sheet.dart`) كان موجوداً بالقالب أصلاً كـwidget عام جاهز (`FilterGroup<T>`/`SortOption<T>`) لكن غير مُستخدم بأي شاشة حقيقية — أول استخدام إنتاجي فعلي (Users/Roles بمشروع Qirtas) كشف أنه يعمل ممتازاً وكل ما ينقصه توثيق ربطه بـ`PaginationCubit`.
- الفلترة اختيارية بالكامل بالطرفين — أي مشروع/شاشة لا تحتاجها لا تتأثر إطلاقاً (لا تغيير على `PaginationQuery`/`PaginationCubit` الأساسيين).

**طريقة الدمج:**
```
# Backend (لكل موديول list جديد):
src/core/db/crud-helpers.ts              ← findManyPaginated(table, params, options) — options.orderBy إلزامي بالنوع
src/features/{module}/dtos/{module}.dto.ts  ← {module}FilterQuerySchema (Zod .strict()) بجانب DTOs الحالية
src/features/{module}/routes/*.routes.ts    ← paginationQuerySchema.merge({module}FilterQuerySchema)
src/features/{module}/repositories/*.repository.ts ← where/orderBy ديناميكيان من الفلتر
```
```dart
// Frontend (لكل feature تحتاج فلتر بشاشتها):
Features/{feature}/domain/params/{feature}_filter_params.dart  ← يطابق {module}FilterQuerySchema يدوياً (بلا أداة توليد)
Features/{feature}/presentation/cubits/{feature}_cubit.dart    ← filter field + applyFilter()/clearFilter()
Features/{feature}/presentation/pages/{feature}_list_screen.dart ← IconButton(Icons.filter_list) → AppFilterSheet.show<T>(...)
```
التفاصيل الكاملة خطوة بخطوة (مع أمثلة كود كاملة وchecklist): `qirtas_backend/docs/rest_api.md` §6.1 (عقد الـREST) و`qirtas_app/readme/pagination.md` §5.1 (التنفيذ بالفرونت).

**الاستقلالية:**
- الباك إند: `options.orderBy` إلزامي بالنوع، لكن **القيمة الافتراضية** (`desc(table.created_at)`) تُبقي نفس سلوك اليوم لأي موديول لا يحتاج فلترة فعلية — الإلزام على مستوى التوقيع فقط، لا فرض فلترة حقيقية.
- الفرونت: `filter` field على الـCubit افتراضه `const {Feature}FilterParams()` (كل الحقول null) — شاشة لا تستدعي `applyFilter()` مطلقاً تتصرف بالضبط كأن هذه الطبقة غير موجودة. لا تعديل على `PaginationCubit`/`PaginationQuery`/`PaginationBuilderWdg` نفسها.

**التطوير المستقبلي:**
- Discovery ديناميكي (الباك إند "يُعلن" عن حقول الفلترة القابلة للاستخدام بدل تكرار كتابتها يدوياً على الطرفين) — نُوقِش وتقرر تأجيله عمداً: يتطلب بناء أداة توليد OpenAPI→Dart كاملة (غير موجودة بالقالب حالياً)، مشروع مستقل أكبر من نظام الفلتر نفسه. راجع القرار الكامل بمحادثة بناء هذه الميزة قبل البدء بهذا الامتداد لتفادي إعادة نفس النقاش.
- ~~Free-text search منفصل عن الفلترة البنيوية~~ — **نُفِّذ**، راجع **#26**: `ListFilterBar` بالفرونت + `likeTerm()` بالباك.
- دعم فلترة بمدى تاريخ (date range) — الأعمدة الحالية المفلترة كلها enum/boolean، لا يوجد بعد مثال حي لمدى.

> **تصحيح بعد التنفيذ (2026-08-05)**: هذا البند وثّق العقد ونسي **نوع القيمة**. الفلاتر البوليانية شُحنت بـ`z.coerce.boolean()`، و`Boolean('false') === true` — فكان `?is_active=false` يُرجع كل الأدوار **النشطة**. خمسة فلاتر حملت العلّة معاً وكلها تعمل بلا خطأ. راجع **#21** و**#22**: عقدٌ صحيح بنوع خاطئ يُنتج جواباً معقولاً ومقلوباً، وهو أسوأ من الفشل.

---

### 18 — `SafeCubit` (حارس `emit` بعد `close`)

**ما هو:**
`abstract class SafeCubit<S> extends Cubit<S>` بـ`core/foundation/domain/` يتجاهل `emit` بعد الإغلاق بدل أن يرمي. كل cubit بالمشروع صار يرثه — و`PaginationCubit` نفسه صار يرثه، فكل قائمة محميّة بلا سطر إضافي.

**الفائدة للقالب:**
- `Bad state: Cannot emit new states after calling close` **انهيار حقيقي يصل نسخة الإصدار**، سببه لا أكثر من مغادرة شاشة قبل وصول ردّها. أي تطبيق فيه شاشة تجلب شيئاً سيلقاه.
- القالب كان **يظن أنه محميّ ولم يكن**: `BaseUseCase.cancel()` موجودة، وسبعة كيوبتس تستدعيها من `close()` — و`resetCancelToken` **بلا مستدعٍ واحد في `lib/` كلّه**، فالتوكن `null` دائماً وكل `cancel()` لا تفعل شيئاً. الحماية كانت تُقرأ بالمراجعة وتغيب بالتشغيل.
- الإلغاء الصحيح لا يُغني عنه أصلاً: الردّ قد يصل بين «تحليل الاستجابة» و«إغلاق الـcubit» مهما أُلغي بسرعة.

**طريقة الدمج:**
```
core/foundation/domain/safe_cubit.dart   ← الملف (Pure Dart — لا Flutter)
test/safe_cubit_test.dart                ← يثبّت السلوك
```
```dart
class MyCubit extends SafeCubit<MyState> { ... }   // بدل extends Cubit
```
موقعه بـ`foundation/` متعمَّد: `modules/` ممنوعة من استيراد `presentation/`، وحارسٌ ضد انهيار ليس شيئاً تُعيد وحدة مقيَّدة بناءه لتبقى داخل قواعد التبعية.

**الاستقلالية:**
صنف أساس إضافي — لا يُعدَّل أي cubit قائم إلا بكلمة واحدة بسطر التعريف. المشروع الذي لا يريده يبقى على `Cubit` بلا أي أثر.

**التطوير المستقبلي:**
- ربط `resetCancelToken` فعلياً بـDio ليُحرَّر المقبس أيضاً (متعامد على هذا، لا بديل عنه).
- lint مخصص يرفض `extends Cubit<` مباشرة.

---

### 19 — `MutationResult` (نتيجة الطفرة تُرجَع ولا تُبَثّ)

**ما هو:**
نوع صغير (`presentation/shared/mutation_result.dart`) يحمل `saved`/`failed`/`needsConfirmation` **ورسالة لمرة واحدة**. الطفرة تُرجعه، والشاشة تقوله وتنساه — بدل حمل رسالة الفشل داخل حالة الـcubit.

**الفائدة للقالب:**
- **الشكلان البديهيان شُحنا بقرطاس وكلاهما انكسر بصمت، وبطريقة مختلفة:**

| الشكل | ما حدث |
|---|---|
| **كحالة** `State.saveFailed` | كل طفرة تبدأ بـ`if (state is! Loaded) return`، فأول فشل يركن الـcubit حيث ترتدّ عنه الضغطة التالية — **خمس طفرات ميتة** حتى تُعاد الشاشة. وتكرار نفس الفشل يبني حالة **متساوية** فيُسقطها Cubit، فظهرت الرسالة مرة واحدة مهما ضغطت |
| **كعلَم** `bool saveFailed` | لزج: `copyWith` يحمل الـ`true` القديم للمحاولة التالية، فتظهر رسالة الخطأ **لحظة الضغط** قبل أن يغادر الطلب |

- والسبب الجذري واحد: **رسالة لمرة واحدة ليست حالة** — لا مدة لها، ووضعها بآلة حالات يمنحها مدةً لا تملكها.
- `needsConfirmation` مفصولة عن `failed` عمداً: رفضٌ يستطيع القارئ تجاوزه هو **سؤال لا حُكم**، فتعرض الشاشة «افعلها رغم ذلك» بدل لوحة رفض.

**طريقة الدمج:**
```dart
final result = await cubit.save(...);
if (result.isSaved) {
  context.feedback.success(LocaleKeys.saved.tr());
} else if (result.message != null) {
  context.feedback.error(result.message!);
}
```
`message` تكون `null` عند النجاح **وعند فشلٍ يملكه المعالج المركزي** (جلسة منتهية تُنقّل لصفحة الدخول بنفسها، ورسالة عابرة فوق شاشة مغادِرة ضجيج).

**الاستقلالية:**
نوع مستقل لا يعرف أي feature. الشاشة التي تفضّل `Future<bool>` تبقى تعمل — القاعدة الملزِمة هي **ألّا تُوضع الرسالة بالحالة**، لا استعمال هذا النوع بعينه.

**التطوير المستقبلي:**
- `MutationResult<T>` يحمل الكيان الناتج للشاشات التي تحتاجه.
- ورقة تأكيد قياسية تستهلك `needsConfirmation` مباشرة.

---

### 20 — `message_key` (سبب الرفض يُقرأ آلياً لا نصّياً)

**ما هو:**
عقد بالطرفين: الباك يرفق بكل رفض يقرؤه إنسان **مفتاحاً ثابتاً** بجانب النص (`ApiError.messageKey` → `data.message_key`)، والفرونت يحمله على `BusinessFailure.messageKey` ويتفرّع عليه. النص يبقى للعرض، والمفتاح للقرار.

**الفائدة للقالب:**
- كودان مختلفان يتشاركان نفس حالة HTTP بشكل روتيني، ونصّ الرسالة **نثرٌ مترجَم يتغيّر بتغيّر الصياغة**. التفرّع على النص هشّ بالتعريف.
- يُكمل **#16** (`ApiError.data`): ذاك مرّر الحمولة، وهذا يجعل لها **مفردات مسجَّلة**.
- الباك يحلّ المفتاح حسب `req.lang`، و`MESSAGES` مُقيَّدة بـ`satisfies Record<string, Record<Lang, string>>` — فترجمة ناقصة **لا تُشحن**، تكسر البناء.

**طريقة الدمج:**
```
# Backend
src/core/i18n/messages.ts            ← القاموس: مفتاح → {ar, en}
src/core/i18n/check-message-keys.ts  ← npm run check:messages
src/core/http/api-error.ts           ← messageKey على BusinessError/Forbidden/Unauthorized/RateLimit
```
```dart
// Frontend — core/foundation/errors/failure.dart
final class BusinessFailure extends Failure {
  const BusinessFailure({required this.statusCode, this.serverMessage, this.messageKey});
  final String? messageKey;   // ← تفرّع على هذا، لا على serverMessage أبداً
}
```

**الدرس الأهم — القاعدة المكتوبة بلا فاحص اقتراحٌ لا قاعدة:**
الشرط كان موثّقاً بـ`rest_api.md` §6.1 **منذ بناء نظام الرسائل**. وبتاريخ 2026-08-05 كشف تدقيق **٢٧ موضع رمي** بلا مفتاح — أحدها بلَّغ عنه مستخدم فعلي بعدما قرأ جملة إنجليزية وسط شاشة عربية. لا شيء يفشل ولا شيء يُسجَّل: الطريقة الوحيدة للاكتشاف أن تصطدم بذلك الرفض بعينه وتنظر للشاشة. لذلك النقطة الحقيقية بهذا البند ليست الحقل، بل **`npm run check:messages`**.

**الاستقلالية:**
`messageKey` اختياري بالطرفين وافتراضه `null`. كل موضع رمي قائم يبقى يعمل ويعود لنص `message` الإنجليزي. الفاحص يفحص **أربعة أصناف فقط** (`BusinessError`/`ForbiddenError`/`UnauthorizedError`/`RateLimitError`) — ما يصل المستخدم حرفياً؛ و`NotFoundError`/`ValidationError` مستثناة عمداً لأن العميل يرسم نصّه لـ404 و422 يحمل أخطاء حقول لا رسالة.

**التطوير المستقبلي:**
- ربط الفاحص بـCI (#09) فيمنع الدمج لا يكتفي بالإبلاغ.
- توليد ثوابت Dart من `MESSAGES` بدل كتابة السلاسل يدوياً بالفرونت.

---

### 21 — `queryBooleanSchema` (البوليان بالـquery لا يُكرَه) — Backend

**ما هو:**
Zod schema مشترك يقبل `'true' | 'false' | '1' | '0'` ويرفض ما عداه بـ422، **بديلاً إلزامياً عن `z.coerce.boolean()`** بكل فلتر بوليّاني على query string.

**الفائدة للقالب:**
- `z.coerce.boolean()` يطبّق `Boolean()` الخاص بجافاسكربت، وكل سلسلة غير فارغة صادقة — فـ`?is_active=false` يُحلّل إلى `true`. الفلتر **لا يفشل ولا ينبّه ويُرجع عكس المطلوب بالضبط**.
- ثبت حيّاً (2026-08-05): `GET /roles?is_active=false` أعاد كل دور **نشط**. ونفس الفخّ كان جالساً على `assignable` و`unassigned` و`is_admin` و`is_default` — خمسة فلاتر بعلّة واحدة.
- الرفض بـ422 مقصود: `?unassigned=yes` المكتوب خطأً يجب أن يكون **خطأً مرئياً**، لا `true` صامتاً.

**طريقة الدمج:**
```ts
// src/core/validation/common-schemas.ts
export const queryBooleanSchema = z
  .enum(['true', 'false', '1', '0'])
  .transform((v) => v === 'true' || v === '1');

// أي {module}FilterQuerySchema:
is_active: queryBooleanSchema.optional(),   // ❌ z.coerce.boolean().optional()
```

**الاستقلالية:**
schema مستقل بـ`core/validation/` — لا يُعدَّل شيء إلا استبدال النوع بموضع تعريف الفلتر. الوحدات التي لا تملك فلاتر بوليانية لا تراه.

**التطوير المستقبلي:**
- فاحص ثابت على غرار `check:messages` يرفض ظهور `z.coerce.boolean()` بأي مكان تحت `src/`.
- `queryNumberSchema`/`queryDateSchema` — نفس فئة الفخّ بأنواع أخرى.

---

### 22 — Contract Smoke Test (يؤكد العلاقات لا الأرقام) — Backend

**ما هو:**
سكربت `npm run smoke` يُشغَّل بمواجهة خادم حيّ، ويؤكد **ثوابت العقد** لا نتائج العمل: أن الفلتر البوليّاني ونقيضه يُرجعان مجموعتين **مختلفتين ومتكاملتين**، وأن القيمة غير الصالحة **تُرفض لا تُكرَه**، وأن كل انتقال دورة حياة موثَّق له نظير يمكن بلوغه، وأن العملية المحروسة ترفض بـ`message_key` الموثَّق.

**الفائدة للقالب:**
- كل عيب بُني هذا السكربت لالتقاطه كان **خفياً على المراجعة وعلى فاحص الأنواع، لأن أياً منها لم يفشل**: كلها أعادت جواباً معقول الشكل وخاطئاً.
  - `?is_active=false` يُرجع كل نشط (#21).
  - `POST /roles/:id/deactivate` شُحن **بلا نظير**، فالدور المتقاعد لا يعود أبداً. لا خطأ — الصف فقط توقّف عن الوجود من منظور الواجهة.
  - `level: null` (بلا سلطة) وصل فخُزِّن `0` (أعلى سلطة موجودة).
- الشكل المشترك: نظام لا يفرّق بين **«غائب»** و**«فاشل»**. فاحص الأنواع لا يراه، والمراجع لا يراه — وعدّان يجب أن يختلفا، مقارنان ببعضهما، يريانه.

**طريقة الدمج:**
```
src/core/db/smoke-test.ts   ← خارج مسار الإنتاج
package.json: "smoke": "tsx src/core/db/smoke-test.ts"
# npm run dev  (نافذة)  ثم  npm run smoke  (أخرى)
```
**قواعد ما يُضاف إليه — وهي جوهر البند:**
1. **قراءة فقط افتراضاً.** الكتلة الوحيدة المُعدِّلة تُنشئ دوراً مؤقتاً وتحذفه بـ`finally` — سكربت يترك خلفه ركاماً يتوقف الناس عن تشغيله.
2. **أكِّد العلاقات لا الأرقام المطلقة.** `active + inactive === all` ينجو من إعادة بذر؛ `total === 11` لا — واختبارٌ لا يُوثَق به لا يُشغَّل.
3. **كل فحص يُسمّي ما ينكسر لو سقط** — سطر أحمر بلا تفسير يُعاد تشغيله حتى يمرّ.

**الاستقلالية:**
ملف واحد + سطر بـ`package.json`. لا يُستورَد من أي كود إنتاجي، ولا يُشغَّل إلا يدوياً. المشروع الذي لا يريده يحذف السطر.

**التطوير المستقبلي:**
- تشغيله ضمن CI (#09) بمواجهة بيئة مؤقتة.
- توليد بعض فحوصه من وثيقة OpenAPI بدل كتابتها يدوياً.

---

### 23 — `NetworkLogInterceptor` (سطر لكل نجاح، وكل شيء عند الفشل)

**ما هو:**
Interceptor يطبع **سطراً واحداً** لكل طلب ناجح (`✅ GET /roles?page=1 · 200 · 142ms`)، و**الصورة كاملة** عند الفشل (الطريقة، الرابط، الحالة، جسم الطلب، جسم الرد)، ويُعلّم النجاح البطيء بلا إطالة. يُسجَّل **آخر السلسلة** فيرى النتيجة النهائية بعد المصادقة وإعادة المحاولة والكاش.

**الفائدة للقالب:**
- المسجّل السابق كان يطبع الطلب والرد كاملَين لكل نداء: إقلاعٌ واحد ينتج مئات الأسطر، والعطل الحقيقي سطران منها.
- وهذه ليست شكوى تجميلية: خطأَا `401` كانا يقعان **بكل إقلاع** طوال وجود تسخين الترجمة، ويطبعان `[FAILURE-MAPPER] ❌` كل مرة. الإشارة لم تغب قط — كانت **غير مقروءة**. لا أحد يمرّر جداراً من ٤٠٠ سطر بحثاً عن سطر أحمر لا يتوقعه.
- فالعلاج لخطأٍ فات لم يكن تسجيلاً أكثر، بل **أقلّ**.
- الأجسام تُقصّ بالسجل لا بالطلب: حمولة ٢٠٠ ك.ب مطبوعة كاملة هي نفس مشكلة القراءة بزيّ آخر.

**طريقة الدمج:**
```
core/infra/network/interceptors/network_log_interceptor.dart
app_features.dart: static const verboseNetworkLog = false;   ← اتركه false
```
`verbose` يعيد الخرطوم القديم **لجلسة تصحيح واحدة**؛ تركه مفعّلاً يعيد بالضبط الحالة التي أخفت تلك الـ401.

**تكملة (2026-08-10) — السطر الذي يحمل التشخيص لا يُرسَل بقناة جانبية:**
كان سبب العطل يُمرَّر عبر `LogService.error(error: err.message)` وحده، وهي معلمة `dev.log` — ووصولها للطرفية يتوقّف على القارئ، **ولم تصل**. فجهازٌ عجز عن بلوغ خادم التطوير أنتج سجلاً كاملاً نصّه `type: connectionError` ولا كلمة أخرى.

والكلمة هي التشخيص. `type` يقول «المقبس لم يوصِل» فقط، أما نصّ النظام تحته فيقول **أيّها** — وحلولها لا تشترك بشيء:

| النصّ | السبب | الحلّ |
|---|---|---|
| `Connection refused` | المضيف حيّ ولا شيء يستمع على المنفذ | شغّل الخادم / صحّح المنفذ |
| `No route to host` | شبكة فرعية خاطئة، أو نفق VPN ابتلع المسار | صحّح الـIP / راجع التوجيه |
| `Network unreachable` | الواجهة نفسها بلا مسار | الجهاز ليس على الشبكة |
| `Connection timed out` | الحزم تُسقَط بصمت | جدار ناري |

فصار السبب يُطبع **داخل** الرسالة (`cause:`)، ومن **حقلَي** Dio معاً (`message` و`error`) لأن أياً منهما قد يكون الفارغ — والاعتماد على واحد يطبع `null` بالضبط حين يسوء الأمر بما يكفي للحاجة إليه.

> **القاعدة**: ما يلزم لتشخيص فشل يُكتب **بمتن** السجل. القناة الجانبية (`error:`/`stackTrace:`) إضافةٌ للأدوات التي تقرؤها، لا مكانٌ للحقيقة الوحيدة.

**الاستقلالية:**
Interceptor واحد بسلسلة Dio + علَم واحد. لا كود ميزة يعرف بوجوده.

**التطوير المستقبلي:**
- ربط الفشل بـ`CrashReporter` (#05) كـbreadcrumb.
- عتبة البطء (`slowThreshold`) قابلة للضبط لكل بيئة.

---

### 24 — كاش الطلبات **opt-in** لا opt-out

**ما هو:**
قلب افتراضي بـ`RequestCacheInterceptor`: كان **كل** `GET` يُكاش خمس دقائق ما لم يُستثنَ؛ صار لا يُكاش شيء إلا ما طلب ذلك صراحةً بـ`extra: {cacheKey: true}`.

**الفائدة للقالب:**
- العيب لم يكن يبدو بياناتٍ قديمة، بل **ميزاتٍ معطوبة**:
  - التوثيق كان يقول «استدعِ `invalidate` بعد الطفرة». **لا شيء فعل ذلك أبداً.** فتعديل تعيين ثم إعادة قراءة القائمة داخل نافذة الـTTL يُرجع ما قبل التعديل — والشاشة تبدو وكأن الكتابة فشلت بصمت.
  - تغيّر **شكل** الرد (حقل جديد من الخادم) يبقى غير مرئي حتى تنتهي المهلة، فيبدو إصلاح الباك المنشور وكأنه لا يعمل. `branch_status` على التعيينات كان هذا حرفياً.
- تكييش ردٍّ **ادّعاءٌ بأن بياناته بطيئة التغيّر**. صحيح بالفهارس (الصلاحيات، اللغات)، وخاطئ بكل ما يعدّله أدمن. الافتراض «صحيح للجميع» كان يطلق هذا الادّعاء نيابةً عن كل endpoint.
- **والقاعدة الأعمّ**: إن احتاج مورد منطق إبطال ليبقى صحيحاً، فالأفضل ألّا يُكاش أصلاً.

**طريقة الدمج:**
```dart
dio.get('/permissions', options: Options(extra: {
  RequestCacheInterceptor.cacheKey: true,                 // ← اشتراك صريح
  RequestCacheInterceptor.ttlKey: const Duration(hours: 1),
}));
```
`skipKey` أُبقي عمداً: مواضع الاستدعاء القديمة تظل تعني «لا تُكاش» — وهو الافتراض الآن — فتصير بلا أثر بدل أن تنقلب سلوكياً بصمت.

**الاستقلالية:**
لا كود ميزة يتأثر: القلب يجعل السلوك الافتراضي **أكثر تحفّظاً**، والمشروع الذي كان يعتمد على الكاش يضيف مفتاحاً واحداً بمواضعه المقصودة.

**التطوير المستقبلي:**
- ربط الإبطال بـ`AuthEventBus` (مسح الكاش عند تبدّل المستخدم).
- `ETag`/`If-None-Match` بدل TTL زمني للفهارس الكبيرة.

---

### 25 — مفردات شاشة التفاصيل + `PermissionsPanel`

**ما هو:**
`DetailHeaderCard` · `DetailFact` · `DetailSectionHeader` بـ`shared/widgets/layout/detail_widgets.dart` — المفردات المشتركة لأي شاشة تفاصيل. ومعها `PermissionsPanel`: **الطريقة الوحيدة** لرسم الصلاحيات، بوضعَي عرض واختيار.

**الفائدة للقالب:**
- كل شاشة تفاصيل بقرطاس (مستخدم · فرع · دور · ملف شخصي) أنبتت `_IdentityCard` و`_Fact` **خاصَّين بها**. أربع نسخ من كلٍّ، **وقد تباعدت فعلاً**: اثنتان تدعمان أداة تعديل، واحدة تدعم سطر تلميح، اثنتان تفرضان LTR على الهواتف، وبعضها فقط **يذكر القيمة الغائبة** بدل حذف السطر. القارئ المنتقل بين الشاشات يقابل أربعة عروض مختلفة لفكرة واحدة، وأي إصلاح يُنفَّذ أربع مرات أو لا يُنفَّذ صامتاً.
- هذه المفردات هي **اتحادها**، فتكتسب الشاشة قدرةً بتمرير وسيط لا بإنبات نسخة خامسة.
- ومبادئ مضمَّنة بالنوع نفسه لا بالمراجعة: **الغائب يُذكر ولا يُحذف** (عنوان مفقود وعنوان لم يُدخله أحد يتطابقان لو اختفى السطر)، و**غير المتاح يغيب ولا يُعطَّل** (زر رمادي يدعو للمسة لن تعمل ولا يقول لماذا).
- `PermissionsPanel` يحلّ فرعاً من المرض نفسه: كان العارض يرسم الصلاحيات chips بـ`Wrap` والمحرّر يرسمها صفوفاً بقائمة — نفس البيانات، نفس التجميع، شكلان لا صلة بينهما، فلا ينتقل شيء تعلَّمه القارئ من النظر إلى التغيير.

**طريقة الدمج:**
```
shared/widgets/layout/detail_widgets.dart   ← DetailHeaderCard · DetailFact · DetailSectionHeader
shared/widgets/layout/permissions_panel.dart ← PermissionsPanel (display/selection)
```
التفاصيل الكاملة بالأمثلة: `readme/widgets.md`. ومرآة تفاعلية بـ`WidgetLibraryDemoScreen` (قانون المرآة).

**الاستقلالية:**
widgets إضافية لا تُعدِّل شيئاً. و`PermissionsPanel` يُعرِّف `PermissionItem` الخاص به عمداً بدل استيراد كيان الـfeature — `shared/` ممنوعة من استيراد `Features/`.

**التطوير المستقبلي:**
- `DetailFact.copyable` (نسخ الإيميل/الهاتف بلمسة) — يستهلك خدمة `clipboard` المفعَّلة أصلاً.
- تخطيط عمودين لهذه المفردات على التابلت — يعتمد على **#04**.

---

### 26 — البحث الحرّ: `ListFilterBar` + `likeTerm` (امتداد #17)

**ما هو:**
الطرف الثاني لنظام الفلترة: بحث نصّي حرّ (مؤجَّل 400ms) **مع شرائح تُظهر ما يُضيّق القائمة الآن** بالفرونت، و`likeTerm()` تهرّب `%` و`_` بالباك.

**الفائدة للقالب:**
- **الشرائح لا تقلّ أهمية عن صندوق البحث**: قائمة مفلترة ومنظمة فارغة **تتطابقان بصرياً**. فور وجود ما يضيّق النتائج، يجب أن يرى القارئ **ماذا** بلا فتح ورقة الفلتر، وأن يتراجع بلا مطاردة الأداة التي ضبطته. ولذلك تشمل الشرائح **نصّ البحث نفسه** — استثناؤه يجعل «لا نتائج» تُقرأ «لا يوجد شيء».
- موضعها بـ`AppBar.bottom` متعمَّد: جواب «لماذا أرى هؤلاء فقط؟» يجب ألّا ينزلق بعيداً عن الصفوف التي يفسّرها.
- **بالباك**: `%` غير المهرَّب يطابق كل صف، فيستنتج من كتبه أن البحث معطوب لا أن مدخله كان خاصاً؛ و`_` يطابق أي محرف واحد بصمت.

**طريقة الدمج:**
```dart
// shared/widgets/inputs/list_filter_bar.dart — يركّب AppSearchBar ولا يعيد بناءه
bottom: PreferredSize(
  preferredSize: Size.fromHeight(ListFilterBar.heightFor(hasActiveFilters: ...)),
  child: ListFilterBar(onSearch: ..., onClearSearch: ..., activeFilters: [...], onClearAll: ...),
)
```
```ts
// src/core/db/like-term.ts — والمستدعي يتخطّى القيمة الفارغة: '%%' يطابق كل شيء
ilike(usersTable.full_name, likeTerm(params.search))
```
`heightFor` يُرجع قيمتين لا واحدة: صفّ الشرائح لا يوجد إلا عند وجود فلتر فعّال، وحجز ارتفاعه دائماً يترك فجوة دائمة تحت صندوق البحث.

**⚠️ فخّ مرافق (شُحن مرتين بيوم واحد، 2026-08-06):** حساب `hasActiveFilters` داخل `appBar` يقع **فوق** الـ`BlocProvider`. الشكل الذي انهار كان أرحم؛ الشكل الذي تجاوز الـprovider بـ`getIt` **أجاب خطأً بصمت** — كل cubit قائمة مسجَّل `factory`، فبُنيت نسخة جديدة فلترها فارغ أبداً، فرُسمت الشرائح بارتفاع لا يتّسع لها مع تسريب cubit كل rebuild. الحلّ `Builder` أو فصل الشاشة لموفِّر ومستهلك — راجع `lib/Features/CLAUDE.md` §CRUD-PATTERNS.

**الاستقلالية:**
widget إضافي؛ القائمة التي لا تحتاج بحثاً لا تركّبه. و`likeTerm` دالة نقيّة لا تُستدعى إلا حيث يوجد فلتر بحث.

**التطوير المستقبلي:**
- ترتيب النتائج بالصلة (`ts_rank`) بدل `created_at` عند وجود بحث.
- إبراز المطابقة داخل الصف.

---

### 27 — `context.bottomContentInset` (آخر عنصر بالقائمة يجب أن يُرى)

**ما هو:**
`double get bottomContentInset => MediaQuery.of(this).padding.bottom` — المسافة التي يجب أن ينتهي عندها **محتوى قابل للتمرير** ليُرى آخره كاملاً، شاملةً شريط النظام **وأي شريط تنقّل سفلي فوقه**.

**الفائدة للقالب:**
- الفرق جوهري وليس تفصيلاً:

| | يقيس | داخل تبويب |
|---|---|---|
| `viewPadding.bottom` (`bottomPadding`) | شريط النظام وحده | ~٢٤ بكسل |
| `padding.bottom` (`bottomContentInset`) | + `NavigationBar` | ~١٠٠ بكسل |

- السبب: الشِّل يستخدم `extendBody: true`، فيمتدّ الـbody **خلف** شريط التنقّل، وFlutter يعوّض بحقن ارتفاع الشريط في `padding.bottom` — وهي القيمة الوحيدة التي تعرف أن الشريط هناك.
- **بلاغ حيّ (2026-08-06)**: لا واحدة من التبويبات الثلاثة كانت تحسب ذلك، رغم تعليق بالشِّل يقول إنها «محميّة بـ`SafeArea`» — ادّعاء لم يكن صحيحاً لأيٍّ منها. النتيجة: `LogoutSection` بالملف الشخصي **لا يظهر مهما نزلت**.
- **والعطل صامت تماماً**: الشاشة تُبنى وتُمرَّر ولا يُرمى شيء — تكتفي بألّا تُظهر آخرها. لذلك ثُبِّت بـ`test/bottom_content_inset_test.dart` لا بالمراجعة.
- **ولا يُحلّ بـ`SizedBox`** آخر القائمة: ذلك يحشو رقماً مُخمَّناً لا يعرف ارتفاع الشريط، ويبقى فراغاً ميتاً بالشاشات التي لا شريط تحتها. الحشوة تخصّ القائمة نفسها لا عنصراً بداخلها.

**طريقة الدمج:**
```dart
ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + context.bottomContentInset))
```
قيمة واحدة تخدم التبويب والمسار المدفوع معاً — فلا شرط ولا رقم يُخمَّن لكل شاشة.

**الاستقلالية:**
getter إضافي على extension قائم. الشاشات التي لم تُحدَّث تتصرف كما كانت (بعطلها).

**التطوير المستقبلي:**
- lint/فاحص يرفض `EdgeInsets` سفلية ثابتة على `ListView`/`SingleChildScrollView`.
- دمجه بالنظام التكيّفي (#04) عند بناء `NavigationRail` للتابلت — الشريط يصير جانبياً فتتغيّر القيمة تلقائياً.

---

### 28 — أقسام ذاتية التحميل داخل `ListView` (keep-alive)

**ما هو:**
قاعدة + اختبار: أي قسم يجلب بياناته بنفسه (`initState` أو `BlocProvider.create`) ويعيش داخل `ListView` **يجب** أن يستعمل `AutomaticKeepAliveClientMixin`.

**الفائدة للقالب:**
- `ListView` يتخلّص من الأبناء الذين يغادرون نطاق الكاش ويعيد بناءهم عند العودة — فيعاد التحميل مع كل تمريرة. **بلاغ حيّ**: النزول والصعود بالملف الشخصي كان يعيد جلب التعيينات كل مرة.
- الكلفة ليست شبكية فقط: المحتوى المحمَّل يرتدّ إلى مؤشر تحميل، **وما وسّعه القارئ يُفقد**.
- والقالب يشجّع هذا الشكل أصلاً — استثناءات `Features → Features` كلها widgets تملك cubit داخلياً وتُحمِّل عند التركيب (`UserAssignmentsSection`, `EntityHistorySection`, ...). فالفخّ مبنيّ في النمط الموصى به.

**طريقة الدمج:**
```dart
class _SectionState extends State<Section> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  @override Widget build(BuildContext context) { super.build(context); ... }  // ← إلزامي
}
```
و`PaginationBuilderWdg` يقبل `wantKeepAlive: true` أصلاً.

**الاختبار المزدوج — وهو الجزء المنقول للقالب:**
`test/section_keep_alive_test.dart` يؤكد الحالتين **معاً**: أن المحمي يُحمَّل مرة، **وأن غير المحمي يُحمَّل أكثر من مرة**. الثاني يثبت أن `ListView` فعلاً يتخلّص هنا — فبدونه قد ينجح الأول لأن الابن لم يغادر النطاق أصلاً، ويكون الاختبار قد أثبت لا شيء.

**الاستقلالية:**
mixin من Flutter نفسه + ملف اختبار. لا كود مشترك جديد.

**التطوير المستقبلي:**
- `KeepAliveSection` wrapper يغني عن تكرار الـmixin.
- إعادة تحميل مشروطة بمرور وقت (تتكامل مع `AppLifecycleService` #08).

---

### 29 — سجل التدقيق هو الماضي (لا جداول `*_history`)

**ما هو:**
قرار معماري: جدول `audit_log_entries` الذي يسجّل كل طفرة **بطرفَيها ووقتها** هو المصدر الوحيد للتاريخ — ولا يُنشأ جدول `*_history` مواز. ومعه `EntityHistorySection` بالفرونت (widget يُركَّب على أي شاشة تفاصيل بمفتاح هدف)، و`resolveNameAt()` بالباك.

**الفائدة للقالب:**
- الجدول كان يسجّل منذ 2026-08-04 **ولم يكن أي شيء يقرأه**. أرشيف بلا قارئ كلفة بلا فائدة، والقالب يستحق النمط الذي يجعله مقروءاً.
- **الاسم عبر الزمن مشتقّ لا مخزَّن**: صف التعيين يحمل اسم الدور **اليوم**، فتعيينٌ جرى والدور اسمه «كاشير» يُعرض «موظف مبيعات» بعد إعادة التسمية — والسجل يعيد كتابة ماضيه بصمت. الحلّ: ابدأ من الاسم الحالي وارجع خلال كل إعادة تسمية وقعت بعد التاريخ المطلوب.
- **ولماذا لا لقطة مخزَّنة على الصف؟** لأنها **مكان ثانٍ يعيش فيه الاسم**، والمكانان يختلفان أول مرة يُكتب أحدهما دون الآخر — وهو بالضبط العطل الذي دفع هذا المشروع ثمنه بمواضع أخرى. الكلفة استعلام واحد على فهرس موجود.
- **والقسم يغيب تماماً بلا صلاحية العرض**: 403 جوابٌ لا عطل، ولوحة حمراء بكل شاشة تفاصيل تُدرّب الناس على تجاهل اللوحات الحمراء.

**طريقة الدمج:**
```
# Backend
src/features/{module}/services/audit.service.ts   ← record() · resolveNameAt()
src/features/{module}/services/audit-actions.ts   ← ثوابت أسماء الأفعال (لا سلاسل حرّة)
```
```dart
// Frontend — يُركَّب بمفتاح هدف فقط، ويملك cubit داخلياً (نمط LogoutSection)
EntityHistorySection(targetEntity: AuditTarget.role(id))
```

**الاستقلالية:**
`record()` تُستدعى من الخدمات الموجودة بسطر واحد لكل طفرة. المشروع الذي لا يريد أرشيفاً لا يستدعيها، ولا يركّب الـwidget — والجدول يبقى فارغاً بلا أثر.

**التطوير المستقبلي:**
- تعميم `resolveNameAt` لأي حقل لا الاسم فقط.
- شاشة سجل عامة (لا مقيَّدة بكيان) لمن يملك `audit_log.view`.
- ضغط/أرشفة الصفوف القديمة — لم يلزم بعد.

---

### 30 — طبقة الترجمة البعيدة: كاش عند الإقلاع + تحرير داخل التطبيق

**ما هو:**
إكمال دورة `dynamic_localization`: (أ) قراءة الـoverrides من الكاش المحلي **بانتظار** عند الإقلاع وتحديثها بالخلفية **بلا انتظار**، (ب) عدم إطلاق الطلب أصلاً بلا جلسة مخزَّنة، (ج) مسار كتابة (`PUT /:code/translations`) يُحرَّر منه النص من داخل التطبيق.

**الفائدة للقالب:**
- **`AssetLoader.load()` يعمل أثناء بناء أول إطار**، فالـoverride الذي لا يوجد إلا بعد نداء شبكة **مضمون الغياب باللحظة الوحيدة التي يُقرأ فيها**. لهذا لم تعمل الطبقة كلها ولو مرة رغم أن الكود كان موجوداً.
- **عدم التناظر هو الفكرة كلها**: الترطيب من القرص يُنتظَر (مللي ثوانٍ معدودة)، والشبكة لا تُنتظَر (وإلا وقف اتصال متعثّر بين المستخدم وتطبيقه). النتيجة أن التعديل يظهر **بالإقلاع التالي** — وهي المقايضة الصحيحة لمحتوى يعدّله أدمن أحياناً، لا لشيء يجب أن يكون آنياً.
- **والتوكن يجب أن يُحمَّل هنا**: الـendpoint محروس بالمصادقة، و`AuthInterceptor` يقرأ التوكن **تزامنياً** من ذاكرة `SessionRepository` التي تملؤها `SplashCubit` — أي **بعد** `runApp()`. فكان التسخين يعمل بلا ترويسة `Authorization` ويجيب 401 **بكل إقلاع** (وهو مصدر الـ401 المذكور بـ#23). والتعليق القديم كان يدّعي أن الـinterceptor «يرفقه كأي طلب موثَّق» — لا يستطيع، لأن لا شيء حمّله بعد.
- **مفتاحان منفصلان للكاش** رغم أن البايتات واحدة: اللغة الديناميكية **مُصدَّرة برقم نسخة** والـoverride تحديث خلفي بلا نسخة — فكتابته عبر الأول تختم رقماً لم تتعلّمه الجلبة، و`hasUpdateAvailable` تعيد التنزيل أبداً أو تتخطّى تحديثاً حقيقياً.
- **ومسار الكتابة**: كان مبنياً **بلا مستدعٍ** منذ بناء الوحدة، فكان الجدول يُصان يدوياً بملف بذرة، ولم يكن لصلاحية تُنشأ عبر الـAPI طريق لتُسمّى.

**طريقة الدمج:**
```dart
// main.dart — الترتيب هو العقد
await service.hydrateOverridesFromCache(localeCodes);          // يُنتظَر (قرص)
final hasSession = (await getIt<SessionRepository>().loadCachedToken())?.isNotEmpty ?? false;
if (hasSession) for (final c in localeCodes) unawaited(service.refreshOverrides(c));  // لا يُنتظَر
```
والكتابة تمرّ عبر `DynamicLocalizationService` لا عبر الـrepository مباشرة: الوحدة تملك الكاش، فكاتبٌ خارجها يترك كاشاً تظنه الوحدة حديثاً.

**الاستقلالية:**
الوحدة اختيارية كما كانت. بلا جلسة مخزَّنة **لا يُطلَق طلب إطلاقاً** وتُعرض ar/en من نصّها المُصرَّف — وهو المسار الاحتياطي الموثَّق، مبلوغاً الآن بلا رحلة فاشلة.

**التطوير المستقبلي:**
- `refreshCurrentLocale` عند العودة من الخلفية (يتكامل مع #08).
- نسخ (versioning) لطبقة الـoverride ليصير التحديث مشروطاً لا غير مشروط.

---

### 31 — حرّاس المسار: `requirePermission` + `RateLimiter` عام — Backend

**ما هو:**
`requirePermission(key)` — middleware يفرض RBAC على مستوى المسار (اتحاد الصلاحيات عبر كل تعيين فعّال، بلا قواعد منع). و`RateLimiter` صنف عام بنافذة ثابتة يُنشأ منه حارس لكل مسار حسّاس، برسالة ومفتاح ترجمة خاصَّين به.

**الفائدة للقالب:**
- الحارس بالمسار يجعل الرفض **متسقاً وقابلاً للتدقيق** بدل تكراره داخل كل controller — ويجعل `ForbiddenFailure` (#13) و`CurrentUserRepository` (#15) طرفين لعقد واحد فعلاً.
- **الرسالة قابلة للتخصيص عمداً**: «محاولات دخول كثيرة» خاطئة ومربكة على فيضان تسجيل، والرسالة يقرأها شخص حقيقي. ومفتاح الترجمة (#20) يتبع `req.lang` كأي رفض آخر — تركه إنجليزياً كان سهواً.
- النصّ الإنجليزي يسمّي الصلاحية الناقصة **للسجلات**، والنصّ المترجَم لا يسمّيها — مفتاح صلاحية خام لا يعني شيئاً للقارئ.

**طريقة الدمج:**
```ts
router.get('/roles', requireAuth, requirePermission('roles.view'), listRoles);
const loginLimiter = new RateLimiter(5, 15 * 60_000, 'Too many login attempts…', 'too_many_login_attempts');
```

**الاستقلالية:**
middlewares تُركَّب على المسارات التي تحتاجها فقط. `RateLimiter` **بالذاكرة** — كافٍ لنشر بعملية واحدة، ويُستبدل بمخزن مشترك (Redis) لو تعدّدت النسخ؛ وإعادة التشغيل تصفّر العدّاد، وهو مقبول لحارس تخمين كلمات مرور.

**التطوير المستقبلي:**
- مخزن مشترك لتعدّد النسخ.
- `requireAnyPermission([...])` للمسارات التي يكفيها أحد مفتاحين.

---

### 32 — `{Entity}DetailOutcome` (ثلاثة أجوبة لا اثنان)

**ما هو:**
شاشة التفاصيل تُرجع `sealed class` بثلاث حالات (تعديل · حذف · لا شيء) بدل `Entity?`.

**الفائدة للقالب:**
- `Entity?` تملك **خانتين** بينما الواقع ثلاثة أجوبة. فلمّا وصل الحذف لم يجد ما يقوله بغير `null` — وهو نفسه «لم يتغيّر شيء». فبقيت القائمة تعرض صفاً لم يعد موجوداً. **الحذف نجح؛ قيمة الإرجاع فقط لم تستطع التعبير عنه.**
- **نتيجتان تحتاجان معالجة مختلفة لا تتشاركان خانة واحدة قابلة للعدم** — والقاعدة أعمّ من التفاصيل: تنطبق على أي شاشة تُرجع نتيجة.
- حالة الحذف تحمل **المعرّف لا الكيان**: ما تحتاجه القائمة هو أي صفّ تحذف، وإعطاؤها كياناً لسجلٍّ لم يعد موجوداً دعوةٌ لأن يرسمه أحد.

**طريقة الدمج:**
```dart
sealed class RoleDetailOutcome {}
class RoleUpdated extends RoleDetailOutcome { final Role role; }
class RoleDeleted extends RoleDetailOutcome { final int roleId; }   // معرّف لا كيان
// والمستدعي:
switch (await context.router.push<RoleDetailOutcome?>(...)) {
  case RoleUpdated(:final role): cubit.replaceEntityItem(role);
  case RoleDeleted(:final roleId): cubit.removeItemWhere((e) => e.id == roleId);
  case null: break;
}
```
`sealed` تُفعّل شمولية المُصرِّف، فحالةٌ ثالثة تُضاف لاحقاً لا تُنسى صامتةً.

**الاستقلالية:**
ملف واحد لكل feature تحتاجه. شاشات النموذج تبقى على `pop(entity)` — لأنها فعلاً جوابان.

**التطوير المستقبلي:**
- `DetailOutcome<T>` عام بـ`presentation/shared/` لو تكرّر بأكثر من ثلاث features.

---

### 33 — `common-schemas.ts` (قاعدة الحقل تُكتب مرة) — Backend

**ما هو:**
ملف Zod مشترك تُعرَّف فيه قاعدة كل نوع حقل متكرّر **مرة واحدة**، وتُستورد بكل DTO — بدل `z.string()` بسقف طول بكل موضع.

**الفائدة للقالب:**
- الفجوة عملية لا نظرية: قيمة مثل `"تر"` قُبِلت كـ`contact_info` لفرع، لأن الحقل كان سلسلة بحدّ طول لا أكثر.
- والقاعدة تُعرَّف بثلاث صور (`إلزامي` · `اختياري` · `قابل للعدم صراحةً` لأجسام PATCH التي تُفرِّغ الحقل) فلا يخترع أحد صيغة رابعة.
- **ويجب أن تُطابَق بالفرونت بنفس التغيير**: `CustomRegex.syrianPhoneRegex` بالفرونت يقابل `syrianPhoneSchema` بالباك حرفياً — طرف يتغيّر وحده يُنتج رفضاً لا يفهمه المستخدم أو قبولاً يرفضه الخادم.

**طريقة الدمج:**
```ts
// src/core/validation/common-schemas.ts
export const syrianPhoneSchema = z.string().trim().regex(/^09\d{8}$/, '…');
export const optionalSyrianPhoneSchema = syrianPhoneSchema.optional();
export const nullableSyrianPhoneSchema = syrianPhoneSchema.nullable().optional();
```
يستضيف أيضاً `queryBooleanSchema` (#21) — نفس المبدأ بنوع آخر.

**الاستقلالية:**
schemas مستوردة. الوحدة التي لا تملك حقل هاتف لا تراها. والقاعدة نفسها (نمط الرقم) تخصّ المشروع لا القالب — **المنقول للقالب هو المكان والصور الثلاث**، لا التعبير النمطي.

**التطوير المستقبلي:**
- توليد validators الفرونت من هذه الـschemas بدل مطابقتها يدوياً — يتطلب أداة OpenAPI→Dart، وهي مؤجَّلة عمداً (راجع #17).

---

### 43 — ميزات OpenType للعناوين (`ss01`) كطبقة بالثيم

**ما هو:**
الخط لا يُوصَف بعائلته ووزنه وحدهما. ملفات OpenType تحمل **ميزات** يُفعّلها المستهلك بالاسم، ومنها المجموعات الأسلوبية (`ss01`–`ss20`): أشكال بديلة عرّفها مصمّم الخط للحرف نفسه. القالب لم يكن يطلب أياً منها، فكان يعرض الشكل الافتراضي دائماً — ويدفع ثمن ملفٍ يحمل أكثر مما يُستعمل منه.

**ما نُفِّذ فعلياً (2026-08-10):**
`itfQomraArabic` — الخط الافتراضي بقرطاس — يحمل `ss01`–`ss04` مع `salt` و`dlig` و`calt` (**متحقَّق بمسح الملفات الثلاثة بايتياً**، لا بالوثائق). و`ss01` صار مطبَّقاً على `displayLarge`/`displayMedium`/`headlineLarge`/`headlineMedium` — أي ١٨ بكسل فما فوق — من داخل الثيم.

**الفائدة للقالب — وثلاث قواعد عامة أخرجها التنفيذ:**

**١. نقطة تطبيق واحدة، وإلا اختلف العنصر حسب طريقة الوصول إليه.**
القالب يوفّر طريقين للأنماط: `context.textTheme.headlineLarge` (Material) و`context.ts.headlineLg` (`AppTextStyles`). ويبدوان بديلين متكافئين — **وليسا كذلك**: `AppTextStyles` تبني كل نمط بـ`copyWith` على `Theme.of(ctx).textTheme` نفسه. فالتطبيق بـ`_textTheme()` وحده يصل الطريقين؛ ولو طُبِّق بـ`AppTextStyles` لظهر **العنوان نفسه مختلفاً بشاشتين** حسب أي وصول استعملته كل واحدة — فرقٌ لا يُنسَب لسببه أبداً.

**٢. ما يُولَّد آلياً يبتلع ما يُكتب داخله.**
الوجهة البديهية كانت حقلاً سادساً على `AppFontOption`. لكن كتلة `AppFonts.available` **مولَّدة** بـ`scripts/sync_fonts.dart`، والسكربت يُصدِر خمسة وسائط يعرفها فقط. فالحقل السادس يعيش حتى أول تشغيل تالٍ للسكربت ثم **يختفي**، وترتدّ العناوين لأشكالها العادية: لا فشل، لا تحذير، ولا سطر بالفارق يقرأه أحد. لذلك الخريطة **تحت** `// ── END GENERATED ──`.
> **القاعدة المعمَّمة:** أي قيمة تُكتب يدوياً داخل نطاق مولِّد لها **عمر افتراضي** — والمولِّد لا يُبلّغ عند حذفها.

**٣. السلّم المولَّد ليس كل العناوين — وأكثرها ظهوراً خارجه.**
`_textTheme()` تُعرّف ١٥ نمطاً، لكن الثيم يبني **أنماط عناوين كاملة بيدها** خارجها: `appBarTheme.titleTextStyle` (١٨) و`dialogTheme.titleTextStyle` (٢٠). فأول تنفيذ غطّى السلّم وفوّتهما — و**عنوان الـ`AppBar` هو أكثر عنوان يظهر بالتطبيق**: ٦٩ موضعاً، ٦٦ منها لا تمرّر نمطاً إطلاقاً فتأخذ هذا الافتراضي. أي أن القاعدة الموثَّقة («١٨ فما فوق») كانت **تتخطّى معظم العناوين** بينما تبدو مطبَّقة بالكامل.
> **القاعدة المعمَّمة:** حين تُطبَّق سمة على «كل س»، عدّ مواضع تعريف س أولاً. السلّم المركزي يجذب الانتباه، والاستثناءات المكتوبة يدوياً هي التي تُفوَّت — وهي غالباً الأكثر استعمالاً.
>
> والدواء بنيوي لا انتباهي: `final headingFeatures = ...` **متغيّر محلّي واحد** بأعلى `_theme()` تستهلكه المواضع الأربعة، فالنمط الخامس الذي يُكتب لاحقاً يجد القيمة أمامه بدل أن يستدعي الخريطة من جديد أو ينساها.

**٤. الميزة غير المدعومة تُتجاهَل بصمت — فالمعاينة المفردة لا تُثبت شيئاً.**
المُشكِّل لا يخطئ عند طلب وسم لا يُعرّفه الخط؛ يتجاهله. فسطرٌ يحمل `ss01` وسطرٌ لم يطلبه **متطابقان بالبكسل** حين يكون الوسم مفقوداً أو مكتوباً خطأً أو الملف مُحوَّلاً بصيغة أسقطت ميزاته. لذلك مرآة `TestThemeDemoScreen` تعرض **«مع» و«بدون» جنباً لجنب**: إن تطابق السطران فالميزة لا تصل النص. وهذا نفس شكل الأعطال الذي يجمعه هذا الملف — نتيجة حسنة الشكل لا تكشف عن نفسها.

**طريقة الدمج:**
```dart
// core/infra/config/app_fonts.dart — تحت END GENERATED
static const Map<String, List<FontFeature>> _headingFeatures = {
  'itfQomraArabic': <FontFeature>[FontFeature('ss01')],
};
static List<FontFeature> headingFeaturesFor(String family) =>
    _headingFeatures[family] ?? const <FontFeature>[];

// presentation/theme/app_theme.dart — نقطة التطبيق الوحيدة
textTheme: _textTheme(..., AppFonts.headingFeaturesFor(fontFamily)),
// وداخل _textTheme: fontFeatures: headingFeatures على الطبقات الأربع الكبيرة
```
`FontFeature('ss01')` لا `FontFeature.stylisticSet(1)`: متطابقتان أثراً، لكن الثانية **مصنع** فلا تصلح داخل `const`.

**لماذا العناوين وحدها:**
هذه البدائل مرسومة لأحجام العرض. و`headlineSmall` (١٤) هو **عنوان البطاقة** بهذا التطبيق، يتكرّر نازلاً بقائمة كاملة بحجم النصّ العادي — فالشكل البديل يصير ضجيجاً، وعرضه الأوسع يزاحم صفوفاً تقصّ نصّها أصلاً (قواعد `Text` بـ`lib/CLAUDE.md`). الحدّ **١٨ بكسل فما فوق**، ويشمل عنوانَي الـ`AppBar` والحوار.

**التثبيت — `test/heading_font_features_test.dart` (١٣ فحصاً، ٣ مجموعات):**
| المجموعة | تُثبت |
|---|---|
| العناوين ≥١٨ **تحمل** `ss01` | أن الميزة تصل الأنماط الستة — بما فيها المكتوبان يدوياً |
| ما دون الحدّ **لا يحمل** | أن الخطأ المعاكس لم يقع: تطبيقها على كل شيء |
| عائلة `sans` **لا تحمل شيئاً** | أن الخريطة **تُستشار فعلاً** — بدون هذه المجموعة كان وسمٌ مُثبَّت بالثيم يُرضي المجموعتين الأوليين |
لا يُكتفى بالأولى: النجاح وحده لا يميّز «مطبَّقة صحيحاً» عن «مطبَّقة على الجميع» عن «مُثبَّتة بالكود». والفحص على `TextStyle` المُحلّ لا على البكسل، لأن الأثر البصري لا يُختبر آلياً — لكن **طلب** الميزة يُختبر.

**الاستقلالية:**
عائلة بلا مدخل بالخريطة تحصل على `const []` — أي سلوك اليوم بالضبط، وهو حال `NotoSansArabic`/`NotoSans`. المشروع الذي يبدّل خطه لا يرث قراراً خاصاً بقمرة، ولا شاشة واحدة تُعدَّل: الشاشات لا تعرف بوجود الميزة.

**التطوير المستقبلي:**
- تجربة `ss02`–`ss04` بصرياً واختيار الأنسب لكل مستوى عنوان (المرآة تُظهر الفرق فوراً).
- `dlig` (الحروف المركّبة) لشاشات محدّدة كالسبلاش — أثقل بصرياً من أن يُعمَّم.
- توسيع `sync_fonts.dart` ليكتشف الميزات المتاحة بكل ملف ويُدرجها **كتعليق** بجانب العائلة — فيعرف من يضيف خطاً ما يملكه بلا مسح يدوي.

---

## مرشَّحات مختبر الودجات — التفاصيل (34–42)

**المصدر:** `D:\awqaf_app\Archive\test_apps\widgets` — تطبيق Flutter مستقل فيه ٩ وحدات، كلٌّ منها بهيكل `config/ · logic/ · model/ · cubit/ · ui/ · demo/` وشاشة عرض حيّة.

**ما يجعله مرشَّحاً جيداً للقالب:** التبعيات الإضافية **اثنتان فقط** (`local_auth` · `shared_preferences`) — فسبعٌ من التسع **Flutter صرف بلا أي حزمة جديدة**. والوحدات مبنيّة أصلاً على المنافذ (`abstract interface class` + تنفيذ وهمي)، وهو نفس نمط `modules/` بالقالب.

**ما رُفض من المختبر بعد الفحص — موجود بالقالب فعلاً:**

| المرفوض | البديل القائم |
|---|---|
| `micro_interactions/ui/shimmer_loading.dart` | `ShimmerLoadingWidget` + `SkeletonWidget` (#10) |
| `smart_search/logic/search_debouncer.dart` | `AppSearchBar.debounceDuration` (400ms، مبني ومستعمل) |
| `core/localization/*` (نظام ترجمة بديل بملفات Dart) | `easy_localization` + مولّد المفاتيح + طبقة override (#30) — **لا تُدمَج**، نظاما ترجمة بمشروع واحد يعني مكانين للنص |
| `biometric_auth/logic/biometric_service.dart` | `core/platform/` → `BiometricsService` خلف `AppFeatures.biometrics` |

---

### 34 — Guided UX (جولات إرشادية بأهداف مُسجَّلة)

**ما هو:**
محرّك جولات تعليمية: `GuidedTarget(id:)` يلفّ أي widget فيسجّل مفتاحه بسجلّ (`GuideTargetRegistry`) يحوّله لاحقاً إلى `Rect` بإحداثيات الـoverlay، وطبقة تُبرز الهدف وتشرحه. الجولة تُعرَّف بخطوات وقواعد إطلاق (`firstTime` · `always` · `afterAction(id)` · `custom(condition)`)، وتقدّمها محفوظ.

**الفائدة للقالب:**
- **الاستئناف هو الميزة الحقيقية**: `GuideProgress` يحفظ الخطوة الحالية والخطوات المرئية، فالمستخدم الذي أغلق التطبيق بمنتصف الجولة يعود إلى **حيث توقّف** لا إلى البداية ولا إلى «انتهت». والجولة غير المتكرّرة (`repeatable: false`) لا تُعاد بعد إتمامها.
- **الهدف يُفكّ تسجيله عند `dispose`** — فجولة تشير إلى زر بشاشة أُغلقت لا تُبرز مستطيلاً في الفراغ.
- الحاجة حقيقية بقرطاس: شاشات مثل محرّر صلاحيات الدور أو `UserAssignmentsSection` تحمل مفاهيم (مستوى السلطة، النقل مقابل الإنهاء) تُشرح اليوم بالنص وحده أو لا تُشرح.

**قبل الدمج:**
- التخزين بالمختبر `SharedPreferences`؛ القالب يستعمل `StorageService` (Hive) — **يُستبدل المحوّل، لا تُضاف حزمة**. الواجهة `GuideStorage` موجودة أصلاً فالاستبدال تنفيذٌ واحد.
- النصوص تمرّ عبر `LocaleKeys` وتُخزَّن كمفاتيح لا كنصوص جاهزة (وإلا تجمّدت الجولة بلغة واحدة).
- `Rect` يُحسب على محاور مطلقة — يجب اختباره بـRTL قبل الاعتماد.

**الاستقلالية:**
`GuidedTarget` بلا سجلّ مركّب يمرّر ابنه كما هو (`KeyedSubtree`)، فالشاشة المُعلَّمة تعمل تماماً بلا الوحدة. علَم واحد + عدم تعريف أي `Guide` = صفر أثر.

---

### 35 — Session Guard (قفل بعد خمول / عند الخلفية)

**ما هو:**
`SessionWrapper` يلفّ الشجرة، يرصد التفاعل (`Listener` للّمس + `NotificationListener<ScrollNotification>` للتمرير) فيصفّر مؤقّت الخمول، ويعرض طبقة قفل عند انتهائه أو عند ذهاب التطبيق للخلفية (`lockOnBackground`)، مع فتح اختياري بالبصمة.

**الفائدة للقالب:**
- **متطلب فعلي لأي تطبيق إداري**: قرطاس يعرض بيانات موظفين وصلاحيات على جهاز يُترك على مكتب. وهذا البند بالضبط ما ذكره **#08** كتطوير مستقبلي («قفل تلقائي بعد ٣ دقائق بالخلفية») — والوحدة تنفيذه الجاهز.
- **الحماية موضعية لا شاملة**: `protectRoutes` تقصر القفل على مسارات بعينها، فشاشة الدخول أو الترحيب لا تُقفَل بلا معنى.
- `gracePeriod` مفصولة عن `sessionTimeout` — مهلة سماح قصيرة بعد العودة تمنع قفلاً يُقرأ كعطل لمن بدّل تطبيقاً لثانيتين.
- التفاعل يُرصد **بالتمرير أيضاً** لا باللمس وحده: قارئٌ يمرّر قائمة طويلة نشطٌ تماماً، وقفلٌ يفاجئه وسط القراءة هو أسوأ ما بهذه الميزات.

**قبل الدمج:**
- يُربط بـ`AppLifecycleService` القائم (`AppFeatures.appLifecycle = true` أصلاً) بدل `WidgetsBindingObserver` مستقل — راصدان لدورة الحياة بتطبيق واحد يتباعدان.
- البصمة عبر `BiometricsService` القائم لا عبر `local_auth` مباشرة.
- القفل **ليس** تسجيل خروج: يجب ألّا يمسّ `SessionRepository` ولا يُطلق `AuthEventBus.sessionExpired` — وإلا صار الخمول يُنهي الجلسة فعلاً.

**الاستقلالية:**
`enabled: false` يُرجع الابن كما هو بلا أي `Stack` أو مستمع. يُقترح `AppFeatures.sessionLock`.

---

### 36 — `MicroFeedbackController` + `AnimatedTapButton`

**ما هو:**
متحكّم صغير بحالة واحدة (`idle → loading → success/error`) يعود تلقائياً إلى `idle` بعد مدة تعليق (`successHold` ~950ms، `errorHold` ~1150ms)، و`run(task)` يديرها كلها حول عملية واحدة. و`AnimatedTapButton` يستهلكه: تصغير عند الضغط + تبديل المحتوى واللون حسب الحالة.

**الفائدة للقالب:**
- **يكمل قاعدة «كل طفرة تُعلن نتيجتها»** (`lib/CLAUDE.md`) بشكل موضعي: الإعلان اليوم رسالة عابرة أعلى الشاشة، والزر نفسه لا يقول شيئاً. مع هذا، **الزر الذي ضُغط هو الذي يجيب** — وهو أقرب مكان ينظر إليه المستخدم.
- **ومفارقة مقصودة مع #19**: هناك قلنا إن رسالة لمرة واحدة **ليست حالة** لأن لا مدة لها. هنا العكس تماماً — هذه الحالة **لها مدة صريحة** (`holdFor`)، ولذلك تصحّ كحالة داخل متحكّم يملك مؤقّتها ويلغيه عند `dispose`. القاعدة واحدة: *ما له مدة يُخزَّن، وما لا مدة له يُقال ويُنسى.*
- `run()` تلتقط الاستثناء وتُظهر `error` — فلا مسار نجاح صامت ولا فشل بلا أثر بصري.

**قبل الدمج:**
- الألوان تُمرَّر اليوم كـ`Color?` مباشرة — تُستبدل بـ`context.colors.*` التزاماً بقاعدة الألوان الصارمة.
- يُدمَج مع `PrimaryButton` القائم بدل إضافة زر منافس: `isLoading` موجودة فيه أصلاً، والناقص `success`/`error` والتعليق المؤقّت.
- يُربط بخدمة `haptics` المفعَّلة (`AppFeatures.haptics = true`) فيتزامن الاهتزاز مع تبدّل الحالة.

**الاستقلالية:**
`MicroInteractionDurations.defaults` ثابتة قابلة للتمرير؛ ومَن لا يمرّر متحكّماً يحصل على زر عادي بتأثير ضغط فقط.

---

### 37 — Feature Flags وقت التشغيل (أسبقية معلنة + مصدر لكل قيمة)

**ما هو:**
خدمة تُقيّم كل علَم عبر سلسلة أسبقية صريحة — **افتراضي ← بيئة ← بعيد ← تجاوز محلي** — وتُرجع مع كل قيمة **مصدرها** (`FeatureFlagValueSource`) لا القيمة وحدها.

**الفائدة للقالب:**
- القالب اليوم يملك طرفين ولا ثالث بينهما: `AppFeatures` **ثوابت وقت تصريف** (لا تتغيّر إلا بإصدار)، و`modules/remote_config/` **قارئ مفاتيح مسطّح** (`getBool(key)`) بلا فهرس ولا أسبقية ولا تجاوز محلي. فسؤال «لماذا هذه الميزة مفعَّلة عند هذا المستخدم؟» بلا جواب.
- **إرجاع المصدر هو البند كلّه**: `enabled = true` وحدها لا تُصحَّح؛ «مفعَّلة **لأن تجاوزاً محلياً** ضبطها» تُصحَّح فوراً. وهذا بالضبط شكل الأعطال التي جمعها هذا الملف — قيمة صحيحة الشكل لا يُعرف من أين جاءت.
- التجاوز المحلي يجعل الاختبار على جهاز واحد ممكناً بلا لمس إعدادات الخادم.

**قبل الدمج:**
- **لا يُستبدل به `modules/remote_config/`** بل يجلس فوقه: `FeatureFlagsRemoteSource` واجهة، وتنفيذها يستدعي `RemoteConfigService.getBool` القائم.
- `_localOverrides` بالذاكرة فقط — تُفقد بإعادة التشغيل؛ تُحفظ بـ`StorageService` لتصير مفيدة فعلاً.
- التجاوز المحلي يجب أن يكون **debug فقط** أو محروساً بصلاحية: علَمٌ يُطفئه المستخدم بنفسه بالإنتاج ثغرةٌ لا ميزة.

**الاستقلالية:**
فهرس فارغ = لا أعلام = صفر أثر. و`AppFeatures` تبقى كما هي لما يجب أن يُحسم وقت التصريف (أذونات المنصّة، تسجيل خدمات DI) — وهذا **فصل مقصود**: ما يغيّر شكل الحزمة لا يُقرَّر وقت التشغيل.

---

### 38 — مركز إشعارات داخل التطبيق (قواعد + تجميع + حالة قراءة)

**ما هو:**
مدير إشعارات **داخل التطبيق**: بثّ تفاعلي للقائمة، تجميع حسب مفتاح مجموعة، حالة مقروء/غير مقروء، جدولة مؤجَّلة قابلة للإلغاء، وقاعدتان للإطلاق — **حدث** (`triggerEvent('order_shipped')`) و**سلوك** (`trackBehavior(key)` يُطلق بعد تكرار يبلغ عتبة، مع تصفير اختياري). ومعه شريط داخل التطبيق وشاشة مركز إشعارات.

**الفائدة للقالب:**
- `modules/push_notifications/` القائم **ناقلٌ لا مركز**: بثّ الأمامية، بثّ النقر، توكن، مواضيع. لا يوجد **أين تذهب الرسالة بعد وصولها** — لا سجل، لا مقروء، لا تجميع. المستخدم الذي أغلق الشعار فقد المحتوى إلى الأبد.
- **التجميع يمنع الطوفان**: خمس إشعارات من نفس النوع تصير مجموعة واحدة مرتَّبة بالأحدث، لا خمسة صفوف تدفع الباقي خارج الشاشة.
- **قاعدة السلوك** مفردة نادرة ومفيدة: «بعد ثالث محاولة فاشلة اعرض المساعدة» يُعبَّر عنها بتعريف واحد بدل عدّادات متناثرة بالشاشات.
- والتخصيص كلّه بمنافذ: `SmartNotificationLocalAdapter` افتراضه ذاكرة، فيُوصَل لاحقاً بالإشعارات المحلية (`AppFeatures.localNotifications`).

**قبل الدمج:**
- القائمة **بالذاكرة فقط** — تُفقد بإعادة التشغيل. تحتاج طبقة تخزين (`StorageService`) وإلا فمركز إشعارات ينسى كل شيء.
- بلا ترقيم صفحات؛ لأعداد كبيرة يُربط بـ`PaginationCubit`.
- `dispose()` يدوية — يُحوَّل إلى `@lazySingleton` بدورة حياة DI، أو cubit يرث `SafeCubit` (#18).

**الاستقلالية:**
بلا قواعد وبلا استدعاء `show()` لا يحدث شيء. مستقل تماماً عن FCM — يعمل بلا Firebase.

---

### 39 — Smart Form (نموذج متعدد الخطوات تعريفي) — **مشروط**

**ما هو:**
نموذج يُعرَّف بياناتٍ لا بشجرة widgets: خطوات، وحقول لكل خطوة، ولكل حقل **مدقّقات متزامنة** و**مدقّق لا متزامن واحد** (تحقّق بالخادم — إيميل مستعمل مثلاً) واقتراحات ثابتة أو من مزوّد. والخدمة تدقّق خطوةً كاملة أو النموذج كلّه، ومؤشّر تقدّم يرافقها.

**الفائدة للقالب:**
- **ترتيب التدقيق هو الجزء الذي يستحق النقل**: المتزامن أولاً لكل الحقول، ثم اللامتزامن **فقط لما نجا منه**. فلا يُرسَل نداء شبكة للتحقق من قيمة مرفوضة محلياً أصلاً — وهي الغلطة التي يقع فيها كل تنفيذ يدوي لهذا.
- `isValidating` منفصلة عن `error`، فالحقل قيد التحقق لا يبدو صالحاً ولا فاسداً.

**لماذا «مشروط»:**
`lib/Features/CLAUDE.md` §FORMS-GUIDE يفرض نمطاً **أمرياً** واضحاً (`Form` + `GlobalKey` + `_submitted`/`_isLoading`) يعمل جيداً، وكل نماذج قرطاس تتبعه. نمطان للنماذج بمشروع واحد كلفةٌ لا تُدفَع إلا بمقابل.
**فالشرط**: لا يُدمَج إلا عند ظهور نموذج **متعدد الخطوات فعلاً** أو حقل يحتاج تحقّقاً بالخادم أثناء الكتابة. ودون ذلك يبقى §FORMS-GUIDE هو الطريق الوحيد، ويُوثَّق هذا صراحةً حتى لا يختار كل مطوّر ما يفضّله.

---

### 40 — Fuzzy Search (ترتيب بالصلة) — ⚠️ **لا يعمل بالعربية حالياً**

**ما هو:**
دالة تسجيل نقاط نقيّة ترتّب المطابقات: تطابق تام (320) ← احتواء (240−) ← بداية كلمة (220−) ← متتالية جزئية (150−) ← مسافة Levenshtein ضمن حدّ مسموح يتناسب مع طول الاستعلام (200 − 28×المسافة). ومطابقة متعددة الكلمات تُجمَّع بمتوسط أفضل نتيجة لكل كلمة.

**الفائدة للقالب:**
- يكمل **#26**: `likeTerm` بالباك تجيب «يحتوي أو لا»، وهذه تجيب **«أيّها أقرب»** — والفرق يظهر بقوائم يبحث فيها المستخدم عن اسم يعرفه تقريباً.
- تسامح الأخطاء المطبعية مضبوط بطول الاستعلام (حرف واحد للقصير) فلا تنهار الدقّة على استعلام من حرفين.
- **دالة نقيّة بلا حالة ولا تبعيات** — تصلح لـ`core/foundation/` مباشرة، وقابلة للاختبار بالكامل.

**⚠️ العيب المانع (مُتحقَّق منه بالقراءة، لا مفترضاً):**
```dart
static String _normalize(String value) {
  final lower = value.toLowerCase().trim();
  final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');   // ← هنا
  return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
}
```
كل محرف خارج `a-z0-9` يُستبدَل بمسافة — **والعربية كلها خارجه**. فأي نصّ عربي يُطبَّع إلى سلسلة فارغة، و`score` تُرجع `0` عند الفراغ. النتيجة: البحث عن «كاشير» يُطابق **صفر** نتائج، **بلا خطأ ولا تحذير** — وهو حرفياً شكل العطل الذي يجمعه هذا الملف: جوابٌ حسن الشكل وخاطئ تماماً.

**قبل الدمج (إلزامي):**
1. توسيع التطبيع للعربية: الإبقاء على `\u0600-\u06FF`، وتوحيد الهمزات (أ/إ/آ ← ا) والتاء المربوطة/الهاء والألف المقصورة/الياء، وحذف التشكيل والتطويل — وإلا فـ«علي» و«على» غريبان.
2. اختبار وحدة بمدخلات عربية **قبل** أي استعمال — العيب صامت، فالمراجعة لا تكفي.
3. تُشغَّل على صفحة محمَّلة فقط لا كبديل عن بحث الخادم: البيانات المرتَّبة بالصلة يجب أن تكون كلها بالذاكرة.

---

### 41 — Smart Input (منافذ QR/OCR بتدرّج آمن) — **منافذ فقط**

**ما هو:**
ثلاث واجهات (`SmartQrScannerSource` · `SmartImageInputSource` · `SmartTextExtractorSource`) وخدمة تركّبها، تعرض **الخيارات المتاحة فعلاً** حسب ما هو موصول (`getAvailableOptions()`) ولا تعرض إلا الممكن.

**الفائدة للقالب:**
- **التدرّج الآمن هو الفكرة**: الإدخال اليدوي متاح دائماً، وخيار الكاميرا/المعرض يظهر **فقط** إن وُجد ماسح **وقارئ نصّ** معاً. فلا زر يقود إلى «غير مدعوم» — وهذا نفس مبدأ #25 («غير المتاح يغيب ولا يُعطَّل») مطبَّقاً على القدرات لا الصلاحيات.
- تصنيف أخطاء صريح (`qrUnavailable` · `captureCanceled` · `noTextDetected` · `ocrUnavailable`) يفصل **الإلغاء** عن **الفشل** — وهو تمييز يُهمَل عادةً فيظهر خطأ أحمر لمن ضغط «رجوع».

**قبل الدمج — بصراحة:**
الوحدة **منافذ بلا محوّلات حقيقية**: التنفيذات الموجودة كلها `Scripted*` (وهمية للعرض). لا كاميرا ولا ML Kit. فالمنقول للقالب هو **شكل المنفذ والتدرّج**، والتشغيل الفعلي يتطلب حزمة ماسح + محرّك OCR وتفعيل أذونات `camera`/`photos` بـ`AppFeatures` وتشغيل `sync_permissions.dart`.

**الاستقلالية:**
بلا مصادر موصولة تُرجع الخدمة خيار الإدخال اليدوي وحده — أي سلوك حقل نصّي عادي.

---

### 42 — طبقة UX للمصادقة الحيوية (فوق `BiometricsService` القائم)

**ما هو:**
ما ينقص القالب حول البصمة: تصنيف أخطاء مفصَّل (غير مسجَّلة · غير مدعومة · مقفلة مؤقتاً · مقفلة دائماً · أُلغيت) بحالات cubit مطابقة، وودجت جاهز يعرض لكل حالة ما يُفعل بها.

**الفائدة للقالب:**
- `AppFeatures.biometrics` و`BiometricsService` موجودان — لكنهما يجيبان **«نجح أم لا»**. و«لا» هنا خمس حالات لكلٍّ **مخرج مختلف**: «سجّل بصمتك من الإعدادات» ليست «حاول بعد ٣٠ ثانية» وليست «جهازك لا يدعمها» وليست «أنت ألغيتها». تكديسها برسالة واحدة يترك المستخدم بلا خطوة تالية.
- ونفس المبدأ الذي جعل تمييز حالات رفض الدخول الأربع (#16) يستحق البناء — الحالة تُسمّى برمجياً، والواجهة تعطي المخرج المناسب.

**قبل الدمج:**
- **لا يُنسخ `biometric_service.dart` من المختبر**: القالب يملك خدمته بـ`core/platform/`، والمنقول هو تصنيف الأخطاء وطبقة العرض فوقها.
- تُربط بـ**#35** (فتح القفل) لا كبديل عن تسجيل الدخول — البصمة تُثبت أن **الجهاز** بيد صاحبه، لا أن الجلسة صالحة على الخادم.

---

## قواعد إضافة اقتراح جديد

```
1. يجب أن يكون opt-in (feature flag أو parameter اختياري)
2. لا يُكسِر أي كود موجود عند عدم استخدامه
3. يتبع نمط core/platform/ + core/infra/ للـ services
4. له Demo في Features/test/ (قانون المرآة)
5. يُوثَّق في هذا الملف قبل التنفيذ
6. إن كان قاعدة يجب أن يلتزم بها كل مطوّر → له **فاحص آلي** أو اختبار،
   لا سطر بالتوثيق وحده (راجع #20: قاعدة مكتوبة بلا فاحص اقتراحٌ لا قاعدة)
```

### ما علّمه التطبيق العملي عن هذه القواعد نفسها

البنود 18–33 كلها جاءت من أعطال **شُحنت ومرّت المراجعة**. والقاسم المشترك بينها تقريباً كلها أن **لا شيء فشل**:

| الشكل | أمثلة | ما يكشفه |
|---|---|---|
| **جواب معقول ومقلوب** | `?is_active=false` يُرجع النشط · `level: null` يُخزَّن `0` | مقارنة عدّين يجب أن يختلفا (#22) — لا مراجعة ولا فاحص أنواع |
| **حماية تُقرأ ولا تعمل** | `cancel()` وتوكن `null` أبداً (#18) · تعليق «محميّة بـSafeArea» (#27) · `invalidate` بلا مستدعٍ (#24) | تتبّع مستدعٍ فعلي، ثم اختبار يثبّت السلوك |
| **إشارة موجودة وغير مقروءة** | ٤٠٠ سطر سجل تخفي `401` متكرّراً (#23) | تقليل الإخراج لا زيادته |
| **قيمة تُخزَّن مكاناً لا يخصّها** | رسالة لمرة واحدة داخل الحالة (#19) | سؤال: هل لهذه القيمة **مدة**؟ |
| **نسخة رابعة من فكرة واحدة** | `_IdentityCard` بأربع شاشات (#25) · عارض/محرّر صلاحيات منفصلان | البحث بـ`shared/` قبل بناء أي widget |

**القاعدة المستخلَصة:** الميزة التي «تعمل» ولم يتحقّق أحد من **نقيضها** لم تُختبر بعد.

---

## مرجع الـ Feature Flags الحالية

> مطابق لـ`lib/core/platform/features/app_features.dart` **بهذا المشروع** بتاريخ 2026-08-10.

```dart
abstract final class AppFeatures {
  // ── Debug / Development ──
  static const debugSkipLogin      = true;   // ← القالب: مفعَّل للعرض. اضبطه false بأي مشروع
  static const verboseNetworkLog   = false;  // ← #23 — اتركه false

  // ── Platform permissions ──  (كلها false — sync_permissions.dart يقرؤها)
  static const camera = false;      static const microphone = false;
  static const location = false;    static const locationAlways = false;
  static const photos = false;      static const fileStorage = false;
  static const contacts = false;    static const bluetooth = false;
  static const pushNotifications = false;

  // ── Optional modules ──
  static const localNotifications  = false;
  static const offlineSync         = false;
  static const multiDevice         = false;

  // ── Firebase-backed ──  (تحتاج google-services.json / GoogleService-Info.plist)
  static const crashReporting      = false;  // ← #05
  static const analytics           = false;
  static const remoteConfig        = false;

  // ── Optional platform services ──
  static const biometrics          = false;
  static const clipboard           = true;   // ← مُفعَّل
  static const shareSheet          = false;
  static const fileOperations      = false;
  static const appLifecycle        = true;   // ← مُفعَّل — #08
  static const haptics             = true;   // ← مُفعَّل — #02
  static const certificatePinning  = false;
}
```

> **`screenshotPrevention` (#06) لم يُنفَّذ** — البند ما زال ⬜ معلقاً، والعلَم غير موجود بالملف. لا تنسخه من هنا قبل بناء الخدمة.
