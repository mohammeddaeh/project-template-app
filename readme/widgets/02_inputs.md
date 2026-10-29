# الإدخال والنماذج

> جزءٌ من دليل الودجات — الفهرس الكامل والاستيراد بـ[`../21_WIDGETS_USAGE.md`](../21_WIDGETS_USAGE.md).

> **Import الوحيد:** `package:app_template/ui/widgets/widgets.dart` — والاستثناءات بـ§DIRECT-IMPORTS بالفهرس.


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

## §33 · `validateAndReveal` — التمرير لأول حقل ناقص

> امتداد على `GlobalKey<FormState>` بـ`ui/widgets/inputs/form_reveal.dart`، مُصدَّر بـ`widgets.dart`.

```dart
// بدل: if (!(_formKey.currentState?.validate() ?? false)) return;
if (!_formKey.validateAndReveal()) return;
```

`Form.validate()` تُعلّم الحقول الناقصة بالأحمر وتترك الشاشة حيث هي. بنموذج
أطول من شاشة، القارئ يرى التوست ولا يرى الحقل — فيقرأ الرفض عطلاً («يقول
مطلوب ولا أرى أين»). `validateAndReveal` تتحقق، ثم تمشي شجرة النموذج نفسها
لتجد **أول** `FormFieldState` فاشل بترتيب الرسم، فتُمرّر إليه وتضع المؤشر فيه
إن كان حقل كتابة.

| القرار | لماذا |
|---|---|
| **بلا مفتاح لكل حقل** | كل حقول المكتبة تبني `FormField` داخلها، فالمشي عليها يكفي. قائمة مفاتيح يدوية تُنسى بأول حقل يُضاف، والنسيان صامت |
| **الأول لا الأخير** | القارئ يُصلح من الأعلى للأسفل؛ القفز للأخير يُخفي ما قبله |
| **المؤشر لحقل الكتابة وحده** | المنتقي لا `focusNode` له، والتمرير يكفيه |
| **نقصٌ خارج الحقول يُظهره المستدعي** | قيمة لا يحرسها `FormField` لا حالة خطأ لها، فيُعلّمها المستدعي ثم يستدعي `revealFirstInvalid()` |
| **⚠️ النموذج داخل `ListView`** | `ListView` يبني المرئي وحده، والحقل غير المبنيّ **لا يُتحقَّق منه أصلاً** — نموذج بحقول كثيرة يُحفظ بحقل مطلوب فارغ. استعمل `SingleChildScrollView + Column` بكل نموذج |

يُثبَّت بـ`test/form_reveal_test.dart`: الفشل هنا **صامت** — التوست يظهر والحقل
يحمرّ، والشاشة وحدها لا تتحرك.

المستهلكون: شاشات `features/auth/` الست (الدخول · التسجيل · التحقق · نسيان/إعادة/تغيير كلمة المرور).
