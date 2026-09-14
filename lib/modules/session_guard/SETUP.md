# Session Guard Module — دليل التفعيل

قفلٌ محليّ للجلسة (رقمٌ محلّي و/أو بصمة إصبع) بعد خمولٍ أو عودةٍ من الخلفية —
**دون تسجيل خروجٍ كامل**. راجع [`readme/41_ROADMAP.md`](../../../readme/41_ROADMAP.md)
بند #07 للسياق الكامل ولماذا صُمِّم هكذا.

## الخطوة ١ — تفعيل الموديول

```dart
// lib/core/platform/features/app_features.dart
static const sessionGuard = true;  // ← غيّر من false إلى true
```

لا شيء آخر إلزامي — `ModulesBootstrap.initializeAll()` و`SessionGuardGate`
(مركَّبٌ بالفعل بـ`main_shell_page.dart`) يتوليان الباقي تلقائياً.

---

## الخطوة ٢ — البصمة (اختياري)

لتفعيل خيار البصمة **بجانب** الرقم المحلي (الاثنان معاً، لا أحدهما بدل الآخر):

```dart
// lib/core/platform/features/app_features.dart
static const biometrics = true;
```

بلا هذا العلَم، شاشة القفل تعرض لوحة الأرقام وحدها — لا خطأ ولا نقص، فقط خيارٌ
واحد بدل اثنين.

---

## الخطوة ٣ — تأكيد التفعيل

عند الإقلاع:
```
[SESSION_GUARD] SessionGuardPlugin initializing...
[SESSION_GUARD] SessionGuardPlugin ready.
```

وعند أوّل وصولٍ للقشرة الرئيسية بلا رقمٍ مسجَّل بعد: شاشة "أنشئ رقم قفل
للتطبيق" تظهر تلقائياً بدل جسد التطبيق.

---

## ماذا يحدث تلقائياً بعد التفعيل؟

| الحدث | ما يحدث |
|---|---|
| أوّل وصولٍ للقشرة، ولا رقم مسجَّل | شاشة إعداد الرقم (خطوتان: اكتب ثم أكِّد) |
| دخولٌ بكلمة مرور كُتبت للتوّ | **لا قفل فوري** — إثباتُ حضورٍ حيّ يُعفي أول لحظة (`SessionGuardFreshAuth`) |
| إقلاعٌ باردٌ بتوكن محفوظ (بلا دخول هذه الجلسة) | **قفلٌ فوري** — استعادة توكن لا تثبت من يحمل الجهاز الآن |
| خلفيةٌ أطول من `SessionGuardConfig.lockAfter` (افتراضياً دقيقتان) ثم عودة | قفل |
| رقمٌ صحيح أو بصمة ناجحة | فتح فوري |
| `SessionGuardConfig.maxWrongAttempts` محاولاتٍ خاطئة متتالية (افتراضياً ٥) | **تسجيل خروجٍ كاملٍ قسريّ** — لا قفلٌ إضافي. مساحة تخمين رقمٍ قصير لا تحتمل محاولاتٍ غير محدودة |
| خروجٌ أو تبديل حساب (`AccountDataCleaner`) | الرقم المحفوظ يُمحى تلقائياً (`AccountScopedStore`) — لا يرثه حسابٌ تالٍ على نفس الجهاز |

---

## التخصيص

```dart
// lib/modules/session_guard/session_guard_config.dart
static const Duration lockAfter = Duration(minutes: 2);  // مدّة الخمول قبل القفل
static const int maxWrongAttempts = 5;                   // قبل تسجيل الخروج القسري
```

قِسها لمشروعك — تطبيقٌ بنكيّ أو حكوميّ حسّاس يقصّرها إلى ثوانٍ.

---

## إيقاف الموديول

```dart
// lib/core/platform/features/app_features.dart
static const sessionGuard = false;  // ← أعِد إلى false
```

لا حاجة لإزالة الكود — صفر أوفرهيد عند الإيقاف، و`SessionGuardGate` يعرض
جسد التطبيق مباشرة بلا حتى بناء cubit.
