# Multi-Device Session Module — دليل التفعيل

## الخطوة ١ — تفعيل الموديول

```dart
// lib/core/platform/features/app_features.dart
static const multiDevice = true;  // ← غيّر من false إلى true
```

---

## الخطوة ٢ — توليد Retrofit

الموديول يستخدم Retrofit لـ `DeviceSessionApiService`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## الخطوة ٣ — تأكيد التفعيل

التطبيق سيطبع في console عند البداية:
```
[MULTI_DEVICE] MultiDevicePlugin initializing...
[MULTI_DEVICE] DeviceIdService ready | id=550e8400...
[MULTI_DEVICE] MultiDevicePlugin ready.
```

---

## الخطوة ٤ — إضافة شاشة الأجهزة (اختياري)

### في router.dart

```dart
// lib/routes/router.dart
AutoRoute(page: ActiveDevicesRoute.page, path: '/settings/devices'),
```

### في صفحة الإعدادات

```dart
import 'package:app_template/modules/multi_device/presentation/pages/active_devices_screen.dart';

// Navigate:
context.pushRoute(const ActiveDevicesRoute());
```

---

## الخطوة ٥ — ربط FCM (اختياري — للإشعارات)

في handler الـ FCM الخاص بك:

```dart
FirebaseMessaging.onMessage.listen((message) {
  getIt<DeviceNotificationHandler>().handle(message.data);
});

// Background messages:
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  getIt<DeviceNotificationHandler>().handle(message.data);
}
```

---

## الخطوة ٦ — رسالة "تم تسجيل خروجك" (اختياري)

عند الوصول لشاشة الدخول بعد `sessionRevoked`، يمكن عرض رسالة:

```dart
// في app.dart، داخل switch:
case AuthEvent.sessionRevoked:
  // يمكنك تخزين flag أو تمرير param:
  SessionRevokedFlag.wasRevoked = true;
  router.pushAndPopUntil(const LoginRoute(), predicate: (_) => false);
```

---

## ماذا يحدث تلقائياً بعد التفعيل؟

| الحدث | ما يحدث |
|---|---|
| تسجيل دخول | يُرسل `device_id` + `device_name` + `platform` تلقائياً |
| أي طلب HTTP | يُضاف `X-Device-ID` header تلقائياً |
| استقبال `SESSION_REVOKED` | مسح البيانات المحلية + انتقال للدخول |
| استقبال FCM `session_revoked` | نفس السلوك أعلاه |
| `is_primary` و `device_session_id` | تُحفظ تلقائياً بعد كل login ناجح |

---

## إيقاف الموديول

```dart
// lib/core/platform/features/app_features.dart
static const multiDevice = false;  // ← أعِد إلى false
```

لا حاجة لإزالة الكود — صفر أوفرهيد عند الإيقاف.
