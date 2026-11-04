# الأزرار والتفاعل

> جزءٌ من دليل الودجات — الفهرس الكامل والاستيراد بـ[`../21_WIDGETS_USAGE.md`](../21_WIDGETS_USAGE.md).

> **Import الوحيد:** `package:app_template/ui/widgets/widgets.dart` — والاستثناءات بـ§DIRECT-IMPORTS بالفهرس.


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
| `onBrand` | فوق سطح العلامة (`bgBrand`) — شاشة الترحيب. خلفيةٌ `onBrandAccent` ونصٌّ بلون السطح |

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

## §30 · PressableScale — رد فعل لمسي عام

> **يغلّف، لا يستبدل.** يراقب الضغط بـ`Listener` لا `GestureDetector`، فلا
> يدخل ساحة الإيماءة ولا يتنازع مع `InkWell`/`GestureDetector` الخاص بالابن —
> الشكل والـripple والـ`onTap` تبقى بيد الابن، هو يُضيف تصغيراً بصرياً فقط
> أثناء الضغط (`AppMotion.pressedScale` = 0.97) — يصغر بـ`springSnappy` ويرجع بـ`springGentle`
> بارتدادٍ خفيف، وإفلاتٌ سريع ينعطف من موضعه ولا يقفز. يحترم "تقليل الحركة" بالنظام
> (`MediaQuery.disableAnimations`) — الابن بلا تصغيرٍ حينها.

**Usage**

```dart
PressableScale(
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => ...,
      child: ...,
    ),
  ),
)
```

مستهلكٌ حيّ: `modules/session_guard/presentation/widgets/pin_pad.dart` — رد فعل
لمسي على أزرار لوحة الأرقام.

---

## §38 · `ShakeOnError` — هزّةٌ حين يظهر خطأٌ جديد

```dart
ShakeOnError(error: state.errorText, child: MyPicker(...))
```

`CustomTextField` يستعملها وحده؛ وتُلفّ بها أي ودجةٍ لها خطأ تحقّق (منتقٍ · شرائح).
تهتزّ حين يتبدّل `error` إلى نصٍّ جديد غير فارغ — لا بكل إعادة بناء، ولا مع «تقليل الحركة».
