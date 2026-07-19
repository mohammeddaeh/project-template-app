# In-App Updates — Setup Checklist

> يُجبر المستخدم على تحديث التطبيق قبل المتابعة (Android: Google Play API / iOS: App Store redirect).

---

## ① Android — لا إعداد إضافي

يعمل مع أي تطبيق منشور على Google Play — لا متطلبات إضافية.

> ⚠️ يعمل فقط على أجهزة حقيقية مع تطبيق منشور على Play Store.
> في بيئة التطوير سيُرجع `updateAvailability = noUpdateAvailable` دائماً.

---

## ② iOS — App Store ID

- [ ] احتفظ بـ **App Store ID** للتطبيق (يظهر في App Store Connect → App Information)

---

## ③ الاستخدام

```dart
// في SplashCubit أو بعد login مباشرة:
await InAppUpdatesModule.checkAndPrompt(
  context,
  mode: UpdateMode.flexible,   // flexible أو immediate
  iosAppId: '1234567890',      // App Store ID للـ iOS
);
```

### متى تستخدم كل mode؟

| Mode | متى |
|------|-----|
| `flexible` | تحديثات عادية — يُنزَّل في الخلفية |
| `immediate` | تحديثات أمنية أو إصلاحات حرجة — يمنع الاستخدام حتى التحديث |

---

## ④ مع Remote Config (الأفضل)

```dart
// تحقق من الحد الأدنى للإصدار من Remote Config:
final minVersion = getIt<RemoteConfigService>().getString('min_app_version');
final currentVersion = (await PackageInfo.fromPlatform()).version;

if (_isOutdated(currentVersion, minVersion)) {
  await InAppUpdatesModule.checkAndPrompt(
    context,
    mode: UpdateMode.immediate, // إجباري إذا أقل من الحد الأدنى
    iosAppId: '1234567890',
  );
}
```

---

## ملاحظات

| الموضوع | التفصيل |
|---------|---------|
| Android testing | استخدم Internal App Sharing للاختبار قبل النشر |
| iOS | لا توجد API رسمية — يتم redirect للـ App Store |
| عدم الإزعاج | لا تستدعي `checkAndPrompt` في كل مرة — مرة عند فتح التطبيق فقط |
