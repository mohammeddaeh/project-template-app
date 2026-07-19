# Multi-Device Session Module

> **الحالة:** تصميم مكتمل — جاهز للتنفيذ بعد موافقة Backend
> **الموقع:** `lib/modules/multi_device/`
> **الفكرة:** نفس الحساب يعمل على أجهزة متعددة في نفس الوقت — كل جهاز له جلسة مستقلة

---

## جدول المحتويات

1. [المشكلة والهدف](#١--المشكلة-والهدف)
2. [المفاهيم الأساسية](#٢--المفاهيم-الأساسية)
3. [دورة الحياة الكاملة](#٣--دورة-الحياة-الكاملة)
4. [جميع سيناريوهات الأخطاء](#٤--جميع-سيناريوهات-الأخطاء)
5. [هيكل الموديول](#٥--هيكل-الموديول)
6. [الاندماج مع التيمب — الحد الأدنى فقط](#٦--الاندماج-مع-التيمب--الحد-الأدنى-فقط)
7. [Backend Contract](#٧--backend-contract)
8. [ترتيب التنفيذ](#٨--ترتيب-التنفيذ)

---

## ١ — المشكلة والهدف

### الوضع الحالي في التيمب

```
المستخدم يسجّل دخول من جهاز 1  →  token_A يُحفظ
المستخدم يسجّل دخول من جهاز 2  →  token_B جديد
                                 →  token_A أُلغي على السيرفر
جهاز 1 يرسل طلب بـ token_A     →  401 SESSION_EXPIRED
جهاز 1 يعيد توجيه المستخدم لشاشة الدخول
```

**المشكلة:** token واحد لكل مستخدم — تسجيل دخول جديد يُلغي الجلسات القديمة.

### الهدف

```
جهاز 1  →  session_A  [PRIMARY] (محمية — لا تُلغى تلقائياً أبداً)
جهاز 2  →  session_B  (نشطة)
جهاز 3  →  session_C  (نشطة)
جهاز 4  →  session_D  (يريد الدخول — الحد 3)
           session_B  (الأقدم من غير PRIMARY → تُلغى)
           session_D  (نشطة الآن)
```

### القرارات المُتخذة

| القرار | القيمة | ملاحظة |
|---|---|---|
| الحد الأقصى للأجهزة | **3** | قابل للتعديل في `MultiDeviceConfig` |
| الجهاز الأساسي (Primary) | أول جهاز سجّل الدخول للحساب | محمي — لا يُلغى تلقائياً |
| عند تجاوز الحد | أقدم جلسة **غير primary** تُلغى | Primary لا يُمسّ |
| صلاحية الإلغاء | **Primary فقط** يلغي الأجهزة الأخرى | الأجهزة الأخرى لا تملك هذه الصلاحية |
| اكتشاف الإلغاء | FCM + 401 معاً | FCM فوري، 401 ضمان احتياطي |
| إشعار جهاز جديد | ✅ مطلوب | لأسباب أمنية |
| شاشة إدارة الأجهزة | ✅ مطلوبة | في الإعدادات — أزرار الإلغاء لـ Primary فقط |

---

## ٢ — المفاهيم الأساسية

### device_id — هوية الجهاز الثابتة

```
الإنشاء   : UUID v4 عند أول تشغيل للتطبيق
التخزين   : StorageService بمفتاح PersistenceKeys.deviceId
يتغيّر    : فقط عند حذف التطبيق أو مسح بياناته
لا يتغيّر : عند تسجيل خروج / دخول مجدد / تغيير كلمة المرور
```

### device_session — جلسة الجهاز

```
= access_token + refresh_token مرتبطان بـ (user_id + device_id)
كل جهاز له جلسة مستقلة
إلغاء جهاز لا يؤثر على الأجهزة الأخرى
```

### الجهاز الأساسي (Primary Device)

```
التعريف  : أول جهاز يُسجّل دخولاً ناجحاً لهذا الحساب
التخزين  : is_primary = true في جدول device_sessions
الحماية  : لا يُلغى أبداً عند تجاوز حد الأجهزة
الصلاحية : هو الوحيد الذي يمكنه إلغاء جلسات الأجهزة الأخرى

مثال:
  الحساب على جهاز 1 (Primary) + جهاز 2 + جهاز 3
  جهاز 1 يضغط "إلغاء جهاز 2" → مسموح ✅
  جهاز 2 يضغط "إلغاء جهاز 3" → مرفوض ❌ (403 NOT_PRIMARY)
  جهاز 4 يريد الدخول        → يُلغي جهاز 2 أو 3 (الأقدم) — لا يمسّ جهاز 1
```

### الفرق عن الـ token التقليدي

```
Token تقليدي:  user_id → token واحد
Device session: user_id + device_id → token لكل جهاز + Primary محمي
```

---

## ٣ — دورة الحياة الكاملة

### ٣.١ — تسجيل الدخول

```
① الموديول يقرأ device_id من StorageService
  └─ غير موجود؟ → يُولِّد UUID جديد ويُخزّنه

② يُرسل POST /auth/login مع بيانات الجهاز

③ السيرفر يتحقق من بيانات الدخول

④ السيرفر يتحقق من وجود جلسة سابقة لنفس device_id:
  ├─ موجودة → يُحدِّث tokens (is_primary يبقى كما هو — لا تغيير)
  └─ جديدة  → يتحقق من عدد الأجهزة النشطة:
      ├─ لا توجد جلسات أخرى → يُنشئ جلسة بـ is_primary = true ← أول جهاز للحساب
      ├─ أقل من الحد         → يُنشئ جلسة بـ is_primary = false
      └─ يساوي الحد          → اختار أقدم جلسة حيث is_primary = false
                                → يُلغيها ثم يُنشئ الجديدة (is_primary = false)
                                → Primary محمي — لا يُلغى تلقائياً أبداً

⑤ السيرفر يُرسل FCM لكل الأجهزة الأخرى: "جهاز جديد سجّل الدخول"

⑥ الكلاينت يُخزّن access_token + refresh_token + device_session_id + is_primary
   (is_primary يُحدد ما إذا كانت أزرار "إلغاء الأجهزة" تظهر في الشاشة)
```

### ٣.٢ — كل طلب HTTP

```
MultiDeviceInterceptor (مسجَّل في Dio عند تفعيل الموديول):
  → يُضيف: X-Device-ID: {device_id}
  → باقي Headers يُضيفها AuthInterceptor الموجود
```

### ٣.٣ — انتهاء صلاحية access_token

```
① أي طلب يرد بـ 401 + code: SESSION_EXPIRED
② AuthInterceptor يلتقطه (السلوك الحالي بالتيمب)
③ يحاول refresh token تلقائياً
④ يُعيد الطلب الأصلي بالـ token الجديد
⑤ نجح → يكمل بشكل طبيعي
  فشل  → انتقل لـ ٣.٥
```

### ٣.٤ — إلغاء الجلسة من جهاز آخر

```
المسار الأول — عبر FCM (التطبيق مفتوح أو في الخلفية):
  ① FCM يصل بـ type: "session_revoked"
  ② DeviceNotificationHandler يتحقق: هل device_session_id يطابق الجلسة الحالية؟
     مطابق  → مسح البيانات المحلية + إطلاق AuthEvent.sessionRevoked
     غير مطابق → تجاهل (إشعار لجهاز آخر وصل بالخطأ)
  ③ app.dart يلتقط الحدث → يعرض رسالة → ينتقل للدخول

المسار الثاني — عبر 401 (احتياطي إذا فات FCM):
  ① أي طلب يرد بـ 401 + code: SESSION_REVOKED
  ② MultiDeviceInterceptor يلتقطه (قبل AuthInterceptor العادي)
  ③ يمسح البيانات المحلية + يُطلق AuthEvent.sessionRevoked
```

### ٣.٥ — تسجيل الخروج

```
① المستخدم يضغط "تسجيل خروج"
② الكلاينت يُرسل POST /auth/logout
③ الكلاينت يمسح بياناته المحلية بغض النظر عن نجاح الطلب
   (حتى لو كان أوفلاين)
④ الانتقال لشاشة الدخول
```

### ٣.٦ — إلغاء جهاز من شاشة "الأجهزة المرتبطة"

```
شرط مسبق: هذه الشاشة تظهر أزرار "إلغاء" فقط إذا is_primary == true للجهاز الحالي
           الأجهزة غير Primary ترى القائمة بدون أزرار إلغاء (قراءة فقط)

① Primary يضغط "إلغاء" على جهاز معين
② تأكيد: "هل تريد تسجيل الخروج من [اسم الجهاز]؟"
③ DELETE /auth/devices/{device_session_id}
   السيرفر يتحقق: هل الطالب هو Primary؟
   ├─ نعم → يُلغي الجلسة + FCM للجهاز المُلغى
   └─ لا  → 403 NOT_PRIMARY
④ القائمة تتحدث
```

---

## ٤ — جميع سيناريوهات الأخطاء

### الأخطاء على الكلاينت

| # | السيناريو | السبب | التصرف |
|---|---|---|---|
| E1 | فشل إنشاء device_id | StorageService غير جاهز | إعادة المحاولة — يتوقف عن المتابعة إذا استمر الفشل |
| E2 | تغيّر device_id بعد مسح البيانات | المستخدم مسح بيانات التطبيق | تسجيل دخول مجدد — جلسة جديدة لنفس الجهاز فعلياً |
| E3 | FCM token منتهٍ أو تغيّر | تحديث التطبيق أو إعادة تثبيته | تحديث FCM token عند أول تشغيل ناجح |
| E4 | FCM لم يصل (جهاز أوفلاين) | لا إنترنت وقت الإلغاء | 401 SESSION_REVOKED يتولى عند العودة |
| E5 | طلبان يحاولان refresh في نفس الوقت | race condition | قفل: الطلب الأول يُنفَّذ، الثاني ينتظر نتيجته |
| E6 | refresh_token منتهٍ | المستخدم لم يفتح التطبيق 30 يوماً | تسجيل دخول كامل مجدداً |
| E7 | تسجيل خروج وهو أوفلاين | لا اتصال | يُنظّف محلياً فوراً — يُرسل للسيرفر عند الاتصال (أو يتجاهل) |
| E8 | استقبل FCM لجهاز آخر | device_session_id لا يتطابق | تجاهل — لا إجراء |

### الأخطاء من السيرفر

| كود HTTP | code في الـ body | المعنى | تصرف الكلاينت |
|---|---|---|---|
| 401 | `SESSION_EXPIRED` | access_token انتهت صلاحيته | محاولة refresh تلقائية |
| 401 | `SESSION_REVOKED` | الجلسة أُلغيت | مسح + انتقال للدخول + رسالة خاصة |
| 401 | `INVALID_TOKEN` | token مزيّف أو تالف | مسح + انتقال للدخول |
| 401 | `INVALID_CREDENTIALS` | بيانات الدخول خاطئة | عرض خطأ للمستخدم |
| 403 | `NOT_PRIMARY` | الجهاز ليس Primary — لا صلاحية إلغاء | إخفاء أزرار الإلغاء في الـ UI |
| 403 | `ACCOUNT_DISABLED` | الحساب موقوف | عرض رسالة "حسابك موقوف" |
| 404 | `DEVICE_NOT_FOUND` | الجهاز غير موجود عند الإلغاء | تجاهل (ربما أُلغي مسبقاً) |
| 422 | `VALIDATION_ERROR` | حقل مفقود أو غير صالح | عرض خطأ للمطوّر |
| 429 | `RATE_LIMITED` | محاولات دخول كثيرة | عرض "حاول مجدداً بعد X ثانية" |
| 5xx | — | خطأ في السيرفر | `ServerFailure` العادية |

### سيناريوهات الحافة (Edge Cases)

```
الحافة ١ — الجهاز يسجّل دخول بعد إلغائه مباشرة:
  الكلاينت → POST /auth/login
  السيرفر  ← يقبل الدخول (بيانات صحيحة) ويُنشئ جلسة جديدة بـ is_primary = false
  النتيجة  = طبيعية — الإلغاء السابق لا يمنع الدخول المستقبلي

الحافة ٢ — جهاز غير Primary يحاول إلغاء جهاز آخر:
  جهاز 2 يرسل DELETE /auth/devices/ds_3
  السيرفر يتحقق: is_primary للجهاز الطالب؟ لا
  النتيجة  = 403 NOT_PRIMARY
  الكلاينت = رسالة "لا تملك صلاحية هذا الإجراء"

الحافة ٣ — Primary يُلغي نفسه:
  DELETE /auth/devices/{primary_session_id}
  السيرفر يقبل (المستخدم حرّ)
  يُعيّن is_primary للجلسة التالية الأقدم بـ true
  الجهاز الأقدم يصبح Primary تلقائياً

الحافة ٤ — المستخدم يُغيّر كلمة المرور:
  يجب على السيرفر: إلغاء كل الجلسات ما عدا الحالية (أو كلها)
  كل الأجهزة الأخرى → FCM session_revoked + reason: "password_changed"
  الجهاز الحالي → ينتقل لإعادة الدخول أو يبقى (حسب سياسة التطبيق)

الحافة ٤ — المستخدم يحذف حسابه:
  السيرفر يُلغي كل الجلسات
  كل الأجهزة → FCM type: "account_deleted"
  الكلاينت يمسح كل البيانات المحلية

الحافة ٥ — device_id متضارب (جهازان يولّدان نفس UUID بشكل نادر جداً):
  السيرفر يعرف: (user_id, device_id) UNIQUE
  إذا تضارب: الجلسة الموجودة تُحدَّث (نفس سلوك إعادة الدخول)
  عملياً: UUID v4 = 2^122 احتمالاً — الاحتمال مُهمَل
```

---

## ٥ — هيكل الموديول

```
lib/modules/multi_device/
│
├── README.md                            ← هذا الملف
├── SETUP.md                             ← دليل التفعيل خطوة بخطوة
├── multi_device_plugin.dart             ← entry point الوحيد
│
├── config/
│   └── multi_device_config.dart
│       maxDevices: int = 3
│       sessionRevokedFcmType: String = 'session_revoked'
│       newDeviceLoginFcmType: String = 'new_device_login'
│
├── domain/
│   ├── device_session.dart              ← نموذج بيانات الجلسة
│   │   id, deviceId, deviceName, platform, lastActiveAt,
│   │   createdAt, isCurrent
│   │
│   ├── device_session_repository.dart   ← interface
│   │   getActiveSessions()
│   │   revokeSession(id)
│   │   revokeAllExceptCurrent()
│   │
│   └── failures/
│       └── device_session_failure.dart  ← DeviceNotFoundFailure
│                                           SessionAlreadyRevokedFailure
│
├── data/
│   ├── device_session_api_service.dart  ← Retrofit
│   │   GET  /auth/devices
│   │   DELETE /auth/devices/{id}
│   │   DELETE /auth/devices/all-except-current
│   │   POST /auth/logout
│   │   POST /auth/refresh
│   │
│   └── device_session_repository_impl.dart
│
├── services/
│   ├── device_id_service.dart
│   │   ─ يقرأ device_id من StorageService
│   │   ─ إذا غير موجود → يُولّد UUID ويُخزّنه
│   │   ─ static getter: DeviceIdService.current
│   │
│   └── device_notification_handler.dart
│       ─ يستقبل FCM silent notifications
│       ─ يُطابق device_session_id
│       ─ يُطلق AuthEvent.sessionRevoked عند التطابق
│
├── interceptor/
│   └── multi_device_interceptor.dart    ← Dio Interceptor منفصل
│       onRequest:  يُضيف X-Device-ID header
│       onError:    يلتقط 401 + SESSION_REVOKED
│                   يُطلق AuthEvent.sessionRevoked
│                   (يعمل قبل AuthInterceptor — أولوية أعلى)
│
├── integration/
│   └── multi_device_bootstrap.dart
│       ─ يُسجّل كل الخدمات في DI
│       ─ يُضيف MultiDeviceInterceptor لـ Dio
│       ─ لا يُعدّل AuthInterceptor
│
└── presentation/
    ├── active_devices_cubit.dart
    ├── active_devices_state.dart
    └── pages/
        └── active_devices_screen.dart
```

---

## ٦ — الاندماج مع التيمب — الحد الأدنى فقط

> الموديول **لا يُعدّل أي ملف موجود** إلا هذه الإضافات البسيطة.
> كل الإضافات **backward-compatible** — لا تُكسر شيئاً إذا الموديول معطَّل.

---

### ٦.١ — تفعيل الموديول (سطر واحد)

```dart
// lib/core/platform/features/app_features.dart
static const multiDevice = false;  // ← غيّره إلى true
```

---

### ٦.٢ — PersistenceKeys (إضافة ثوابت)

```dart
// lib/core/platform/storage/persistence_keys.dart
static const String deviceId        = 'device_id';
static const String deviceSessionId = 'device_session_id';
```

---

### ٦.٣ — AuthEvent (إضافة حدث)

```dart
// lib/core/infra/session/auth_event_bus.dart
enum AuthEvent {
  sessionExpired,   // موجود
  sessionRevoked,   // جديد — الجلسة أُلغيت من جهاز آخر
}
```

`AuthEventBus.emit()` يعمل مع الحدثين بنفس آلية deduplication الموجودة.

---

### ٦.٤ — app.dart (إضافة حالة)

```dart
// lib/app.dart
_authSub = AuthEventBus.instance.stream.listen((event) {
  switch (event) {
    case AuthEvent.sessionExpired:
      // السلوك الحالي — لا تغيير
      router.pushAndPopUntil(const LoginRoute(), predicate: (_) => false);
    case AuthEvent.sessionRevoked:
      // جديد — رسالة مختلفة
      router.pushAndPopUntil(
        const LoginRoute(revokedSession: true),
        predicate: (_) => false,
      );
  }
});
```

---

### ٦.٥ — LoginParams (حقول اختيارية)

```dart
// lib/Features/auth/domain/entities/login_params.dart
class LoginParams extends UseCaseParams {
  const LoginParams({
    required this.email,
    required this.password,
    this.languageCode = 'ar',
    // جديد — اختياري: يُملأ فقط إذا AppFeatures.multiDevice == true
    this.deviceId,
    this.deviceName,
    this.platform,
    this.fcmToken,
  });

  final String email;
  final String password;
  final String languageCode;
  final String? deviceId;
  final String? deviceName;
  final String? platform;
  final String? fcmToken;
}
```

---

### ٦.٦ — main.dart (تفعيل الموديول)

```dart
// lib/main.dart — بعد configureInjection
if (AppFeatures.multiDevice) {
  await MultiDevicePlugin.initialize(getIt);
}
```

---

### ملخص التغييرات على الكور

| الملف | نوع التغيير | الحجم |
|---|---|---|
| `app_features.dart` | إضافة ثابت | سطر واحد |
| `persistence_keys.dart` | إضافة ثوابت | سطران |
| `auth_event_bus.dart` | إضافة enum value | سطر واحد |
| `app.dart` | إضافة case في switch | 4 أسطر |
| `login_params.dart` | إضافة حقول اختيارية | 4 أسطر |
| `main.dart` | استدعاء initialize | 3 أسطر |

**المجموع: 15 سطراً في 6 ملفات — لا شيء يُحذف أو يُعدَّل.**

---

## ٧ — Backend Contract

### ٧.١ — قاعدة البيانات

```sql
CREATE TABLE device_sessions (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID        NOT NULL REFERENCES users(id),
  device_id      TEXT        NOT NULL,
  device_name    TEXT        NOT NULL,
  platform       TEXT        NOT NULL CHECK (platform IN ('ios','android','web')),
  app_version    TEXT,
  fcm_token      TEXT,
  is_primary     BOOLEAN     NOT NULL DEFAULT false,  -- أول جهاز للحساب
  access_token   TEXT        UNIQUE NOT NULL,
  refresh_token  TEXT        UNIQUE NOT NULL,
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at     TIMESTAMPTZ,
  revoke_reason  TEXT        CHECK (revoke_reason IN
                   ('logout','manual','limit_exceeded','password_changed','account_deleted')),

  UNIQUE (user_id, device_id)
);

-- يضمن وجود Primary واحد فقط لكل مستخدم في أي وقت
CREATE UNIQUE INDEX ON device_sessions (user_id)
  WHERE is_primary = true AND revoked_at IS NULL;

CREATE INDEX ON device_sessions (user_id) WHERE revoked_at IS NULL;
CREATE INDEX ON device_sessions (access_token);
CREATE INDEX ON device_sessions (refresh_token);
```

---

### ٧.٢ — قواعد العمل

```
① حد الأجهزة = 3 (configurable)

② تسجيل دخول بنفس device_id موجود:
   → حدّث access_token + refresh_token + fcm_token + last_active_at
   → is_primary لا يتغيّر — يبقى كما هو

③ تسجيل دخول بـ device_id جديد والحساب ليس له أي جلسات:
   → أنشئ الجلسة بـ is_primary = true  ← أول جهاز

④ تسجيل دخول بـ device_id جديد والعدد أقل من الحد:
   → أنشئ الجلسة بـ is_primary = false

⑤ تسجيل دخول بـ device_id جديد والعدد = الحد:
   → اعثر على أقدم جلسة حيث is_primary = false (created_at ASC)
   → عيّن revoked_at = NOW(), revoke_reason = 'limit_exceeded'
   → أرسل FCM للجهاز المُلغى
   → أنشئ الجلسة الجديدة بـ is_primary = false
   ⚠️ لا تمسّ الجلسة الـ Primary أبداً

⑥ كل request → حدّث last_active_at للجلسة الحالية

⑦ عند التحقق من access_token:
   revoked_at ≠ null  →  401 SESSION_REVOKED
   token منتهٍ        →  401 SESSION_EXPIRED
   token غير موجود   →  401 INVALID_TOKEN

⑧ عند DELETE /auth/devices/{id}:
   تحقق أن is_primary للجلسة الطالبة = true
   إذا لا → 403 NOT_PRIMARY
   إذا نعم → أكمل الإلغاء

⑨ Primary يُلغي نفسه (DELETE على session_id الخاص به):
   → مسموح — عيّن revoked_at
   → أعطِ is_primary = true لأقدم جلسة نشطة (created_at ASC)
   → إن لم تكن جلسات أخرى → لا يوجد Primary حتى تسجيل الدخول القادم

⑩ تغيير كلمة المرور → أَلغِ كل الجلسات + FCM لكلٍّ منها
```

---

### ٧.٣ — POST /auth/login

**Request:**
```json
{
  "email":        "user@example.com",
  "password":     "...",
  "device_id":    "550e8400-e29b-41d4-a716-446655440000",
  "device_name":  "iPhone 15 Pro",
  "platform":     "ios",
  "app_version":  "1.2.0",
  "fcm_token":    "..."
}
```

**Response 200 — طبيعي:**
```json
{
  "access_token":         "eyJhbG...",
  "refresh_token":        "...",
  "expires_in":           900,
  "device_session_id":    "ds_abc",
  "is_primary":           false,
  "active_devices_count": 2,
  "max_devices":          3,
  "revoked_device":       null
}
```

**Response 200 — أول تسجيل دخول (Primary):**
```json
{
  "access_token":         "eyJhbG...",
  "refresh_token":        "...",
  "expires_in":           900,
  "device_session_id":    "ds_abc",
  "is_primary":           true,
  "active_devices_count": 1,
  "max_devices":          3,
  "revoked_device":       null
}
```

**Response 200 — مع إلغاء جهاز (تجاوز الحد — المُلغى دائماً غير Primary):**
```json
{
  "access_token":         "eyJhbG...",
  "refresh_token":        "...",
  "expires_in":           900,
  "device_session_id":    "ds_new",
  "is_primary":           false,
  "active_devices_count": 3,
  "max_devices":          3,
  "revoked_device": {
    "device_session_id": "ds_oldest_non_primary",
    "device_name":       "Samsung Galaxy S24"
  }
}
```

**Response 401:**
```json
{ "code": "INVALID_CREDENTIALS", "message": "..." }
```

**Response 429:**
```json
{ "code": "RATE_LIMITED", "retry_after_seconds": 60 }
```

**Side effects:**
```
→ FCM لكل الأجهزة الأخرى النشطة:
  { "data": { "type": "new_device_login",
              "device_name": "...", "platform": "...",
              "login_at": "ISO", "device_session_id": "ds_new" } }
```

---

### ٧.٤ — POST /auth/refresh

**Request:**
```json
{ "refresh_token": "...", "device_id": "550e..." }
```

**Response 200:**
```json
{ "access_token": "eyJhbG...", "expires_in": 900 }
```

**Response 401:**
```json
{ "code": "SESSION_REVOKED | SESSION_EXPIRED | INVALID_TOKEN" }
```

---

### ٧.٥ — GET /auth/devices

**Response 200:**
```json
{
  "devices": [
    {
      "device_session_id": "ds_abc",
      "device_name":        "iPhone 15 Pro",
      "platform":           "ios",
      "app_version":        "1.2.0",
      "last_active_at":     "2026-06-21T08:00:00Z",
      "created_at":         "2026-05-01T10:00:00Z",
      "is_current":         true,
      "is_primary":         true
    },
    {
      "device_session_id": "ds_xyz",
      "device_name":        "Samsung Galaxy S24",
      "platform":           "android",
      "app_version":        "1.2.0",
      "last_active_at":     "2026-06-20T12:00:00Z",
      "created_at":         "2026-06-01T09:00:00Z",
      "is_current":         false,
      "is_primary":         false
    }
  ],
  "total":       2,
  "max_devices": 3
}
```

> لا تُرجع access_token أو refresh_token أبداً.

---

### ٧.٦ — DELETE /auth/devices/{device_session_id}

**Response 200:**
```json
{ "revoked": true, "device_name": "Samsung Galaxy S24" }
```

**Response 404:**
```json
{ "code": "DEVICE_NOT_FOUND" }
```

**Response 403 — جهاز آخر يملكه مستخدم آخر:**
```json
{ "code": "NOT_YOUR_DEVICE" }
```

**Response 403 — الجهاز الطالب ليس Primary:**
```json
{ "code": "NOT_PRIMARY", "message": "Only the primary device can revoke sessions" }
```

**Side effects:**
```
→ FCM للجهاز المُلغى:
  { "data": { "type": "session_revoked",
              "device_session_id": "ds_xyz",
              "revoked_by_device": "اسم الجهاز المُلغي",
              "reason": "manual" } }

→ FCM لبقية الأجهزة (اختياري — للأمان):
  { "data": { "type": "device_removed", "device_name": "..." } }
```

---

### ٧.٧ — DELETE /auth/devices/all-except-current

**Response 200:**
```json
{
  "revoked_count": 2,
  "revoked_devices": [
    { "device_session_id": "ds_xyz", "device_name": "Samsung" }
  ]
}
```

---

### ٧.٨ — POST /auth/logout

**Response 200:** `{ "logged_out": true }`
**Side effects:** عيّن revoked_at = NOW() — لا FCM.

---

### ٧.٩ — كل 401 — الأكواد المطلوبة

```json
{ "code": "SESSION_EXPIRED",     "message": "..." }
{ "code": "SESSION_REVOKED",     "message": "..." }
{ "code": "INVALID_TOKEN",       "message": "..." }
{ "code": "INVALID_CREDENTIALS", "message": "..." }
```

---

### ٧.١٠ — FCM — القاموس الكامل

```json
// ١ — جهاز جديد دخل (لكل الأجهزة الأخرى)
{ "data": { "type": "new_device_login",
            "device_name": "...", "platform": "ios|android|web",
            "login_at": "ISO", "device_session_id": "ds_new" } }

// ٢ — جلستك أُلغيت
{ "data": { "type": "session_revoked",
            "device_session_id": "ds_xyz",
            "revoked_by_device": "iPhone 15 Pro",
            "reason": "manual|limit_exceeded|password_changed" } }

// ٣ — جهاز آخر أُزيل من حسابك
{ "data": { "type": "device_removed",
            "device_name": "Samsung Galaxy S24" } }
```

> جميعها **silent** (بدون notification key) — الكلاينت يتحكم بعرض الإشعار.

---

## ٨ — ترتيب التنفيذ

### المرحلة ١ — الأساس (لا UI)

```
□ DeviceIdService
□ MultiDeviceConfig
□ MultiDeviceInterceptor (X-Device-ID header + SESSION_REVOKED)
□ إضافة AuthEvent.sessionRevoked
□ إضافة الحقول الاختيارية في LoginParams
□ multi_device_bootstrap.dart
□ تحديث main.dart
□ تحديث app.dart
```

النتيجة: الجلسات تعمل بشكل صحيح، الإلغاء يُعيد التوجيه للدخول.

### المرحلة ٢ — إدارة الأجهزة

```
□ DeviceSessionApiService (Retrofit)
□ DeviceSessionRepositoryImpl
□ ActiveDevicesCubit + State
□ ActiveDevicesScreen
□ إضافة الشاشة في الإعدادات
```

### المرحلة ٣ — الإشعارات

```
□ DeviceNotificationHandler (يتعامل مع FCM)
□ عرض إشعار "جهاز جديد سجّل الدخول"
□ زر "إلغاء هذه الجلسة" في الإشعار
```

---

## شاشة "الأجهزة المرتبطة"

### عندما يفتحها الجهاز الأساسي (Primary = true)

```
┌──────────────────────────────────┐
│  الأجهزة المرتبطة  (2 من 3)      │
├──────────────────────────────────┤
│  📱 iPhone 15 Pro  ⭐ الأساسي    │
│     هذا الجهاز • نشط الآن        │
├──────────────────────────────────┤
│  📱 Samsung Galaxy S24            │
│     Android • آخر نشاط: أمس      │
│                    [تسجيل خروج]  │ ← زر الإلغاء يظهر
├──────────────────────────────────┤
│  [تسجيل خروج من كل الأجهزة]      │ ← يظهر فقط لـ Primary
└──────────────────────────────────┘
```

### عندما يفتحها جهاز غير أساسي (Primary = false)

```
┌──────────────────────────────────┐
│  الأجهزة المرتبطة  (2 من 3)      │
├──────────────────────────────────┤
│  📱 iPhone 15 Pro  ⭐ الأساسي    │
│     نشط اليوم                    │
│                        (لا زر)   │ ← لا يمكن لغير Primary الإلغاء
├──────────────────────────────────┤
│  📱 Samsung Galaxy S24            │
│     هذا الجهاز • نشط الآن        │
│                        (لا زر)   │
└──────────────────────────────────┘
```

**ملاحظة UI:** الكلاينت يتحقق من `is_primary` المخزّن محلياً لإظهار/إخفاء الأزرار.
إذا حاول جهاز غير Primary الإلغاء (bypass عبر API مباشرة) → السيرفر يردّ بـ 403 NOT_PRIMARY.

---

## العلاقة مع الموديولات الأخرى

```
هذا الموديول مستقل تماماً.
يُوفّر device_id لأي موديول يحتاجه:

Multi-Device  →  device_id
                  ↓
            Sync Module (اختياري)
            يُرفق X-Device-ID مع كل sync request
            لإخبار السيرفر بمصدر التغيير
```

---

*جاهز للعرض على Backend — كل التفاصيل موجودة لتنفيذ مستقل.*
