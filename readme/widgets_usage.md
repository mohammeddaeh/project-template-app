# Widget Library — دليل الاستخدام

> **Import الوحيد لجميع الـ widgets:**
> ```dart
> import 'package:app_template/shared/widgets/widgets.dart';
> ```
> استثناءات في §DIRECT-IMPORTS.

---

## فهرس

| الـ Widget | النوع | القسم |
|-----------|-------|-------|
| `AppButton` | زر | §1 |
| `PrimaryButton` | زر (توافق) | §2 |
| `AppStateWidget` | حالات الشاشة | §3 |
| `context.feedback.*` | Toast / Snackbar | §4 |
| `CustomTextField` | إدخال | §5 |
| `AppSearchBar` | إدخال | §6 |
| `AppSelectField<T>` | إدخال | §7 |
| `ChipRow<T>` | إدخال | §8 |
| `AppNavBar` | تخطيط | §9 |
| `AppCard` | تخطيط | §10 |
| `AppListTile` | تخطيط | §11 |
| `ExpandableSection` | تخطيط | §12 |
| `KeyValueRow / KeyValueSection` | عرض بيانات | §13 |
| `StatCard` | عرض بيانات | §14 |
| `StepProgressIndicator` | عرض بيانات | §15 |
| `AppLabel` | تصنيف | §16 |
| `PaginationBuilderWdg` | قوائم | §17 |
| `ShimmerLoadingWidget / SkeletonWidget` | تحميل | §18 |
| `AvatarWidget` | صور | §19 |
| `AppTabBar` | تنقل | §20 |
| `Dialogs` | حوارات | §21 |
| `Connectivity` | اتصال | §22 |
| `DividerWidget / DashedDivider / SectionTitle` | تقسيم | §23 |
| `Spacing` | مسافات | §24 |
| `BadgeWidget / TagWidget` | توافق | §25 |

### §DIRECT-IMPORTS — imports مباشرة (غير موجودة في barrel)

```dart
import 'package:app_template/presentation/extensions/screen_sizes_extensions.dart';
// context.sw, context.sh, context.bottomPadding, context.topPadding

import 'package:app_template/presentation/extensions/app_padding_extension.dart';
// 16.allPadding / 16.horizontalPadding / 16.verticalPadding
// 4.widthBox / 4.heightBox

import 'package:app_template/presentation/theme/theme_extensions.dart';
// context.colors / context.textTheme / context.colorScheme

import 'package:app_template/presentation/feedback/feedback_extension.dart';
// context.feedback.* — إلزامي في كل ملف يستخدمه
```

---

## §1 · AppButton — زر موحَّد

> استخدمه في كل الكود الجديد بدلاً من `ElevatedButton` أو `TextButton` المباشر.

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `text` | `String` | مطلوب | نص الزر |
| `onTap` | `VoidCallback?` | `null` | null = معطَّل |
| `variant` | `AppButtonVariant` | `filled` | نوع الزر |
| `size` | `AppButtonSize` | `medium` | الحجم |
| `isLoading` | `bool` | `false` | يُظهر spinner ويعطّل الضغط |
| `isEnabled` | `bool` | `true` | تعطيل بصري ووظيفي |
| `leadingIcon` | `IconData?` | `null` | أيقونة يسار النص |
| `width` | `double?` | `null` | `null` = shrink · `double.infinity` = عرض كامل |

**Variants**

| `AppButtonVariant` | الاستخدام |
|-------------------|-----------|
| `filled` | الإجراء الرئيسي (CTA) |
| `tonal` | إجراء ثانوي أخف |
| `outlined` | بديل محايد |
| `text` | رابط أو إجراء خفيف |
| `danger` | حذف / إجراء تدميري |

**Sizes** — `AppButtonSize.small` (36dp) · `medium` (44dp) · `large` (52dp)

**Usage**

```dart
// ── CTA رئيسي ──
AppButton(
  text: LocaleKeys.save.tr(),
  onTap: _submit,
  width: double.infinity,
)

// ── Loading ──
AppButton(
  text: LocaleKeys.submit.tr(),
  isLoading: state is FormLoading,
  onTap: state is FormLoading ? null : _submit,
  width: double.infinity,
)

// ── زر حذف ──
AppButton(
  text: LocaleKeys.delete.tr(),
  variant: AppButtonVariant.danger,
  leadingIcon: Icons.delete_outline_rounded,
  onTap: _confirmDelete,
)

// ── صف من زرين ──
Row(children: [
  Expanded(child: AppButton(text: LocaleKeys.cancel.tr(), variant: AppButtonVariant.outlined)),
  const SizedBox(width: 12),
  Expanded(child: AppButton(text: LocaleKeys.confirm.tr())),
])
```

> ❌ `ElevatedButton(...)` مباشرة في الـ Features
> ✅ `AppButton(variant: AppButtonVariant.filled, ...)`

---

## §2 · PrimaryButton — زر (توافق)

> موجود للتوافق مع الكود القديم. **للكود الجديد استخدم `AppButton`.**

```dart
PrimaryButton(
  text: LocaleKeys.login.tr(),
  onTap: () => _handleLogin(context),
  isLoading: state is LoginLoading,
  isEnabled: _canSubmit,
)

// نصي فقط
PrimaryButton(text: LocaleKeys.forgotPassword.tr(), isTextOnly: true, onTap: _goToReset)

// مع أيقونة SVG
PrimaryButton(text: LocaleKeys.upload.tr(), vector: Assets.images.vectors.uploadSvg, onTap: _upload)
```

**تفعيل/تعطيل real-time مع RefreshCubit:**

```dart
BlocBuilder<RefreshCubit, RefreshState>(
  bloc: _refreshCubit,
  builder: (context, _) {
    final canSubmit = _emailCtrl.text.isNotEmpty && _passwordCtrl.text.isNotEmpty;
    return PrimaryButton(
      text: LocaleKeys.login.tr(),
      isEnabled: canSubmit,
      isLoading: outerState is LoginLoading,
      onTap: canSubmit ? () => _submit(context) : null,
    );
  },
)
```

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
> import 'package:app_template/presentation/feedback/feedback_extension.dart';
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

## §5 · CustomTextField — حقل إدخال

**Parameters الأكثر استخداماً**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `controller` | `TextEditingController` | مطلوب | — |
| `labelText` | `String?` | — | تسمية فوق الحقل |
| `hint` | `String?` | — | نص تلميح |
| `validator` | `String? Function(String?)?` | — | التحقق |
| `isFieldObscure` | `bool` | `false` | كلمة مرور |
| `isSearch` | `bool` | `false` | أيقونة بحث + زر مسح |
| `ltr` | `bool` | `false` | يُجبر الإدخال LTR (أرقام / URL) |
| `keyboardType` | `TextInputType` | `text` | — |
| `maxLines` | `int` | `1` | متعدد الأسطر |
| `textInputAction` | `TextInputAction` | `next` | — |
| `onSubmitted` | `Function(String)?` | — | عند الضغط Done |

**Usage**

```dart
// ── إيميل ──
CustomTextField(
  controller: _emailCtrl,
  labelText: LocaleKeys.email.tr(),
  hint: LocaleKeys.emailHint.tr(),
  keyboardType: TextInputType.emailAddress,
  ltr: true,
  validator: _validateEmail,
)

// ── كلمة مرور ──
CustomTextField(
  controller: _passwordCtrl,
  labelText: LocaleKeys.password.tr(),
  isFieldObscure: true,
  textInputAction: TextInputAction.done,
  onSubmitted: (_) => _submit(context),
  validator: _validatePassword,
)

// ── بحث ──
CustomTextField(
  controller: _searchCtrl,
  isSearch: true,
  hint: LocaleKeys.search.tr(),
  onChanged: (v) => context.read<MyCubit>().search(v),
)

// ── ملاحظات متعددة الأسطر ──
CustomTextField(
  controller: _notesCtrl,
  labelText: LocaleKeys.notes.tr(),
  maxLines: 4,
  minLines: 2,
  textInputAction: TextInputAction.newline,
)
```

---

## §6 · AppSearchBar — شريط بحث

> مصمم للـ AppBar أو أعلى الشاشة — بصرياً مستقل عن `CustomTextField`.

```dart
AppSearchBar(
  controller: _searchCtrl,
  hintKey: LocaleKeys.searchOrders,
  onChanged: (v) => context.read<OrdersCubit>().search(v),
  onClear: () {
    _searchCtrl.clear();
    context.read<OrdersCubit>().search('');
  },
)
```

---

## §7 · AppSelectField\<T\> — حقل اختيار

> يتكامل مع `Form` ويتطابق بصرياً مع `CustomTextField`.

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `items` | `List<T>` | مطلوب | قائمة الخيارات |
| `labelResolver` | `String Function(T)` | مطلوب | محوّل T → نص |
| `value` | `T?` | `null` | القيمة الحالية |
| `onChanged` | `ValueChanged<T?>?` | — | callback عند التغيير |
| `labelText` | `String?` | — | تسمية فوق الحقل |
| `hint` | `String?` | — | تلميح عند عدم الاختيار |
| `validator` | `String? Function(T?)?` | — | التحقق |
| `mode` | `AppSelectMode` | `dropdown` | طريقة العرض |
| `showRequired` | `bool` | `false` | يُظهر `*` |
| `enabled` | `bool` | `true` | — |

**AppSelectMode**

| القيمة | متى |
|--------|-----|
| `dropdown` | قوائم قصيرة < 8 عناصر |
| `bottomSheet` | قوائم طويلة أو نصوص طويلة |

**Usage**

```dart
// ── Enum بسيط ──
AppSelectField<Gender>(
  labelText: LocaleKeys.gender.tr(),
  hint: LocaleKeys.selectGender.tr(),
  items: Gender.values,
  labelResolver: (g) => g.label.tr(),
  value: _selectedGender,
  onChanged: (g) => setState(() => _selectedGender = g),
  validator: (v) => v == null ? LocaleKeys.fieldRequired.tr() : null,
  showRequired: true,
)

// ── قائمة من الـ API (bottom sheet) ──
AppSelectField<City>(
  labelText: LocaleKeys.city.tr(),
  hint: LocaleKeys.selectCity.tr(),
  mode: AppSelectMode.bottomSheet,
  items: cities,
  labelResolver: (c) => c.name,
  value: _selectedCity,
  onChanged: (c) => setState(() => _selectedCity = c),
)
```

> ❌ `DropdownButtonFormField(...)` مباشرة
> ✅ `AppSelectField<T>(mode: AppSelectMode.dropdown, ...)`

---

## §8 · ChipRow\<T\> — صف chips

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `items` | `List<T>` | مطلوب | — |
| `labelResolver` | `String Function(T)` | مطلوب | محوّل T → نص |
| `selectedValue` | `T?` | — | المحدد (single) |
| `onSelected` | `ValueChanged<T?>?` | — | callback — null = رفع التحديد |
| `scrollable` | `bool` | `true` | `true` = أفقي قابل للتمرير · `false` = Wrap |
| `activeColor` | `Color?` | `primary` | لون المحدد |
| `spacing` | `double` | `8` | مسافة بين الـ chips |

**Usage**

```dart
// ── Single-select ──
ChipRow<Category>(
  items: categories,
  labelResolver: (c) => c.name,
  selectedValue: _selectedCategory,
  onSelected: (c) => setState(() => _selectedCategory = c),
)

// ── Multi-select ──
ChipRow<String>.multi(
  items: tags,
  labelResolver: (t) => t,
  selectedValues: _selectedTags,
  onChanged: (list) => setState(() => _selectedTags = list),
  scrollable: false,
)
```

---

## §9 · AppNavBar — شريط العنوان

> بديل `AppBar` موحَّد. يستنتج زر الرجوع تلقائياً.

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `titleKey` | `String?` | — | مفتاح ترجمة |
| `titleText` | `String?` | — | نص مترجَم مسبقاً |
| `titleWidget` | `Widget?` | — | widget مخصصة (أولوية على الاثنين) |
| `showBackButton` | `bool?` | `null` | `null` = auto من `Navigator.canPop` |
| `onBack` | `VoidCallback?` | — | تجاوز سلوك الرجوع الافتراضي |
| `actions` | `List<Widget>?` | — | أزرار اليمين |
| `bottom` | `PreferredSizeWidget?` | — | TabBar أو شريط إضافي |

**Usage**

```dart
// ── شاشة عادية ──
Scaffold(appBar: AppNavBar(titleKey: LocaleKeys.orderDetails))

// ── شاشة جذر ──
Scaffold(
  appBar: AppNavBar.root(
    titleKey: LocaleKeys.home,
    actions: [
      IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: _open),
    ],
  ),
)

// ── مع TabBar ──
Scaffold(
  appBar: AppNavBar(
    titleKey: LocaleKeys.reports,
    bottom: TabBar(controller: _tabCtrl, tabs: [...]),
  ),
)
```

---

## §10 · AppCard — بطاقة

```dart
AppCard(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  padding: const EdgeInsets.all(16),
  elevation: 2,
  onTap: () => context.router.push(OrderDetailsRoute(id: order.id)),
  child: OrderRowWidget(order: order),
)
```

---

## §11 · AppListTile — عنصر قائمة

> بديل `ListTile` يستخدم قيم الثيم الصحيحة.

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `titleKey` / `titleText` | `String?` | مطلوب أحدهما | — |
| `subtitleKey` / `subtitleText` | `String?` | — | سطر ثانٍ |
| `leadingIcon` | `IconData?` | — | أيقونة يسار |
| `leading` | `Widget?` | — | يستبدل `leadingIcon` |
| `trailing` | `Widget?` | — | widget اليمين |
| `onTap` | `VoidCallback?` | — | يُضيف سهم تلقائياً إن لم يكن `trailing` |
| `showDivider` | `bool` | `false` | فاصل أسفل |
| `dense` | `bool` | `false` | يقلل المسافة الرأسية |
| `titleColor` | `Color?` | — | لون العنوان |

**Usage**

```dart
// ── قائمة إعدادات ──
AppListTile(
  titleKey: LocaleKeys.language,
  leadingIcon: Icons.language_rounded,
  trailing: Text(currentLang, style: context.textTheme.bodySmall),
  onTap: _openLanguageSheet,
  showDivider: true,
)

// ── زر حذف ──
AppListTile(
  titleKey: LocaleKeys.logout,
  leadingIcon: Icons.logout_rounded,
  titleColor: context.colors.error,
  onTap: () => context.read<AuthCubit>().logout(),
)
```

---

## §12 · ExpandableSection — قسم قابل للطي

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `titleKey` / `titleText` | `String?` | مطلوب أحدهما | — |
| `child` | `Widget` | مطلوب | المحتوى |
| `subtitleKey` / `subtitleText` | `String?` | — | سطر ثانٍ في الرأس |
| `leading` | `Widget?` | — | أيقونة يسار الرأس |
| `initiallyExpanded` | `bool` | `false` | الحالة الأولية |
| `isExpanded` | `bool?` | `null` | `null` = uncontrolled mode |
| `onToggle` | `VoidCallback?` | — | callback عند التغيير |
| `showDivider` | `bool` | `true` | فاصل أسفل القسم |

**Usage**

```dart
// ── Uncontrolled ──
ExpandableSection(
  titleKey: LocaleKeys.orderItems,
  child: ItemsListWidget(items: order.items),
)

// ── Controlled ──
ExpandableSection(
  titleKey: LocaleKeys.faq,
  isExpanded: _isOpen,
  onToggle: () => setState(() => _isOpen = !_isOpen),
  leading: const Icon(Icons.help_outline_rounded),
  child: const FaqContent(),
)
```

---

## §13 · KeyValueRow / KeyValueSection — صفوف بيانات

**KeyValueRow Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `labelKey` | `String` | مطلوب | مفتاح ترجمة التسمية |
| `value` | `String?` | — | القيمة النصية |
| `valueWidget` | `Widget?` | — | widget مخصصة بدل `value` |
| `copyable` | `bool` | `false` | أيقونة نسخ |
| `ltr` | `bool` | `false` | يُجبر النص LTR (IBAN / رقم) |
| `showDivider` | `bool` | `true` | — |

**Usage**

```dart
// ── صف واحد ──
KeyValueRow(
  labelKey: LocaleKeys.orderNumber,
  value: '#${order.id}',
  copyable: true,
  ltr: true,
)

// ── مجموعة داخل بطاقة ──
KeyValueSection(
  rows: [
    KeyValueRow(labelKey: LocaleKeys.name, value: user.fullName),
    KeyValueRow(labelKey: LocaleKeys.phone, value: user.phone, ltr: true),
    KeyValueRow(
      labelKey: LocaleKeys.status,
      valueWidget: AppLabel(
        labelText: order.statusLabel,
        variant: order.statusVariant,
      ),
    ),
  ],
)
```

---

## §14 · StatCard — بطاقة إحصاء

> مصممة للوحات التحكم.

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `value` | `String` | مطلوب | القيمة الرئيسية |
| `labelKey` / `labelText` | `String?` | مطلوب أحدهما | الوصف |
| `icon` | `IconData?` | — | أيقونة اختيارية |
| `color` | `Color?` | `primary` | لون القيمة والأيقونة |
| `onTap` | `VoidCallback?` | — | اضغط لفتح تفصيل |
| `isLoading` | `bool` | `false` | skeleton loading |

**Usage**

```dart
GridView.count(
  crossAxisCount: 2,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  children: [
    StatCard(
      value: stats.total.toString(),
      labelKey: LocaleKeys.totalOrders,
      icon: Icons.receipt_long_outlined,
    ),
    StatCard(
      value: stats.active.toString(),
      labelKey: LocaleKeys.activeOrders,
      icon: Icons.check_circle_outline_rounded,
      color: context.colors.statusSuccessFg,
    ),
    StatCard(
      value: '${stats.revenue} ر.س',
      labelKey: LocaleKeys.revenue,
      onTap: () => context.router.push(const RevenueRoute()),
    ),
    StatCard(value: '', labelKey: LocaleKeys.pending, isLoading: true),
  ],
)
```

---

## §15 · StepProgressIndicator — مؤشر خطوات

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `currentStep` | `int` | مطلوب | 1-based |
| `totalSteps` | `int` | مطلوب | — |
| `type` | `StepIndicatorType` | `numbered` | نوع العرض |
| `activeColor` | `Color?` | `primary` | — |
| `inactiveColor` | `Color?` | `borderSubtle` | — |
| `stepLabelResolver` | `String? Function(int)?` | — | labels مخصصة |

**StepIndicatorType**

| القيمة | الوصف |
|--------|-------|
| `numbered` | دوائر مرقّمة مع خطوط رابطة |
| `dots` | نقاط أفقية (بسيط) |
| `bar` | شريط تقدم خطي مع نسبة مئوية |

**Usage**

```dart
// ── Numbered ──
StepProgressIndicator(currentStep: _step, totalSteps: 4)

// ── مع labels ──
StepProgressIndicator(
  currentStep: _step,
  totalSteps: 3,
  stepLabelResolver: (s) => switch (s) {
    1 => LocaleKeys.personalInfo.tr(),
    2 => LocaleKeys.documents.tr(),
    _ => LocaleKeys.review.tr(),
  },
)

// ── شريط تقدم ──
StepProgressIndicator(
  currentStep: _completedSteps,
  totalSteps: form.totalFields,
  type: StepIndicatorType.bar,
  activeColor: context.colors.statusSuccessFg,
)

// ── Dots ──
StepProgressIndicator(
  currentStep: _pageIndex + 1,
  totalSteps: _pages.length,
  type: StepIndicatorType.dots,
)
```

---

## §16 · AppLabel — شارة حالة دلالية

> بديل `TagWidget` — يستخدم ألوان الثيم الدلالية.
> الفرق عن `BadgeWidget`: AppLabel نص مستقل · BadgeWidget تُغطي فوق widget أخرى.

**Parameters**

| الاسم | النوع | الافتراضي | الوصف |
|-------|-------|-----------|-------|
| `labelKey` / `labelText` | `String?` | مطلوب أحدهما | — |
| `variant` | `AppLabelVariant` | `neutral` | النوع الدلالي |
| `icon` | `IconData?` | — | أيقونة اختيارية |
| `onTap` | `VoidCallback?` | — | يُضيف تأثير ضغط |
| `compact` | `bool` | `false` | padding أصغر للجداول |

**AppLabelVariant**

| القيمة | الاستخدام |
|--------|-----------|
| `success` | نشط / مكتمل / مؤكَّد |
| `warning` | معلّق / قيد المراجعة |
| `error` | مرفوض / ملغى / خطأ |
| `info` | معلومة / ملاحظة |
| `neutral` | مسودة / غير محدد |
| `primary` | مميَّز / علامة تجارية |

**Usage**

```dart
// ── في قائمة أوامر ──
AppLabel(labelText: order.statusLabel, variant: order.statusVariant)

// ── مع أيقونة ──
AppLabel(
  labelKey: LocaleKeys.verified,
  variant: AppLabelVariant.success,
  icon: Icons.verified_rounded,
)

// ── مضغوط في جدول ──
AppLabel(labelKey: LocaleKeys.closed, variant: AppLabelVariant.error, compact: true)

// ── mapping من API enum ──
extension on OrderStatus {
  AppLabelVariant get labelVariant => switch (this) {
    OrderStatus.active   => AppLabelVariant.success,
    OrderStatus.pending  => AppLabelVariant.warning,
    OrderStatus.rejected => AppLabelVariant.error,
    OrderStatus.draft    => AppLabelVariant.neutral,
  };
}
```

> ❌ `TagWidget(labelKey: ..., backgroundColor: Colors.green, ...)`
> ✅ `AppLabel(labelKey: ..., variant: AppLabelVariant.success)`

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

## §19 · AvatarWidget — صورة مستخدم

```dart
AvatarWidget(
  imageUrl: user.profileImage,
  initial: user.fullName.getFirstAndLast,
  radius: 24,
  backgroundColor: context.colors.avatarBg,
  foregroundColor: context.colors.avatarFg,
)
```

---

## §20 · AppTabBar — شريط تبويبات

```dart
DefaultTabController(
  length: tabs.length,
  child: Scaffold(
    appBar: AppNavBar(
      titleKey: LocaleKeys.reports,
      bottom: AppTabBar(
        tabs: tabs.map((t) => Tab(text: t.label.tr())).toList(),
      ),
    ),
    body: TabBarView(children: tabs.map((t) => t.content).toList()),
  ),
)
```

---

## §21 · Dialogs — حوارات

```dart
// ── تأكيد الحذف (إلزامي قبل كل حذف) ──
AppConfirmDialog.show(
  context,
  titleKey: LocaleKeys.deleteConfirmTitle,
  messageKey: LocaleKeys.deleteConfirmMessage,
  isDestructive: true,
  onConfirm: () => context.read<OrdersCubit>().delete(order.id),
);

// ── تأكيد عادي (await للنتيجة) ──
final confirmed = await AppConfirmDialog.show(
  context,
  titleKey: LocaleKeys.confirmAction,
  messageKey: LocaleKeys.areYouSure,
);
if (confirmed == true && context.mounted) _proceed();

// ── ورقة سفلية ──
context.showAppBottomSheet(
  title: LocaleKeys.selectDate.tr(),
  child: DatePickerWidget(onSelected: _onDateSelected),
  size: AppBottomSheetSize.large,
);

// ── فلترة ──
AppFilterSheet(
  filters: activeFilters,
  onApply: (filters) => context.read<OrdersCubit>().applyFilters(filters),
  onClear: () => context.read<OrdersCubit>().clearFilters(),
)
```

---

## §22 · Connectivity — حالة الاتصال

```dart
const OfflineBanner()           // شريط أحمر أعلى الشاشة
const SubtleOfflineDot()        // نقطة حمراء مضغوطة
ReconnectCountdownChip(onRetry: _retry)   // chip مع عدّ تنازلي
ConnectivityOverlay(child: Scaffold(...)) // طبقة تغطي الشاشة
```

---

## §23 · DividerWidget / DashedDivider / SectionTitle

```dart
// ── فاصل صلب ──
const DividerWidget()
DividerWidget(color: context.colors.borderSubtle, thickness: 1)

// ── فاصل منقط ──
const DashedDivider()
DashedDivider(color: context.colors.dividerSubtle, dashWidth: 6, dashSpace: 3)

// ── عنوان قسم ──
SectionTitle(titleKey: LocaleKeys.contactInfo)
SectionTitle(titleText: 'معلومات التوصيل', action: TextButton(...))
```

---

## §24 · Spacing — مسافات

> **Import مباشر مطلوب:**
> ```dart
> import 'package:app_template/presentation/extensions/app_padding_extension.dart';
> ```

```dart
4.widthBox              // SizedBox(width: 4)
16.heightBox            // SizedBox(height: 16)
16.allPadding           // EdgeInsets.all(16)
16.horizontalPadding    // EdgeInsets.symmetric(horizontal: 16)
16.verticalPadding      // EdgeInsets.symmetric(vertical: 16)
```

---

## §25 · BadgeWidget / TagWidget — توافق

> موجودان للتوافق. **للكود الجديد استخدم `AppLabel`.**

```dart
// ── BadgeWidget — عدد فوق widget (لا يُستبدَل) ──
BadgeWidget(
  count: notifications.length,
  child: IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: _open),
)

// ── TagWidget — توافق قديم ──
TagWidget(labelKey: LocaleKeys.active)

// ── الصحيح في الكود الجديد ──
AppLabel(labelKey: LocaleKeys.active, variant: AppLabelVariant.success)
```

---

*Phase 4 — ExpandableSection · AppListTile · StatCard · StepProgressIndicator · 2026-06-30*
*Phase 5 — AppButton · AppLabel · FeedbackStyle · 2026-06-30*
