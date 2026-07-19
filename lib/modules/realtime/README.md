# Multi-Device Session Sync — وثيقة التصميم

> **الحالة:** مرحلة التحليل والتصميم — لم يُبنَ بعد
> **الهدف:** نفس الحساب على أجهزة متعددة — التغييرات تنعكس فوراً على الجميع
> **المرجع:** `readme/sync.md` للـ Offline Sync (موديول مختلف ومستقل)

---

## ما المشكلة؟

المستخدم يسجّل دخوله بنفس الحساب على جهازين أو أكثر في نفس الوقت.
أي إجراء على جهاز — إضافة، تعديل، حذف — يجب أن يظهر على كل الأجهزة الأخرى
دون أن يُعيد المستخدم التحميل أو يُشغِّل sync يدوي.

```
[جهاز 1 - موبايل] ─────┐
[جهاز 2 - تابلت  ] ─────┤── نفس الحساب ──► السيرفر
[جهاز 3 - عمل    ] ─────┘
```

تغيير على جهاز 1 → جهاز 2 و 3 يرونه خلال ثوانٍ.

---

## الفرق عن Offline Sync Module

| الجانب | Offline Sync | Multi-Device (هذا الموديول) |
|---|---|---|
| **السؤال** | "ماذا فاتني وأنا أوفلاين؟" | "ماذا تغيّر على الأجهزة الأخرى الآن؟" |
| **من يبدأ؟** | الكلاينت | السيرفر |
| **التوقيت** | عند الاتصال أو كل 5 دقائق | فوري (ثوانٍ) |
| **الاتصال** | HTTP عادي | WebSocket أو SSE (قناة دائمة) |
| **يعمل بدون الآخر؟** | ✅ نعم | ✅ نعم |
| **الأمثلة** | Git, Google Drive sync | WhatsApp Web, Telegram |

---

## المكونات الأساسية للموديول

### ١ — Device Registry (تسجيل الأجهزة)

عند كل تسجيل دخول، الجهاز يُسجِّل نفسه:

```
POST /auth/devices
{
  "device_id": "uuid-فريد-لكل-جهاز",
  "platform": "android | ios | web",
  "fcm_token": "...",
  "app_version": "1.2.0"
}
```

السيرفر يحتفظ بجدول:
```sql
user_devices(user_id, device_id, platform, fcm_token, last_seen_at, last_seq)
```

**`device_id`** يُولَّد مرة واحدة عند أول تشغيل ويُخزَّن في `StorageService`.
لا يتغيّر حتى لو أعاد المستخدم تسجيل الدخول.

---

### ٢ — Transport Layer (القناة الدائمة)

ثلاثة مستويات تعمل معاً:

```
┌─────────────────────────────────────────────────┐
│  المستوى 1: WebSocket / SSE                      │
│  ─ اتصال دائم طالما التطبيق مفتوح               │
│  ─ السيرفر يدفع events فوراً                     │
│  ─ يُقطع عند إغلاق التطبيق                       │
├─────────────────────────────────────────────────┤
│  المستوى 2: FCM / Push Notification              │
│  ─ التطبيق في الخلفية أو مقفول                  │
│  ─ إشعار صامت: "عندك تحديثات، افتح التطبيق"    │
│  ─ عند الفتح → يُشغَّل المستوى 3                │
├─────────────────────────────────────────────────┤
│  المستوى 3: HTTP Catch-up                        │
│  ─ عند فتح التطبيق أو إعادة الاتصال             │
│  ─ GET /events?from_seq=<آخر_seq_وصل>           │
│  ─ يجلب كل ما فات                               │
└─────────────────────────────────────────────────┘
```

**قرار معماري مفتوح:**
- WebSocket: ثنائي الاتجاه، أقوى، يحتاج `web_socket_channel`
- SSE: من السيرفر للكلاينت فقط، أبسط، `http` package كافٍ
- الاختيار يعتمد على ما يدعمه الـ Backend

---

### ٣ — Event Model (نموذج الأحداث)

كل تغيير على السيرفر يُنتج event:

```json
{
  "seq": 1043,
  "user_id": "user-abc",
  "event_type": "entity_changed",
  "entity_name": "mosques",
  "entity_id": "mosque-xyz",
  "operation": "update",
  "changed_fields": ["name", "location"],
  "timestamp": "2026-06-18T11:30:00Z",
  "source_device_id": "iphone-abc"
}
```

**`source_device_id`** مهم: الجهاز الذي أجرى التغيير لا يحتاج أن يستقبله (هو أصلاً عنده أحدث نسخة).

**`seq`** هو الرقم التسلسلي — لا يتراجع، لا يتكرر. كل جهاز يحتفظ بـ `last_seq` خاص به.

---

### ٤ — Sequence Number (الرقم التسلسلي)

لماذا لا نستخدم timestamp؟

```
المشكلة: ساعة الجهاز قد تكون خاطئة بدقيقة أو أكثر
النتيجة: قد يفوت جهاز events لأنه اعتقد أنه استلمها

الحل: seq رقم يزداد بـ 1 كل event — لا غموض
```

كل جهاز يحفظ في `StorageService`:
```
"realtime_last_seq" = 1042
```

عند إعادة الاتصال:
```
GET /events?from_seq=1042&user_id=...
→ السيرفر يرد بكل events من 1043 فصاعداً
```

---

### ٥ — دورة حياة Event على الجهاز

```
السيرفر يُرسل event (seq=1043)
    │
    ▼
RealtimeEventHandler.onEvent(event)
    │
    ├─ هل entity هذه مسجّلة للـ realtime؟
    │   لا  → تجاهل
    │   نعم ↓
    │
    ├─ هل عندنا pending local change لنفس الـ entity؟
    │   نعم → Conflict! ارجع لـ SyncConflictResolver
    │   لا  ↓
    │
    ├─ اكتب البيانات الجديدة في SQLite
    │
    ├─ أطلق StateUpdate → Cubit → UI يتحدّث تلقائياً
    │
    └─ احفظ last_seq = 1043
```

---

### ٦ — التعارض مع Offline Sync

هذا هو أدق جزء في التصميم:

**السيناريو:**
```
جهاز 1: أوفلاين → عدّل مسجد X (pending في الـ queue)
جهاز 2: أونلاين → عدّل نفس المسجد X وحفظ على السيرفر (seq=1043)
جهاز 1: يعود أونلاين
```

**ما الذي يجب أن يحصل؟**

```
جهاز 1 يعود أونلاين:
    ①  Offline Sync يدفع الـ queue
        → السيرفر يرد 409 (Conflict مع جهاز 2)
        → SyncConflictResolver يتولى (serverWins/clientWins/manual)
    
    ②  Realtime يسحب events من آخر seq
        → يستقبل event المسجد X (من جهاز 2)
        → إذا Offline Sync انتهى بـ serverWins → يكتب نسخة السيرفر
        → إذا Offline Sync انتهى بـ clientWins → يتجاهل event جهاز 2
```

**القاعدة:** الـ Offline Sync يعمل أولاً (يدفع) ← ثم Realtime يسحب ما فات.

---

## ما لا يحتاجه هذا الموديول

- ❌ لا يُنشئ نظام sync خاص به — يعتمد على Offline Sync للـ queue
- ❌ لا يُعيد بناء conflict resolution — يستدعي `SyncConflictResolver` الموجود
- ❌ لا يُدير authentication — يستخدم tokens الموجودة في `StorageService`
- ❌ لا يُلزم بـ WebSocket — يعمل مع SSE أو حتى Polling كـ fallback

---

## ما يحتاجه الـ Backend

```
① جدول device_sessions لكل user
② جدول events مرتّب بـ seq (append-only)
③ endpoint: GET /events?from_seq=N
④ WebSocket endpoint أو SSE endpoint
⑤ FCM integration لإرسال silent push عند كل event
⑥ حقل source_device_id في كل write operation
```

---

## هيكل الموديول المقترح

```
lib/modules/realtime/
├── README.md                          ← هذا الملف
├── SETUP.md                           ← دليل التفعيل (لاحقاً)
├── realtime_plugin.dart               ← entry point
├── domain/
│   ├── realtime_event.dart            ← نموذج الـ event
│   ├── device_session.dart            ← نموذج الجهاز
│   └── realtime_event_handler.dart    ← interface للمعالجة
├── config/
│   └── realtime_config.dart           ← transport type, reconnect policy
├── transport/
│   ├── realtime_transport.dart        ← abstract interface
│   ├── websocket_transport.dart       ← WebSocket implementation
│   ├── sse_transport.dart             ← SSE implementation
│   └── polling_transport.dart        ← HTTP polling fallback
├── data/
│   ├── device_registry_service.dart   ← تسجيل/تحديث الجهاز
│   └── realtime_catch_up_service.dart ← سحب الـ events الفائتة
├── engine/
│   ├── realtime_engine.dart           ← القلب: معالجة الـ events
│   └── realtime_reconnect_policy.dart ← إعادة الاتصال عند الانقطاع
├── integration/
│   ├── realtime_bootstrap.dart        ← تسجيل في DI
│   └── realtime_sync_bridge.dart      ← الجسر مع Offline Sync
└── presentation/
    ├── realtime_cubit.dart             ← حالة الاتصال للـ UI
    └── widgets/
        └── connection_status_dot.dart  ← مؤشر الاتصال (أخضر/أحمر)
```

---

## القرارات المفتوحة (تحتاج إجابة)

| # | القرار | الخيارات | الأثر |
|---|---|---|---|
| Q1 | نوع الـ Transport | WebSocket / SSE / Polling | يحدد Backend requirements |
| Q2 | من يُخزِّن الـ seq؟ | `StorageService` (محلي) / Server only | يحدد recovery عند تغيير الجهاز |
| Q3 | Presence (من متصل؟) | مطلوب / غير مطلوب | يُضيف تعقيداً كبيراً |
| Q4 | هل يعمل الموديول بدون Offline Sync؟ | نعم / لا | يحدد coupling |
| Q5 | ماذا يحدث لجهاز لم يتصل أسبوعاً؟ | يسحب كل الـ events / re-bootstrap كامل | يحدد retention policy للـ events |

---

## الحالة الراهنة

- [ ] تحديد نوع الـ Transport (Q1)
- [ ] تصميم Event Model مع Backend
- [ ] تصميم Device Registry API
- [ ] بناء Transport Layer
- [ ] بناء Catch-up Service
- [ ] بناء Realtime Engine
- [ ] بناء الجسر مع Offline Sync
- [ ] UI indicators
- [ ] SETUP.md

---

*هذه الوثيقة تتطور — كل قرار يُتخذ يُضاف هنا فوراً.*
