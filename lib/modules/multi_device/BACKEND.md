# Multi-Device Session — Backend Contract

> هذا الملف موجّه لمطوّر الـ Backend حصراً.
> يحتوي على كل ما يجب تنفيذه من جهة السيرفر حتى يعمل الموديول.

---

## ١ — قاعدة البيانات

```sql
CREATE TABLE device_sessions (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID        NOT NULL REFERENCES users(id),
  device_id      TEXT        NOT NULL,
  device_name    TEXT        NOT NULL,
  platform       TEXT        NOT NULL CHECK (platform IN ('ios','android','web')),
  app_version    TEXT,
  fcm_token      TEXT,
  is_primary     BOOLEAN     NOT NULL DEFAULT false,
  access_token   TEXT        UNIQUE NOT NULL,
  refresh_token  TEXT        UNIQUE NOT NULL,
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at     TIMESTAMPTZ,
  revoke_reason  TEXT        CHECK (revoke_reason IN (
                   'logout','manual','limit_exceeded',
                   'password_changed','account_deleted')),

  UNIQUE (user_id, device_id)
);

-- Primary واحد فقط لكل مستخدم في أي وقت
CREATE UNIQUE INDEX ON device_sessions (user_id)
  WHERE is_primary = true AND revoked_at IS NULL;

CREATE INDEX ON device_sessions (user_id) WHERE revoked_at IS NULL;
CREATE INDEX ON device_sessions (access_token);
CREATE INDEX ON device_sessions (refresh_token);
```

---

## ٢ — قواعد العمل

```
① حد الأجهزة = 3 (configurable في env)

② تسجيل دخول بنفس device_id موجود:
   → حدّث access_token + refresh_token + fcm_token + last_active_at
   → is_primary لا يتغيّر

③ تسجيل دخول بـ device_id جديد — الحساب بلا جلسات:
   → أنشئ جلسة بـ is_primary = true

④ تسجيل دخول بـ device_id جديد — العدد أقل من الحد:
   → أنشئ جلسة بـ is_primary = false

⑤ تسجيل دخول بـ device_id جديد — العدد = الحد:
   → اختار أقدم جلسة حيث is_primary = false (created_at ASC)
   → عيّن revoked_at = NOW(), revoke_reason = 'limit_exceeded'
   → أرسل FCM للجهاز المُلغى (إن كان fcm_token متاحاً)
   → أنشئ الجلسة الجديدة بـ is_primary = false
   ⚠️ لا تمسّ جلسة is_primary = true أبداً

⑥ كل request → حدّث last_active_at للجلسة المقابلة لـ X-Device-ID

⑦ عند التحقق من access_token:
   revoked_at ≠ null  →  401 SESSION_REVOKED
   token منتهٍ        →  401 SESSION_EXPIRED
   token غير موجود   →  401 INVALID_TOKEN

⑧ DELETE /auth/devices/{id} — قبل التنفيذ:
   تحقق أن is_primary للجلسة الطالبة = true
   إذا لا  →  403 NOT_PRIMARY
   إذا نعم →  أكمل

⑨ Primary يُلغي نفسه:
   مسموح → عيّن revoked_at
   → أعطِ is_primary = true لأقدم جلسة نشطة (created_at ASC)

⑩ تغيير كلمة المرور:
   → ألغِ كل الجلسات الأخرى (revoke_reason = 'password_changed')
   → أرسل FCM لكل جهاز مُلغى
```

---

## ٣ — الـ Headers المطلوبة من الكلاينت

يُرسل الكلاينت هذه الـ headers على كل طلب:

```
Authorization: Bearer {access_token}
X-Device-ID:   {device_id}
```

السيرفر يستخدم `X-Device-ID` لتحديث `last_active_at` للجلسة الصحيحة.

---

## ٤ — POST /auth/login

**Request body:**
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
  "revoked_device":       null,
  "user": { "id": "...", "name": "...", "email": "..." }
}
```

**Response 200 — أول تسجيل (Primary):**
```json
{
  "access_token":         "...",
  "refresh_token":        "...",
  "expires_in":           900,
  "device_session_id":    "ds_abc",
  "is_primary":           true,
  "active_devices_count": 1,
  "max_devices":          3,
  "revoked_device":       null
}
```

**Response 200 — مع إلغاء جهاز:**
```json
{
  "access_token":         "...",
  "device_session_id":    "ds_new",
  "is_primary":           false,
  "active_devices_count": 3,
  "max_devices":          3,
  "revoked_device": {
    "device_session_id": "ds_oldest",
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

**Side effect:**
أرسل FCM لكل الأجهزة النشطة الأخرى:
```json
{
  "data": {
    "type": "new_device_login",
    "device_name": "iPhone 15 Pro",
    "platform": "ios",
    "login_at": "2026-06-21T08:00:00Z",
    "device_session_id": "ds_new"
  }
}
```

---

## ٥ — POST /auth/refresh

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

## ٦ — GET /auth/devices

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

> لا تُرجع `access_token` أو `refresh_token` في هذا الرد أبداً.

> `is_current` يُحدَّد بمقارنة `X-Device-ID` header بالـ `device_id` في قاعدة البيانات.

---

## ٧ — DELETE /auth/devices/{device_session_id}

**شرط:** الجهاز الطالب يجب أن يكون `is_primary = true`.

**Response 200:**
```json
{ "revoked": true, "device_name": "Samsung Galaxy S24" }
```

**Response 403 — ليس Primary:**
```json
{ "code": "NOT_PRIMARY", "message": "Only the primary device can revoke sessions" }
```

**Response 403 — جهاز لمستخدم آخر:**
```json
{ "code": "NOT_YOUR_DEVICE" }
```

**Response 404:**
```json
{ "code": "DEVICE_NOT_FOUND" }
```

**Side effects:**
```
→ عيّن revoked_at = NOW(), revoke_reason = 'manual'

→ FCM للجهاز المُلغى:
  { "data": { "type": "session_revoked",
              "device_session_id": "ds_xyz",
              "revoked_by_device": "اسم الجهاز Primary",
              "reason": "manual" } }

→ FCM لبقية الأجهزة (اختياري):
  { "data": { "type": "device_removed",
              "device_name": "Samsung Galaxy S24" } }
```

---

## ٨ — DELETE /auth/devices/all-except-current

**شرط:** الجهاز الطالب يجب أن يكون `is_primary = true`.

**Response 200:**
```json
{
  "revoked_count": 2,
  "revoked_devices": [
    { "device_session_id": "ds_xyz", "device_name": "Samsung Galaxy S24" }
  ]
}
```

**Side effects:**
```
→ عيّن revoked_at = NOW() لكل الجلسات ما عدا الحالية
→ FCM لكل جهاز مُلغى (type: session_revoked)
```

---

## ٩ — POST /auth/logout

**Response 200:**
```json
{ "logged_out": true }
```

**Side effect:**
```
→ عيّن revoked_at = NOW(), revoke_reason = 'logout'
→ لا FCM (المستخدم هو من سجّل الخروج)
```

---

## ١٠ — كل 401 — الأكواد الإلزامية

```json
{ "code": "SESSION_EXPIRED",     "message": "..." }
{ "code": "SESSION_REVOKED",     "message": "..." }
{ "code": "INVALID_TOKEN",       "message": "..." }
{ "code": "INVALID_CREDENTIALS", "message": "..." }
```

| code | تصرف الكلاينت |
|---|---|
| `SESSION_EXPIRED` | محاولة refresh تلقائية |
| `SESSION_REVOKED` | مسح + انتقال للدخول + رسالة "تم تسجيل خروجك" |
| `INVALID_TOKEN` | مسح + انتقال للدخول |
| `INVALID_CREDENTIALS` | عرض خطأ للمستخدم |

---

## ١١ — FCM Payloads الكاملة

جميعها **silent** (بدون `notification` key):

```json
// ١ — جهاز جديد دخل
{ "data": { "type": "new_device_login",
            "device_name": "iPhone 15 Pro",
            "platform": "ios",
            "login_at": "ISO",
            "device_session_id": "ds_new" } }

// ٢ — جلستك أُلغيت
{ "data": { "type": "session_revoked",
            "device_session_id": "ds_xyz",
            "revoked_by_device": "iPhone 15 Pro",
            "reason": "manual | limit_exceeded | password_changed" } }

// ٣ — جهاز آخر أُزيل من الحساب
{ "data": { "type": "device_removed",
            "device_name": "Samsung Galaxy S24" } }
```
