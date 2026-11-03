# Push Notifications — Setup Checklist

> اتبع هذه الخطوات بالترتيب عند استخدام هذا الموديول في أي مشروع جديد.

---

## ① Firebase Project

- [ ] أنشئ مشروع Firebase على [console.firebase.google.com](https://console.firebase.google.com)
- [ ] فعّل **Cloud Messaging** في الـ project settings
- [ ] نفّذ الأمر في جذر المشروع:
  ```bash
  flutterfire configure
  ```
  → يولّد `lib/firebase_options.dart` تلقائياً

---

## ② ملفات الإعداد الأصلية

### Android
- [ ] ضع `google-services.json` في `android/app/`
- [ ] في `android/app/build.gradle` أضف في أسفله:
  ```groovy
  apply plugin: 'com.google.gms.google-services'
  ```
- [ ] في `android/build.gradle` (project level) أضف:
  ```groovy
  classpath 'com.google.gms:google-services:4.4.2'
  ```

### iOS / macOS
- [ ] ضع `GoogleService-Info.plist` في `ios/Runner/` (drag & drop في Xcode)
- [ ] في Xcode → **Signing & Capabilities** → أضف:
  - `Push Notifications`
  - `Background Modes` → فعّل `Remote notifications`
- [ ] في `ios/Runner/AppDelegate.swift`:
  ```swift
  // تأكد أن GeneratedPluginRegistrant.register(with: self) موجودة
  ```

---

## ③ التفعيل — علَمٌ واحد، ومعالجُ الخلفية بـ`main.dart`

```dart
// lib/core/platform/features/app_features.dart
static const pushNotifications = true;
```

`ModulesBootstrap` يهيّئ Firebase مرّةً ثم ينادي الموديول حين يُشعَل علَمُه.
**لا تناده من `main()`**: الموديول يُهيَّأ مرّةً واحدة، فنداءٌ ثانٍ بوسائط أخرى
يُتجاهل بصمت، أيُّهما سبق. ولتغيير الوسائط عدّل سطره هناك:

```dart
// lib/modules/modules_bootstrap.dart
if (AppFeatures.pushNotifications) {
  await PushNotificationsPlugin.initialize(
    di,
    config: PushNotificationsConfig(
      // أرسل الـ token للـ backend عند كل تحديث
      onTokenRefresh: (token) async {
        // مثال: await di<AuthRepository>().updatePushToken(token);
      },
    ),
  );
}
```

**ومعالجُ الخلفية وحده بـ`main.dart`** — دالّةٌ top-level لا يملكها موديول:

```dart
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // معالجة بسيطة فقط — لا UI هنا
}

// داخل _bootstrap() قبل runApp:
FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
```

---

## ④ الاستخدام في Feature

```dart
class NotificationCubit extends SafeCubit<NotificationState> {
  NotificationCubit(PushNotificationsService push) : super(...) {
    // رسائل وصلت والتطبيق مفتوح
    push.foregroundStream.listen(_showInAppBanner);

    // المستخدم نقر على إشعار (deep link)
    push.tapStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(PushNotificationEvent event) {
    final type = event.data['type'];
    switch (type) {
      case 'chat':    router.push(ChatRoute(id: event.data['id']));
      case 'order':   router.push(OrderRoute(id: event.data['id']));
      default:        router.push(const HomeRoute());
    }
  }
}
```

---

## ⑤ الخروج والدخول — تلقائيّ

الرمزُ للحساب الداخل على الجهاز، فالموديول يسمع `SessionRepository.tokenStream`:
**الخروج يحذف الرمز** (وإلا وصلت إشعاراتُ السابق لمن يدخل بعده)، **وأوّلُ دخولٍ بعده
يطلب رمزاً جديداً** ويبلّغ به `onTokenRefresh`. لا سطرَ بشاشة الخروج.

ولإيقاف الموديول كلّه: `await PushNotificationsPlugin.shutdown(getIt);`.

---

## ⑥ Topics (اختياري)

```dart
// اشتراك في موضوع (مثلاً: إشعارات عامة)
await getIt<PushNotificationsService>().subscribeToTopic('announcements');

// إلغاء الاشتراك
await getIt<PushNotificationsService>().unsubscribeFromTopic('announcements');
```

---

## ملاحظات مهمة

| الموضوع | التفصيل |
|---------|---------|
| الـ Token | يُخزَّن تلقائياً في `SecureStorageService` بمفتاح `'fcm_token'` (قابل للتغيير في `PushNotificationsConfig`) |
| صلاحيات iOS | يُطلَب إذن المستخدم تلقائياً عند `initialize()` — يمكن تعطيله بـ `requestPermissionOnInit: false` |
| Background handler | يجب أن يكون `top-level function` — لا `class method` ولا `lambda` |
| Firebase init | يجب استدعاء `Firebase.initializeApp()` قبل `PushNotificationsPlugin.initialize()` |
| Android 13+ | يحتاج `POST_NOTIFICATIONS` permission — FCM يطلبها تلقائياً |
