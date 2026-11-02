# Multi-Device Session Module — دليل التفعيل

> الأجهزة والجلسات النشطة للحساب: قائمةٌ بها، وإنهاءُ جلسةٍ واحدة أو كلِّ ما عدا
> الحالية. يقابل `GET /auth/sessions` و`DELETE /auth/sessions/{id}` و
> `POST /auth/sessions/revoke-others` بـ`backend_template`.

## الخطوة ١ — العلَم

```dart
// lib/core/platform/features/app_features.dart
static const multiDevice = true;
```

`ModulesBootstrap` يُقلع `MultiDevicePlugin` حين يُشعَل. ولا خطوة ثانية للتوليد
بعد تعديل الموديول: `dart run scripts/gen_code.dart` (خدمة Retrofit
`DeviceSessionApiService`).

## الخطوة ٢ — الشاشة مركّبةٌ أصلاً

`DevicesSection` بشاشة الإعدادات (`settings_screen.dart`) يفتح `ActiveDevicesScreen`،
ويرسم لا شيء حين يُطفأ العلَم. **ولا مسار في `router.dart`**: الشاشة ليست
`@RoutePage` بقصد، فموديولٌ مطفأ لا يضع مساراً بكل مشروع.

## ما يحدث تلقائياً بعد التفعيل

| الحدث | ما يحدث |
|---|---|
| أي طلب HTTP | رأس `X-Device-ID` — معرّفٌ ثابتٌ للجهاز من `DeviceIdService` |
| `DevicesSection` | قائمةُ الجلسات من الخادم، وإنهاءُ أيٍّ منها |
| جهازٌ آخر يُنهي هذه الجلسة | الطلب التالي يعود `401` ⇐ **انتهاءُ جلسةٍ عاديّ** (`sessionExpired`). رسالةُ «سُجِّل خروجك من جهازٍ آخر» (`sessionRevoked`) تحتاج خادماً يميّز الجلسة المُنهاة، ولا يميّزها `backend_template` |

## ما ليس موصولاً — اقرأ قبل البناء عليه

| السطح | الحالة |
|---|---|
| `DeviceNotificationHandler` (FCM `session_revoked`) | ⬜ **مسجَّلٌ بالـDI ولا يُنادى.** `push_notifications` لا يمرّر له شيئاً، و`DeviceIdService.saveSession` بلا مستدعٍ فـ`deviceSessionId` فارغٌ دائماً — فيتجاهل كلَّ رسالة. لتشغيله: احفظ `device_session_id` بعد الدخول، ومرّر `PushNotificationsService.foregroundStream` إلى `handle` |
| الدخول | لا يُرسل بيانات الجهاز (`device_name` · `platform`) — الرأس وحده |

## الإيقاف

```dart
static const multiDevice = false;
```

لا حاجة لإزالة الكود — `DevicesSection` يرسم لا شيء، ولا شيء يُسجَّل.
