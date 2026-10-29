# الحالات والتحميل والرسائل

> جزءٌ من دليل الودجات — الفهرس الكامل والاستيراد بـ[`../21_WIDGETS_USAGE.md`](../21_WIDGETS_USAGE.md).

> **Import الوحيد:** `package:app_template/ui/widgets/widgets.dart` — والاستثناءات بـ§DIRECT-IMPORTS بالفهرس.


---

## §3 · AppStateWidget — حالات الشاشة

> widget واحدة تُغطي جميع حالات الشاشة (فارغة / خطأ / تحميل / صيانة / لا اتصال).

**Aliases جاهزة للاستخدام السريع:**

```dart
// Loading
const LoadingWidget()

// Empty
EmptyStateWidget(
  titleKey: LocaleKeys.noItems,
  descriptionKey: LocaleKeys.addFirstItem,
  icon: Icons.inbox_outlined,
  actionLabelKey: LocaleKeys.addItem,
  onAction: () => context.router.push(const ItemFormRoute()),
)

// Error
ErrorStateWidget(
  messageKey: errorMessage,
  onRetry: () => context.read<MyCubit>().load(),
)

// No Internet
const NoInternetWidget()

// Maintenance
const MaintenanceWidget()
```


---

## §4 · context.feedback — Toast / Snackbar

> **Import إلزامي في كل ملف:**
> ```dart
> import 'package:app_template/ui/feedback/feedback_extension.dart';
> ```

**Usage**

```dart
// ── الحالات الأساسية ──
context.feedback.success(LocaleKeys.saved.tr());
context.feedback.error(LocaleKeys.somethingWentWrong.tr());
context.feedback.warning(LocaleKeys.unsavedChanges.tr(), title: LocaleKeys.warning.tr());
context.feedback.info(LocaleKeys.dataUpdated.tr());
context.feedback.toast(LocaleKeys.copied.tr());

// ── تجاوز الـ adapter لرسالة واحدة ──
context.feedback.error(
  LocaleKeys.connectionFailed.tr(),
  style: FeedbackStyle.snackbar,   // Snackbar لهذه الرسالة فقط
);
context.feedback.toast('تم النسخ', style: FeedbackStyle.simpleToast);

// ── مع action (مثلاً: retry) ──
context.feedback.show(context, FeedbackConfig(
  type: FeedbackType.error,
  message: LocaleKeys.connectionFailed.tr(),
  action: FeedbackAction(label: LocaleKeys.retry.tr(), onTap: _retry),
));
```

**FeedbackStyle** — تجاوز الـ adapter per-call دون تغيير الـ DI:

| القيمة | الوصف |
|--------|-------|
| `FeedbackStyle.motionToast` | toast منزلق من الأعلى (الافتراضي) |
| `FeedbackStyle.snackbar` | Material SnackBar مع زر action |
| `FeedbackStyle.simpleToast` | toast مبسط من الأسفل (للنسخ وما شابه) |

> ❌ `ScaffoldMessenger.of(context).showSnackBar(...)` مباشرة
> ✅ `context.feedback.error(msg)` أو مع `style: FeedbackStyle.snackbar`


---

## §17 · PaginationBuilderWdg — قوائم مرقَّمة

> يتولى جميع حالات التحميل / الخطأ / الفراغ / التمرير للتحميل.

**متطلبات:**
- `{Name}Cubit` يـ `extend PaginationCubit<{Entity}>`
- يُغلَّف بـ `BlocProvider<{Name}Cubit>`
- يُلغى الطلب في `close()` بـ `_{useCaseName}.cancel()`

```dart
BlocProvider(
  create: (_) => getIt<OrdersCubit>()..load(),
  child: PaginationBuilderWdg<OrdersCubit, OrderEntity>(
    loadingItemsWidget: const OrdersShimmer(),
    itemWdg: (order) => OrderCard(order: order),
    separatorWidget: const DashedDivider(),
    notItemsMsg: LocaleKeys.noOrders.tr(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    wantKeepAlive: true,
  ),
)
```


---

## §18 · ShimmerLoadingWidget / SkeletonWidget — تحميل

> `ShimmerLoadingWidget` يلف Containers بيضاء.
> `SkeletonWidget` مستقل — **لا تضعه داخل ShimmerLoadingWidget.**

```dart
// ── Shimmer قائمة ──
ShimmerLoadingWidget(
  baseColor: const Color(0xFFE0E0E0),
  highlightColor: const Color(0xFFF5F5F5),
  child: ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 6,
    itemBuilder: (_, __) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
)

// ── Skeleton نص مستقل ──
SkeletonWidget(width: 140, height: 14)
SkeletonWidget(width: 80, height: 14)
```


---

## §22 · Connectivity — حالة الاتصال

```dart
const OfflineBanner()           // شريط أحمر أعلى الشاشة
const SubtleOfflineDot()        // نقطة حمراء مضغوطة
ReconnectCountdownChip(onRetry: _retry)   // chip مع عدّ تنازلي
```

> `ConnectivityOverlay` **لا يُركَّب بشاشة، ولا يأخذ `child`**. هو مركَّب مرة
> واحدة بـ`_ConnectivityLayer` داخل `MaterialApp.builder` بـ`app.dart`، تحت
> `Positioned.fill`، فيغطي كل مسار وورقة.


---

## §26 · AppProgress — مؤشر تحميل/تقدّم موحَّد

> بديل إلزامي لـ`CircularProgressIndicator`/`LinearProgressIndicator`/`CupertinoActivityIndicator` (R35 · F35 — فاحص آلي). `value: null` ⇒ غير محدّد، `0.0–1.0` ⇒ محدّد ويتحرّك — نفس الودجة.

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `value` | `double?` | `null` | `null` = غير محدّد |
| `tone` | `AppProgressTone` | `brand` | `brand` · `accent` · `success` · `warning` · `danger` · `neutral` · `onBrand` |
| `size` | `AppProgressSize` | `md` | `xs` · `sm` · `md` · `lg` (دائري فقط) |
| `dimension` | `double?` | — | يتجاوز `size` للدائري |
| `centered` | `bool` | `false` | يوسّط داخل الأب |
| `center` | `Widget?` | — | محتوى وسط الدائرة (نسبة، أيقونة) |
| `label` | `String?` | — | نص أسفل الشريط الخطي |

**Usage**

```dart
const AppProgress.circular()                                  // تحميل افتراضي
const AppProgress.circular(size: AppProgressSize.xs)           // داخل شارة أو حقل
const AppProgress.circular(centered: true)                     // وسط الشاشة
AppProgress.linear(value: .65, tone: AppProgressTone.accent, label: '52 / 80')
AppProgress.circular(
  value: .65,
  dimension: 54,
  center: GlyphCenter(child: Text('65%')),
)
```


---

## §29 · ErrorBoundary — بديل انهيار `build()`

> **`ErrorBoundary` نقطة تركيب لا ودجةٌ تُستهلك بشاشة** — تُستدعى مرّةً من
> `main.dart` قبل `runApp`، فتستبدل شاشة فلاتر الرمادية الافتراضية بـ
> `ErrorFallback` لأي `build()` ينهار. و`ErrorFallback` مُصدَّرةٌ من الباريل
> (F21 يُلزم بذلك) لكن لا تُبنى يدوياً بشاشة عادية — فلاتر هو من يبنيها عبر
> `ErrorWidget.builder`. راجع [`_template/roadmap.md`](https://github.com/mohammeddaeh/project-template-app/blob/master/_template/roadmap.md) بند #10
> للسياق الكامل.

**Usage** (مرّةً واحدة، بالفعل موصولة بـ`main.dart`)

```dart
ErrorBoundary.install();   // قبل runApp — انظر lib/main.dart
```

⚠️ **النطاق محدودٌ بسلوك فلاتر نفسِه لا بكودٍ هنا**: العنصر الذي ينهار بناؤه
هو وحده الذي يُستبدل — لا الشجرة كلّها. وهي **عرضٌ فقط**؛ `FlutterError.onError`
(ومن ثمّ `modules/crash_reporting` إن كان مفعَّلاً) يستقبل الخطأ نفسه بصرف
النظر عمّا يُرسم. ونصّ الاستثناء الحقيقي لا يظهر إلا بـ`kDebugMode` — بالإصدار
يظهر `LocaleKeys.unknownError` وحده.


---

## §31 · StatusFeedbackIndicator — أيقونة حالة دائرية

> نبضة عند الانتقال إلى `StatusTone.success`، اهتزاز عند الانتقال إلى
> `StatusTone.error` (نفس صيغة الاهتزاز بـ§30 وPIN غير الصحيح). يستهلك نفس
> ألوان `StatusChip` (`AppColors.status*`) — **لا لونَ خاماً هنا**، ونفس
> مؤشّر التحميل الموحَّد `AppProgress.circular` (لا `CircularProgressIndicator`
> خام — يمنعه F35). يحترم "تقليل الحركة" — لا نبضة ولا اهتزاز عندها، الأيقونة
> تتبدّل مباشرةً.

**Usage**

```dart
StatusFeedbackIndicator(
  tone: state.tone,      // StatusTone.success بعد نجاح إجراء
  isLoading: state.isBusy,
  size: 74,               // اختياري — الافتراضي 64
)
```

⬜ **بالمكتبة بلا مستهلكٍ بعد** — مرشَّحٌ لأول شاشة إجراءٍ غير متزامن (حفظ،
رفع، تحقّق) تحتاج ردّاً بصرياً واحداً بدل نصٍّ/toast فقط.
