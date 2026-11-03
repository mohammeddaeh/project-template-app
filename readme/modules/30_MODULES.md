# 30 · الموديولات الاختيارية — الجدول الواحد

> كل موديول بـ`lib/modules/<name>/` يُشعَل **بعلَمٍ واحد** بـ
> [`app_features.dart`](../../lib/core/platform/features/app_features.dart)، ويُقلعه
> `ModulesBootstrap` — `start(getIt)` بـ`main.dart`، و`StartupResolver` ينتظر `ready`.
> **لا يُنادى موديولٌ من `main.dart` مباشرةً**، والترتيب مفروضٌ بالكود هناك.
>
> ومدخلُ كل موديول `<name>_plugin.dart` بجذره، وصنفُه `<Name>Plugin`.

## الجدول

| الموديول | العلَم | افتراضاً | يحتاج خارج التطبيق | يُركَّب بالواجهة | الوثيقة |
|---|---|---|---|---|---|
| `data_transfer/` — استيراد · تصدير | `dataTransfer` | ✅ ON | `/data-transfer/*` بالباك | `DataTransferSheet.show(...)` | [`32_MODULE_DATA_TRANSFER.md`](32_MODULE_DATA_TRANSFER.md) |
| `access_control/` — صلاحيات · أدوار | `accessControl` | ⬜ OFF | `/authz/*` + `AUTHZ_ENABLED` بالباك | `Can(permission:)` · `AccessControlSection` | [`31_MODULE_PERMISSIONS.md`](31_MODULE_PERMISSIONS.md) |
| `multi_device/` — الأجهزة والجلسات | `multiDevice` | ⬜ OFF | `/auth/sessions` بالباك | `DevicesSection` بالإعدادات | [`SETUP.md`](../../lib/modules/multi_device/SETUP.md) |
| `sync/` — العمل دون اتصال | `offlineSync` | ⬜ OFF | عقدُ مزامنةٍ لكل كيان + `/attachments` | `SyncUiHost` · `PendingChangesChip` | [`STATUS.md`](../../lib/modules/sync/STATUS.md) **أوّلاً** · [`SETUP.md`](../../lib/modules/sync/SETUP.md) |
| `in_app_updates/` — تحديثٌ إجباري | `inAppUpdates` | ⬜ OFF | `/api/v1/settings` (أو ما يقابله) | `AppUpdateGate` بالقشرة | [`SETUP.md`](../../lib/modules/in_app_updates/SETUP.md) |
| `session_guard/` — قفلٌ برقمٍ أو بصمة | `sessionGuard` | ⬜ OFF | — | `SessionGuardGate` بالقشرة | [`SETUP.md`](../../lib/modules/session_guard/SETUP.md) |
| `push_notifications/` — إشعارات FCM | `pushNotifications` | ⬜ OFF | مشروع Firebase | — | [`SETUP.md`](../../lib/modules/push_notifications/SETUP.md) |
| `notification_center/` — صندوق الإشعارات | `notificationCenter` | ⬜ OFF | `pushNotifications` مُشعَلاً | `NotificationCenterSection` بالإعدادات | [`SETUP.md`](../../lib/modules/notification_center/SETUP.md) |
| `crash_reporting/` — تقارير الانهيار | `crashReporting` | ⬜ OFF | مشروع Firebase | — | [`SETUP.md`](../../lib/modules/crash_reporting/SETUP.md) |
| `analytics/` — التحليلات | `analytics` | ⬜ OFF | مشروع Firebase | `AnalyticsRouteObserver` موصولٌ أصلاً | [`SETUP.md`](../../lib/modules/analytics/SETUP.md) |
| `remote_config/` — إعداداتٌ بعيدة | `remoteConfig` | ⬜ OFF | مشروع Firebase | — | [`SETUP.md`](../../lib/modules/remote_config/SETUP.md) |
| `token_inspector/` — التوكن على الشاشة (أداة مطوّر) | `tokenInspector` | ⬜ OFF | — | زرٌّ عائم بـ`AppOverlays` — **لا يُرى بنسخة `prod` release** | [`33_MODULE_TOKEN_INSPECTOR.md`](33_MODULE_TOKEN_INSPECTOR.md) |
| `showcase/` — جولة المطوّر | `showcase` | ✅ ON | — | `ShowcaseView` بجسد `HomeScreen` — تُطفأ مع رئيسية المشروع | [`SETUP.md`](../../lib/modules/showcase/SETUP.md) |
<!-- scaffold_module: صفٌّ جديد فوق هذا السطر -->

> ⚠️ **علَمٌ مُشعَل لا يكفي.** عمود «يحتاج خارج التطبيق» شرطٌ لا اقتراح، وأخطرُ ما
> فيه أنه يفشل **صامتاً**: `offlineSync = true` بلا محوّل كيانٍ يترك التطبيق يعمل
> على الشبكة بلا انهيارٍ ولا تحذير، وموديولٌ يطلب نقطةً لا يملكها باكُك يعرض «حدث
> خطأ» بلا سببٍ يُرى. وبمشروعٍ يُنقل إلى باكٍ قائم: skill `port-to-template` §«الباك كما هو».

## ملاحظاتٌ بموديولٍ بعينه

**`in_app_updates/`** — حوارُه يحتاج `BuildContext`، فانقسم نصفين: `initialize(di)`
يسجّل اللقطة المحلّية ومهمّةَ تحديثها بدورة المزامنة — وبلا المزامنة يجلبها مرّةً
بالخلفية — و`AppUpdateGate` بالقشرة يقرأ اللقطة ويستمع لتبدّلها.
⚠️ **ونقطتُه `GET /api/v1/settings` ليست عقداً عامّاً**: تردّ قائمةَ `{key, value, isActive}`
ويُقرأ منها `app_version` و`app_download_url` و`force_update` — بدّلها بما يخدمه باكُك،
أو بدّل `AppUpdateSettings.fromEntries`. ⛔ وتبعيّتُه للمزامنة محصورةٌ بملفٍّ واحد
(`integration/app_update_settings_refresh_task.dart`)، لأن `test/sync/deletion_contract_test.dart`
يشهد أن حذفَ المزامنة حذفُ مجلَّد.

**ولا `realtime/` بـ`lib/modules/`** — تصميمه بلا سطر Dart، فوثيقته بـ
[`_template/archive/realtime_design.md`](https://github.com/mohammeddaeh/project-template-app/blob/master/_template/archive/realtime_design.md).
مجلّدٌ فارغ باسم ميزة ادّعاءٌ بوجودها.

## موديولٌ جديد

```bash
dart run scripts/scaffold_module.dart <name>
```

يكتب أركانه الثلاثة معاً — العلَم · سطرُ `ModulesBootstrap` · صفُّه هنا (R29) — ثم
`SETUP.md` بجواره يدوياً. **وكلُّ ودجةٍ عامّة يضيفها الموديول تحتاج مكاناً بالجولة** — صفحةً
بفصل «الموديولات» تحاكيه (R42)، وإلا أفشل `showcase_test` البناء. والحزم التي يجرّها والقرارات المعمارية:
[`10_ARCHITECTURE.md`](../architecture/10_ARCHITECTURE.md).
