# Notification Center Module — دليل التفعيل

طبقةٌ فوق `modules/push_notifications/` الموجود: تجميع كل إشعار وصل والتطبيقُ
بالمقدّمة داخل شاشة واحدة، بحالة مقروء/غير مقروء. راجع
[`readme/41_ROADMAP.md`](../../../readme/41_ROADMAP.md) بند #11 للسياق الكامل.

## الخطوة ١ — تفعيل `push_notifications` أولاً

```dart
// lib/core/platform/features/app_features.dart
static const pushNotifications = true;
```

هذا الموديول **يستهلك** بثّ `PushNotificationsService`، ولا يتصل بـFCM بذاته.
بلا هذا العلَم، القائمة تبقى فارغةً للأبد — ولا شيء ينهار، لكن لا فائدة من
التفعيل التالي وحده.

---

## الخطوة ٢ — تفعيل الموديول

```dart
// lib/core/platform/features/app_features.dart
static const notificationCenter = true;
```

لا شيء آخر إلزامي — `ModulesBootstrap.initializeAll()` يسجّل المخزن ويبدأ
الاستماع تلقائياً.

---

## الخطوة ٣ — تركيب الشاشة

**متعمَّدٌ بلا `@RoutePage()`** — نفس سبب `ActiveDevicesScreen` بـ`multi_device/`:
مسارٌ يدخل موجِّه كل مشروعٍ مبنيّ على هذا القالب، بما فيها التي تشحن الموديول
مطفأً. ادفعها من أيقونة جرس بالقشرة أو من الإعدادات:

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
);
```

---

## الخطوة ٤ — تأكيد التفعيل

عند الإقلاع:
```
[NOTIFICATION_CENTER] NotificationCenterPlugin initializing...
[NOTIFICATION_CENTER] NotificationCenterPlugin ready.
```

⚠️ **وإن ظهر هذا بدلاً منه**، فـ`pushNotifications` مطفأ — الموديول يبقى
مسجَّلاً (القائمة المخزَّنة سلفاً تبقى مقروءة) لكن لن يصله شيء جديد أبداً:
```
[NOTIFICATION_CENTER] NotificationCenterPlugin enabled without
PushNotificationsService — nothing will ever be added to the list.
```

---

## ماذا يحدث تلقائياً بعد التفعيل؟

| الحدث | ما يحدث |
|---|---|
| إشعارٌ يصل والتطبيقُ بالمقدّمة (`foregroundStream`) | يُضاف للقائمة فوراً، غير مقروء |
| إشعارٌ يصل بالخلفية أو يفتح التطبيق بالنقر عليه (`tapStream`) | **لا يُسجَّل هنا** — يخصّ توجيه الرابط العميق، لا هذه القائمة (تجنّباً للتكرار) |
| نقرةٌ على عنصرٍ غير مقروء بالشاشة | يُعلَّم مقروءاً فوراً |
| «تعليم الكل كمقروء» | كل العناصر تُعلَّم مقروءة |
| «حذف الكل» (بعد تأكيد) | القائمة تُفرَّغ ويُمحى المخزَّن |
| تجاوز `NotificationCenterConfig.maxStored` (افتراضياً ٢٠٠) | أقدم عنصرٍ يُحذف تلقائياً |
| خروجٌ أو تبديل حساب (`AccountDataCleaner`) | القائمة المحفوظة تُمحى تلقائياً (`AccountScopedStore`) — لا يرثها حسابٌ تالٍ على نفس الجهاز |

---

## التخصيص

```dart
// lib/modules/notification_center/notification_center_config.dart
static const int maxStored = 200;  // أقصى عدد إشعارات محفوظة محلياً
```

---

## إيقاف الموديول

```dart
// lib/core/platform/features/app_features.dart
static const notificationCenter = false;  // ← أعِد إلى false
```

لا حاجة لإزالة الكود — صفر أوفرهيد عند الإيقاف، ولا شيء يُسجَّل بالـDI.
