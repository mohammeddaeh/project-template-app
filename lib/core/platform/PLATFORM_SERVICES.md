# Platform Services — دليل الخدمات الاختيارية

> **الغرض:** شرح جميع خدمات `lib/core/platform/` الاختيارية — كيف تُفعّلها، ماذا تحتاج من حزم، وكيف تستخدمها في Features.
>
> **Last updated:** Jun 2026

---

## كيف تعمل الخدمات الاختيارية؟

```
AppFeatures (flag = true)
        ↓
PlatformServicesRegistry.configure()   ← يُستدعى تلقائياً عند التشغيل
        ↓
GetIt.registerLazySingleton<XService>(() => XServiceImpl())
        ↓
Feature: getIt<XService>()   ← يعمل تلقائياً
```

إذا كان الـ flag = false → الخدمة **لا تُسجَّل** → أي `getIt<XService>()` سيرمي استثناءً.

---

## P6 — BiometricsService · بصمة الإصبع / Face ID

| الحزمة | `local_auth: ^3.0.1` |
|--------|----------------------|
| الـ flag | `AppFeatures.biometrics = true` |
| الأذونات | نعم (يجب تشغيل `sync_permissions.dart`) |

**الاستخدام:**
```dart
// في الـ Cubit أو UseCase:
final _bio = getIt<BiometricsService>();

Future<void> unlockWithBiometrics() async {
  if (!await _bio.isAvailable()) return; // الجهاز لا يدعم
  if (!await _bio.isEnrolled())  return; // لا يوجد بصمة مسجّلة

  final ok = await _bio.authenticate('أكّد هويتك للمتابعة');
  if (ok) { /* فتح المحتوى الحساس */ }
}
```

> **ملاحظة:** البيومتريكس تُثبّت الهوية فقط. الـ tokens تُحفظ في `SecureStorageService`.

**Android `AndroidManifest.xml` (مُضاف تلقائياً بـ sync_permissions):**
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```

**iOS `Info.plist`:**
```xml
<key>NSFaceIDUsageDescription</key>
<string>نستخدم Face ID لتأمين الحساب</string>
```

---

## P7 — ClipboardService · حافظة النصوص

| الحزمة | Flutter built-in (بدون حزمة إضافية) |
|--------|--------------------------------------|
| الـ flag | `AppFeatures.clipboard = true` (مفعّل افتراضياً) |
| الأذونات | لا يحتاج |

**الاستخدام:**
```dart
final _clip = getIt<ClipboardService>();

await _clip.copy('النص المنسوخ');
final text = await _clip.paste(); // null إذا كانت الحافظة فارغة
```

---

## P8 — ShareService · مشاركة النص / الملف

| الحزمة | `share_plus: ^10.1.3` |
|--------|------------------------|
| الـ flag | `AppFeatures.shareSheet = true` |
| الأذونات | لا يحتاج عادةً |

**الاستخدام:**
```dart
final _share = getIt<ShareService>();

// نص أو رابط:
await _share.shareText('تحقق من هذا الرابط: https://example.com');

// ملف:
await _share.shareFile(file, mimeType: 'application/pdf');
```

> نافذة المشاركة تُفتح بـ OS sheet — لا تحتاج إذناً.

---

## P9 — FileService · اختيار / تحميل / فتح الملفات

| الحزمة | `file_picker: ^9.0.2` + `open_filex: ^1.3.6` |
|--------|-----------------------------------------------|
| الـ flag | `AppFeatures.fileOperations = true` |
| الأذونات | `AppFeatures.fileStorage = true` (لحفظ في Downloads) |

**الاستخدام:**
```dart
final _files = getIt<FileService>();

// اختيار ملف:
final file = await _files.pick(allowedExtensions: ['pdf', 'docx']);

// تحميل ملف:
final saved = await _files.download('https://api.example.com/report.pdf', 'report.pdf');

// فتح الملف مع التطبيق المناسب:
if (saved != null) await _files.open(saved);

// حفظ في مجلد Downloads:
if (saved != null) await _files.saveToDownloads(saved);
```

---

## P10 — AppLifecycleService · مراقبة دورة حياة التطبيق

| الحزمة | Flutter built-in |
|--------|-----------------|
| الـ flag | `AppFeatures.appLifecycle = true` (مفعّل افتراضياً) |
| التسجيل | `registerSingleton` (فوري — لا يفوته أي حدث) |

**الاستخدام:**
```dart
final _lifecycle = getIt<AppLifecycleService>();

_lifecycle.stateStream.listen((state) {
  switch (state) {
    case AppLifecycleState.paused:
      // التطبيق ذهب للخلفية → أوقف التحديثات
    case AppLifecycleState.resumed:
      // التطبيق عاد → أعد التحديثات
    default: break;
  }
});
```

> **تحذير:** لا تُعطّل هذه الخدمة إلا إن كنت متأكداً — `SyncController` يعتمد عليها لإيقاف المزامنة في الخلفية.

---

## I4 — CertificatePinning · تثبيت الشهادة

| الحزمة | `dio` (مدمج) |
|--------|-------------|
| الـ flag | `AppFeatures.certificatePinning = true` |
| المتطلب | إضافة الـ fingerprints في `platform_services_registry.dart` |

**كيف تحصل على الـ fingerprint:**
```bash
openssl s_client -connect api.example.com:443 < /dev/null 2>/dev/null \
  | openssl x509 -outform DER \
  | openssl dgst -sha256 -hex
```

**الضبط في `PlatformServicesRegistry._applyCertificatePinning()`:**
```dart
const config = CertificatePinningConfig(
  allowedSha256Fingerprints: {
    'abc123...primary_fingerprint',
    'def456...backup_fingerprint',   // احتياطي للتجديد التدريجي
  },
);
config.apply(getIt<Dio>());
```

> ⚠️ **لا تُفعّل هذا بـ fingerprints فارغة** — ستُرفض جميع الطلبات.
> استخدم في الـ production فقط بعد التحقق من الـ fingerprints.

---

## إضافة خدمة اختيارية جديدة

```
1. أنشئ: lib/core/platform/<category>/<service>.dart   ← interface
2. أنشئ: lib/core/platform/<category>/<service>_impl.dart ← impl
3. أضف:  AppFeatures.myService = false  في app_features.dart
4. أضف:  _registerMyService(getIt) في platform_services_registry.dart
5. وثّق: أضف قسماً في هذا الملف
```

---

## ما النتيجة إذا استخدمت خدمة معطّلة؟

```dart
// AppFeatures.biometrics = false
getIt<BiometricsService>() // ← StateError: BiometricsService not registered
```

**الحل الصحيح:**
```dart
// التحقق قبل الاستخدام:
if (AppFeatures.biometrics && getIt.isRegistered<BiometricsService>()) {
  final bio = getIt<BiometricsService>();
  // ...
}
```
