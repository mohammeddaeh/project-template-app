# Template Enhancements — خارطة تطوير القالب

> **الغرض:** توثيق كل اقتراح تطويري للقالب — ما هو، لماذا، كيف يُدمَج، وكيف يبقى منفصلاً.
> **القاعدة الذهبية:** كل إضافة = **feature flag** أو **abstract service** — لا تأثير على المشاريع التي لا تحتاجها.

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

| # | الاقتراح | الأولوية | الحالة | نوع الدمج |
|---|---|---|---|---|
| 01 | Predictive Back (Android 14+) | 🔴 عالية | ✅ مُنفَّذ | Widget مستقل |
| 02 | Haptic Feedback Service | 🔴 عالية | ✅ مُنفَّذ | Platform Service + feature flag |
| 03 | Lottie Animations | 🔴 عالية | ✅ مُنفَّذ | State Widgets بديلة |
| 04 | Adaptive / Responsive Layout | 🔴 عالية | ⬜ معلق | Breakpoint utility |
| 05 | Crash Reporting (Sentry/Crashlytics) | 🟡 متوسطة | ⬜ معلق | Abstract service + feature flag |
| 06 | Screenshot Prevention | 🟡 متوسطة | ⬜ معلق | Platform Service + feature flag |
| 07 | Deep Linking | 🟡 متوسطة | ⬜ معلق | Router pattern |
| 08 | App Lifecycle Service | 🟡 متوسطة | ⬜ معلق | Platform Service + feature flag |
| 09 | GitHub Actions CI | 🟢 تجميلي | ⬜ معلق | ملفات YAML خارج lib/ |
| 10 | Skeleton Widget Variants | 🟢 تجميلي | ✅ مُنفَّذ | shared/widgets/ |
| 11 | Hijri Calendar Support | 🟢 تجميلي | ⬜ معلق | Utility + Widget |
| 12 | Error Boundary Widget | 🟢 تجميلي | ⬜ معلق | shared/widgets/wrappers/ |

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

**التطوير المستقبلي:**
- نشر تلقائي لـ Firebase App Distribution عند merge لـ main
- تشغيل integration tests على device farm
- Slack notification عند نجاح/فشل الـ build

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

## قواعد إضافة اقتراح جديد

```
1. يجب أن يكون opt-in (feature flag أو parameter اختياري)
2. لا يُكسِر أي كود موجود عند عدم استخدامه
3. يتبع نمط core/platform/ + core/infra/ للـ services
4. له Demo في Features/test/ (قانون المرآة)
5. يُوثَّق في هذا الملف قبل التنفيذ
```

---

## مرجع الـ Feature Flags الحالية

```dart
// lib/core/platform/features/app_features.dart
class AppFeatures {
  static const biometrics          = false;
  static const clipboard           = false;
  static const shareSheet          = false;
  static const fileOperations      = false;
  static const appLifecycle        = false;
  static const certificatePinning  = false;
  // ← الإضافات الجديدة هنا:
  static const haptics             = false;
  static const crashReporting      = false;
  static const screenshotPrevention = false;
}
```
