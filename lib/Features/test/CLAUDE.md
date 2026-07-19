# lib/Features/test/CLAUDE.md — قانون المرآة التفاعلية

> **هذه الـ Feature مرآة حية للـ Template — لا showcase ثابتة.**
> كل تغيير في أي موديول يُعدَّل انعكاسه هنا **في نفس المهمة**.

---

## مبدأ المرآة

```
Template Module  ──→  Dashboard Screen
     ↕ (مزامنة دائمة)       ↕
  يتغير          ──→  يتغير معه
```

الـ Dashboard ليس شرحاً — هو **تجربة تفاعلية** تُثبت أن الموديول يعمل بكل خياراته.

---

## هيكل الشاشات

```
lib/Features/test/
├── presentation/
│   ├── pages/
│   │   ├── test_dashboard_screen.dart         ← البوابة الرئيسية
│   │   ├── test_forms_demo_screen.dart        ← مرآة §FORMS-GUIDE
│   │   ├── test_states_demo_screen.dart       ← مرآة State Widgets
│   │   ├── test_theme_demo_screen.dart        ← مرآة AppColors + AppPalette
│   │   ├── test_settings_demo_screen.dart     ← مرآة Settings Feature
│   │   ├── test_form_validation_screen.dart   ← سيناريو #05 — Form Guards
│   │   ├── test_pagination_demo_screen.dart   ← سيناريو #03 — PaginationCubit
│   │   ├── test_crud_demo_screen.dart         ← سيناريو #04 — CRUD + Optimistic
│   │   ├── test_predictive_back_demo_screen.dart ← PopScope + حراسة الرجوع
│   │   ├── test_haptics_demo_screen.dart      ← HapticService
│   │   ├── test_feature_wizard_screen.dart    ← سيناريو #01 — معالج Feature
│   │   ├── test_nav_stack_screen.dart         ← سيناريو #02 — Stack visualizer
│   │   ├── test_platform_services_screen.dart ← سيناريو #11 — AppFeatures flags
│   │   ├── test_failure_demo_screen.dart      ← سيناريو #07 — Failure → UiAction
│   │   ├── test_connectivity_screen.dart      ← سيناريو #13 — Network + Lifecycle
│   │   ├── test_sync_queue_screen.dart        ← سيناريو #10 — محاكاة offline-first
│   │   ├── test_bloc_states_screen.dart       ← سيناريو #06 — آلة حالات Freezed
│   │   └── test_api_simulator_screen.dart     ← سيناريو #12 — محاكاة REST pipeline
│   └── widgets/
│       └── demo_card.dart
└── CLAUDE.md  ← هذا الملف

⚠️ widget_library_demo_screen.dart تعيش في lib/shared/screens/ (ليست هنا) — لكنها جزء من منظومة الـ Showcase.
```

---

## قواعد إضافة Control تفاعلي

### 1. Enum جديد أو قيمة جديدة

```dart
// مثال: FeedbackStyle أضيف له قيمة جديدة "banner"
// → أضف segment في _FeedbackStyleSelector داخل WidgetLibraryDemoScreen

SegmentedButton<FeedbackStyle>(
  segments: [
    ButtonSegment(value: FeedbackStyle.motionToast, label: Text('Motion')),
    ButtonSegment(value: FeedbackStyle.snackbar,    label: Text('Snack')),
    ButtonSegment(value: FeedbackStyle.simpleToast, label: Text('Simple')),
    ButtonSegment(value: FeedbackStyle.banner,      label: Text('Banner')), // ← جديد
  ],
  ...
)
```

### 2. Widget بـ Variants متعددة

```dart
// مثال: PaginationCubit دعم loadingStyle جديد
// → أضف selector + عرض حي في سيناريو #03

// Pattern:
// - SegmentedButton لاختيار الـ variant
// - مساحة عرض تتغير مع الاختيار
// - label يُظهر اسم الـ class/enum المستخدم
Column(children: [
  _VariantSelector(
    label: 'Loading Style',
    options: PaginationLoadingStyle.values,
    selected: _style,
    onChanged: (v) => setState(() => _style = v),
  ),
  const SizedBox(height: 16),
  _LivePreview(style: _style),  // يُظهر النتيجة الفعلية
])
```

### 3. Service / Platform Feature

```dart
// مثال: BiometricsService أضيف
// → أضف card في سيناريو #11

_ServiceCard(
  title: 'Biometrics',
  enabled: AppFeatures.biometrics,
  enabledHint: 'app_features.dart → biometrics = true',
  onTest: AppFeatures.biometrics
      ? () async {
          final ok = await getIt<BiometricsService>().authenticate();
          context.feedback.info(ok ? 'Authenticated' : 'Failed');
        }
      : null,
)
```

---

## Pattern: _VariantSelector (معيار موحّد)

استخدم هذا الـ pattern لكل اختيار في الـ Dashboard:

```dart
class _VariantSelector<T extends Enum> extends StatelessWidget {
  const _VariantSelector({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textTheme.headlineSmall),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<T>(
            segments: options
                .map((e) => ButtonSegment(value: e, label: Text(e.name)))
                .toList(),
            selected: {selected},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ),
      ],
    );
  }
}
```

---

## Pattern: _LivePreview (معيار موحّد)

كل control يجب أن يكون مصحوباً بمعاينة حية فورية:

```dart
// ✅ صحيح — اختيار + نتيجة في نفس الشاشة
Column(children: [
  _VariantSelector(..., selected: _loadingStyle, onChanged: (v) => setState(() => _loadingStyle = v)),
  const SizedBox(height: 16),
  AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: KeyedSubtree(
      key: ValueKey(_loadingStyle),
      child: _buildPreview(_loadingStyle),  // ← النتيجة الفعلية
    ),
  ),
])

// ❌ خاطئ — اختيار بدون نتيجة مرئية فورية
```

---

## جدول المرآة التفصيلي

| الموديول | الملف | الشاشة | الـ Control المطلوب |
|---|---|---|---|
| FeedbackStyle | `presentation/feedback/feedback_style.dart` | `WidgetLibraryDemoScreen` | `SegmentedButton<FeedbackStyle>` |
| AppFeedbackService methods | `presentation/feedback/app_feedback_service.dart` | `WidgetLibraryDemoScreen` | زر لكل method |
| PaginationCubit options | `presentation/shared/pagination/` | سيناريو #03 | Sliders + Toggles |
| AppStateWidgets | `shared/widgets/` | `TestStatesDemoScreen` | Card لكل widget |
| AppColors semantic tokens | `presentation/theme/app_colors.dart` | `TestThemeDemoScreen` | جدول ألوان تلقائي |
| AppPalette raw colors | `presentation/theme/app_palette.dart` | `TestThemeDemoScreen` | palette grid تلقائي |
| AppFontOption | `core/infra/config/app_fonts.dart` | `TestSettingsDemoScreen` | قائمة typography |
| AdaptiveThemeMode | `adaptive_theme` | `TestSettingsDemoScreen` | `SegmentedButton<AdaptiveThemeMode>` |
| AppLocale | `core/platform/locale/app_locale.dart` | `TestSettingsDemoScreen` | `SegmentedButton<bool>` |
| §FORMS-GUIDE patterns | `Features/CLAUDE.md` §FORMS-GUIDE | `TestFormValidationScreen` | Toggle autoValidate/guard/API error + IndicatorBar |
| PaginationCubit loadingStyle | `presentation/shared/pagination/` | `TestPaginationDemoScreen` | SegmentedButton + Sliders + 4 loading styles |
| `PageLoadingStyle` enum | `shared/widgets/indicators/page_loading_indicator.dart` | `TestPaginationDemoScreen` | SegmentedButton (6 أنماط) + Live preview + `loadingItemWidget` |
| CRUD Optimistic patterns | `Features/CLAUDE.md` §CRUD-PATTERNS | `TestCrudDemoScreen` | Add/Edit/Delete + Event Log + Rollback |
| PopScope patterns | `Features/test/presentation/pages/test_predictive_back_demo_screen.dart` | `TestPredictiveBackDemoScreen` | 3 سيناريوهات: Free · Confirm · DirtyGuard + counter حي |
| HapticService | `core/platform/haptics/haptic_service.dart` | `TestHapticsDemoScreen` | 4 أزرار intensity + 5 feedback chips مع auto-haptic |
| Lottie (AppStateWidget) | `shared/widgets/states/app_state_widget.dart` | `TestStatesDemoScreen` | Toggle "With Lottie / With Icon" + `lottieAsset`/`lottieSize` params |
| Skeleton Templates | `shared/widgets/placeholders/skeleton_templates.dart` | `WidgetLibraryDemoScreen` → Skeleton Templates | `SegmentedButton<_SkeletonVariant>` + `AnimatedSwitcher` live preview لكل variant |
| Platform Services | `core/platform/` + `app_features.dart` | `TestPlatformServicesScreen` | card لكل خدمة مع chip Enabled/Disabled + أزرار test للمُفعَّل |
| Failure types | `core/foundation/errors/failure.dart` | `TestFailureDemoScreen` | chip لكل failure type + **مسار متحرك خطوة بخطوة** عبر الطبقات حتى `UiAction` (`FailureUiMapper.toAction`) |
| Freezed states + BlocConsumer | `Features/CLAUDE.md` §FREEZED | `TestBlocStatesScreen` | آلة حالات تفاعلية: Load/Reset/Inject Error + snippet يتبدّل مع الحالة + سجل انتقالات |
| REST pipeline | `core/infra/network/` (محاكاة) | `TestApiSimulatorScreen` | 6 مراحل مع توقيت حي + حقن فشل (NoInternet/Timeout/500/Parse) + نتيجة `FailureUiMapper` فعلية |
| AutoRoute stack | `routes/router.dart` | `TestNavStackScreen` | Stack visualizer: push/replace/replaceAll/pop + جدول "متى تستخدم" |
| Feature architecture | `Features/CLAUDE.md` | `TestFeatureWizardScreen` | 5 خطوات (Domain→Data→UseCases→Route→Presentation) مع snippets قابلة للنسخ |
| NetworkStateMonitor + AppLifecycleService | `core/platform/connectivity/` + `core/platform/lifecycle/` | `TestConnectivityScreen` | streams حية + سجل أحداث مختوم بالوقت |
| Sync offline-first pattern | `modules/sync/` (محاكاة) | `TestSyncQueueScreen` | toggle online/offline + **طابوران مستقلان**: معلَّق (يتفرّغ تلقائياً بعد النجاح، لا يحتفظ بالسجل) وأخطاء (يحتاج تدخلاً: retry/clear) + معالجة تلقائية عند العودة |

---

## قواعد صارمة لا استثناء

1. **لا تُغلق مهمة تمسّ موديولاً في الجدول أعلاه بدون تحديث الشاشة المقابلة.**
2. **لا تُضيف option/variant لـ widget موجود بدون إضافة control له في الـ Demo.**
3. **كل control جديد → `_LivePreview` يُظهر الفرق الفعلي (ليس مجرد log أو toast).**
4. **الـ Demo يعمل بدون network — كل البيانات mock أو fake في الـ presentation layer.**
5. **إذا أُضيف سيناريو من `readme/test_scenarios_roadmap.md` → غيّر حالته من ⬜ إلى ✅.**

---

## كيفية إضافة شاشة Demo جديدة

```
1. أنشئ: lib/Features/test/presentation/pages/{name}_demo_screen.dart
2. أضف @RoutePage() على الـ class
3. lib/routes/router.dart: أضف AutoRoute(page: {Name}DemoRoute.page, path: '/test/{name}')
4. dart run build_runner build --delete-conflicting-outputs
5. test_dashboard_screen.dart: أضف _CardData جديدة
6. هذا الملف: أضف صفاً في جدول المرآة
7. readme/test_scenarios_roadmap.md: غيّر حالة السيناريو إلى ✅
```
