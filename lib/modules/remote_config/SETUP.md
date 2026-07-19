# Remote Config — Setup Checklist

> تغيير سلوك التطبيق بدون إصدار جديد — feature flags، نصوص، حد أدنى للإصدار.

---

## ① المتطلبات المسبقة

- [ ] Firebase project مُعدّ + `flutterfire configure` نُفِّذ
- [ ] فعّل **Remote Config** في Firebase console

---

## ② الكود في `main.dart`

```dart
await RemoteConfigModule.initialize(
  getIt,
  // القيم الافتراضية المحلية — تُستخدم عند عدم الاتصال أو قبل أول fetch
  defaults: {
    'new_payment_flow':  false,
    'min_app_version':   '1.0.0',
    'maintenance_mode':  false,
    'banner_text':       '',
    'max_upload_size_mb': 10,
  },
  // في debug: Duration.zero للحصول على قيم فورية
  minimumFetchInterval: kReleaseMode
      ? const Duration(hours: 12)
      : Duration.zero,
);
```

---

## ③ إضافة القيم في Firebase Console

1. افتح **Remote Config** في Firebase console
2. أضف المفاتيح بنفس الأسماء المستخدمة في `defaults`
3. انشر (`Publish changes`)

---

## ④ الاستخدام في Features

```dart
final config = getIt<RemoteConfigService>();

// Feature flags
if (config.getBool('new_payment_flow')) {
  // استخدم الـ flow الجديد
}

// نصوص ديناميكية
final bannerText = config.getString('banner_text');

// حد أدنى للإصدار (مع in_app_updates)
final minVersion = config.getString('min_app_version');

// مراقبة التحديثات الفورية
config.onUpdated.listen((_) {
  // القيم تغيّرت — أعد رسم الشاشة إذا لزم
});
```

---

## ملاحظات

| الموضوع | التفصيل |
|---------|---------|
| `defaults` | ضع قيمًا افتراضية لكل مفتاح — تضمن عمل التطبيق offline |
| `minimumFetchInterval` | في debug استخدم `Duration.zero` — في production `hours: 12` |
| `onUpdated` | يعمل فقط مع خطط Firebase Blaze (Spark لا يدعم real-time) |
| تبديل الـ adapter | غيّر `FirebaseRemoteConfigAdapter` في `RemoteConfigModule` — لا تغيير في Features |
