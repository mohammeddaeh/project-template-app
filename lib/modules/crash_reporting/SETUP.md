# Crash Reporting — Setup Checklist

> Firebase Crashlytics — يرصد الأعطال تلقائياً ويربطها بـ LogService.

---

## ① المتطلبات المسبقة

- [ ] Firebase project مُعدّ (راجع `modules/push_notifications/SETUP.md` → الخطوة ①)
- [ ] `firebase_core` مضاف (يُضاف تلقائياً مع `firebase_crashlytics`)
- [ ] `flutterfire configure` نُفِّذ وملف `firebase_options.dart` موجود

---

## ② Android — إضافة Crashlytics plugin

في `android/app/build.gradle` أضف في أسفله:
```groovy
apply plugin: 'com.google.firebase.crashlytics'
```

في `android/build.gradle` (project level) أضف في `dependencies`:
```groovy
classpath 'com.google.firebase:firebase-crashlytics-gradle:3.0.2'
```

---

## ③ iOS — لا إعداد إضافي مطلوب

Crashlytics يعمل تلقائياً بعد إضافة `GoogleService-Info.plist`.

---

## ④ الكود في `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ① Firebase أولاً
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ② Crash Reporting — قبل runApp مباشرة
  await CrashReportingModule.initialize(
    enabled: kReleaseMode, // فقط في release — لا uploads في debug
  );

  // ③ بعد login: اربط هوية المستخدم
  // CrashReportingModule.setUserId(user.id);

  runApp(const App());
}
```

---

## ⑤ بعد Login — تحديد هوية المستخدم

```dart
// في AuthCubit بعد نجاح الدخول:
await CrashReportingModule.setUserId(user.id);
await CrashReportingModule.setUserAttribute('role', user.role);
await CrashReportingModule.setUserAttribute('plan', user.subscriptionPlan);
```

## ⑥ عند Logout — مسح الهوية

```dart
await CrashReportingModule.clearUser();
```

---

## ⑦ الاستخدام اليومي — لا تغيير مطلوب

بعد `initialize()` كل شيء تلقائي:

```dart
// هذا السطر كافٍ — يُرسَل لـ Crashlytics تلقائياً:
LogService.error('Payment failed', error: e, stackTrace: st, tag: 'PAY');

// لا حاجة لاستدعاء Crashlytics مباشرة في أي Feature أو Cubit
```

---

## ملاحظات مهمة

| الموضوع | التفصيل |
|---------|---------|
| `enabled: kReleaseMode` | يمنع رفع الأعطال أثناء التطوير — تظهر فقط في console |
| Flutter errors | مُوجَّهة تلقائياً لـ Crashlytics عبر `FlutterError.onError` |
| Async errors | مُوجَّهة عبر `PlatformDispatcher.instance.onError` |
| LogService.error | يُرسَل تلقائياً بعد `initialize()` — لا تغيير في أي Feature |
| اختبار Crashlytics | استخدم `FirebaseCrashlytics.instance.crash()` لاختبار يدوي |
