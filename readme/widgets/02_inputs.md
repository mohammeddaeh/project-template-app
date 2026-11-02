# الإدخال والنماذج

> جزءٌ من دليل الودجات — الفهرس الكامل والاستيراد بـ[`../21_WIDGETS_USAGE.md`](../21_WIDGETS_USAGE.md).

> **Import الوحيد:** `package:app_template/ui/widgets/widgets.dart` — والاستثناءات بـ§DIRECT-IMPORTS بالفهرس.


---

## §5 · CustomTextField — حقل إدخال

> **ويهتزّ حين يظهر خطأ تحقّقٍ جديد** (`ShakeOnError` — §38) — فتعرف العين أيّ
> حقلٍ رُفض بلا قراءة الرسائل. ولا يهتزّ لخطأٍ ثابت، ولا مع «تقليل الحركة».

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

> **`onChanged` · `onFieldSubmitted`** يقبلان `(String v) {…}` أو `() {…}` — والحقل ينادي
> كلّاً بما يأخذه (`test/library_guards_test.dart`).

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

---

## §42 · DictationButton · SpeakButton — الصوت (`kit_voice`)

> **ودجتا kit**: تعملان حين تكون `kit_voice` مركّبة (`dart run scripts/kit.dart add voice`)،
> **ولا ترسمان شيئاً بدونها** — فالشاشة تطلبهما بلا شرط، وتبقى سليمةً بمشروعٍ لم يركّبها.
> البنية بـ[`24_DEVICE_KITS.md`](../24_DEVICE_KITS.md).

```dart
// ── إملاءٌ بحقل — الطريق المعتاد ──
CustomTextField(controller: _notes, labelText: LocaleKeys.notes.tr(), dictation: true)

// ── الزرّ وحده — لحقلٍ ليس CustomTextField ──
DictationButton(controller: _query, onChanged: (v) => cubit.search(v))

// ── قراءةٌ بصوت — بلغة النصّ لا لغة التطبيق إن اختلفتا ──
SpeakButton(text: article.body)
SpeakButton(text: quote, languageCode: 'en')
```

| القرار | لماذا |
|---|---|
| **الكلام يُضاف لما بالحقل** | من يُملي جملةً ثانية لا يريد أن تمحو الأولى |
| **بلغة التطبيق** | `context.locale` — والمحرّك يختار لهجة الجهاز إن كانت من نفس اللغة |
| **الإذن بـ`PermissionsService`** | `ensureKitReady` يطلب الميكروفون ومُعرِّف الكلام معاً مرّةً واحدة؛ الرفضُ الدائم يعرض زرّ «الإعدادات» |
| **لا إملاء بحقل كلمة مرور ولا بحقل بحث** | لا أحد يقول كلمة مروره بصوتٍ مسموع؛ والبحث له `DictationButton` وحده إن أراده |
| **`onChanged` للإملاء صراحةً** | التغيير البرمجيّ لا يمرّ بـ`onChanged` الحقل — فـ`CustomTextField` يمرّره بنفسه |

يُثبَّت بـ`test/voice_kit_test.dart` — بالـkit وبدونها، عبر `FakeSpeechInput`/`FakeSpeechOutput`
من `package:kit_contracts/testing.dart`، فلا يلمس اختبارٌ حزمة منصّة.

---

## §44 · DeviceScan — الكاميرا مدخلاً (`kit_scan` · `kit_ocr`)

> **نداءاتٌ لا ودجات**: كلٌّ يطلب إذن الكاميرا بنفسه ويقول لماذا توقّف. والزرُّ يُرسم حين
> تكون الـkit مركّبة — `DeviceScan.canScanCodes` · `canReadText`.
> البنية بـ[`24_DEVICE_KITS.md`](../24_DEVICE_KITS.md).

```dart
// ── رمز QR أو باركود — ورقةٌ بالكاميرا تُغلق بأوّل رمز ──
final code = await DeviceScan.code(context);          // ScannedCode? (value · format)

// ── نصٌّ مطبوع من صورة (kit_ocr) — لاتينيّ وحده ──
final image = await getIt<MediaService>().pickFromGallery();
final text = await DeviceScan.text(context, image!.path);
```

| القرار | لماذا |
|---|---|
| **أوّلُ رمزٍ يُغلق الورقة** | المسح فعلٌ واحد؛ ورقةٌ تبقى بعد القراءة تُعيد الرمزَ نفسه والمستدعي يريد واحداً |
| **المربّع يصغر ليناسب** | شاشةٌ قصيرة أو أفقية لا تتّسع لمربّعٍ بعرض الورقة — والورقة تعطي المحتوى غير القابل للتمرير سقفَها |
| **النص بالحروف اللاتينية وحدها** | النموذج على الجهاز لا يقرأ العربية — يصلح للأرقام التسلسلية واللوحات والمستندات الإنجليزية |

يُثبَّت بـ`test/scan_kit_test.dart`.

---

## §46 · SignaturePad · HandwritingInput — التوقيع والكتابة اليدوية

> **`SignaturePad` بالمكتبة نفسها** (رسمٌ بـFlutter، بلا kit). **`HandwritingInput` ودجةُ kit**
> (`kit_ink`) — لا ترسم شيئاً بدونها. والرسمُ واحدٌ للاثنين: `InkController`.

```dart
// ── توقيع — يُحفظ صورة ──
final ink = InkController();
SignaturePad(controller: ink, hint: LocaleKeys.signHere.tr())
final png = await ink.toPng(color: context.colors.textPrimary);   // null إن كان فارغاً

// ── كتابةٌ بخطّ اليد تصير نصّاً ──
HandwritingInput(onText: (t) => _notes.text += ' $t')
```

| القرار | لماذا |
|---|---|
| **النقاطُ بأوقاتها** | المُعرِّف يقرأ ترتيبَ الحركة وسرعتَها، فالرسمُ نفسُه يصلح صورةً ونصّاً |
| **النموذجُ بضغطةٍ معلَنة** | عدّةُ ميغابايتات من Google لكل لغة — الزرُّ يقول «حمّل نموذج الكتابة (ar) — مرّة واحدة» قبل أن يقع |
| **بلغة التطبيق** | العربية مدعومة — و`languageCode` لنصٍّ بلغةٍ أخرى |
| **اللوحُ يُمسح بعد كل كلمة** | تُكتب الكلمةُ التالية بلا مسحٍ يدويّ |
| **الصورة شفّافة الخلفية** | التوقيعُ يوضع فوق مستندٍ أو بطاقةٍ بلا مربّعٍ أبيض |

⚠️ **تنزيلُ النموذج يحتاج اتصالاً يصل إلى Google** — شبكةٌ تحجبه تردّ «تعذّر تحميل النموذج». وبناءُ
`kit_ink` أوّلَ مرّة يحتاج الوصول لمستودع Google (كـ`kit_audio`).

يُثبَّت بـ`test/ink_kit_test.dart`.
