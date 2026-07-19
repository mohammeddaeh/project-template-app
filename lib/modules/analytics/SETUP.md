# Analytics — Setup Checklist

> Firebase Analytics — تتبع أحداث المستخدم بدون كود مكرر في كل Feature.

---

## ① المتطلبات المسبقة

- [ ] Firebase project مُعدّ + `flutterfire configure` نُفِّذ
- [ ] `google-services.json` و `GoogleService-Info.plist` موجودان

> Firebase Analytics مُفعَّل تلقائياً بمجرد إضافة الـ package — لا إعداد إضافي.

---

## ② الكود في `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await configureInjection(Env.dev);

  await AnalyticsModule.initialize(
    getIt,
    enabled: kReleaseMode, // بيانات فقط في release
  );

  runApp(const App());
}
```

---

## ③ الاستخدام في Features

```dart
// أي Cubit أو UseCase:
final _analytics = getIt<AnalyticsService>();

// تتبع حدث
await _analytics.track('login_success', {'method': 'email'});
await _analytics.track('purchase_completed', {'amount': 99, 'currency': 'SAR'});

// تتبع الشاشات
await _analytics.logScreen('HomeScreen');

// بعد login
await _analytics.setUserId(user.id);
await _analytics.setUserProperty('plan', 'premium');
await _analytics.setUserProperty('locale', 'ar');

// عند logout
await _analytics.setUserId(null);
```

---

## ④ GDPR / موافقة المستخدم

```dart
// عند رفض الموافقة:
await getIt<AnalyticsService>().setEnabled(false);

// عند القبول:
await getIt<AnalyticsService>().setEnabled(true);
```

---

## ملاحظات

| الموضوع | التفصيل |
|---------|---------|
| اسم الحدث | ≤ 40 حرف، يبدأ بحرف، أحرف/أرقام/underscore فقط |
| عدد المعاملات | ≤ 25 parameter per event |
| تبديل الـ adapter | غيّر `FirebaseAnalyticsAdapter` بـ `MixpanelAdapter` في `AnalyticsModule` — لا تغيير في Features |
| بيانات debug | فعّل **DebugView** في Firebase console + `adb shell setprop debug.firebase.analytics.app <package>` |
