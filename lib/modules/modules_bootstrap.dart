import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/access_control/access_control_plugin.dart';
import 'package:app_template/modules/analytics/analytics_plugin.dart';
import 'package:app_template/modules/crash_reporting/crash_reporting_plugin.dart';
import 'package:app_template/modules/data_transfer/data_transfer_plugin.dart';
import 'package:app_template/modules/in_app_updates/in_app_updates_plugin.dart';
import 'package:app_template/modules/multi_device/multi_device_plugin.dart';
import 'package:app_template/modules/notification_center/notification_center_plugin.dart';
import 'package:app_template/modules/push_notifications/push_notifications_plugin.dart';
import 'package:app_template/modules/remote_config/remote_config_plugin.dart';
import 'package:app_template/modules/session_guard/session_guard_plugin.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';
import 'package:app_template/modules/showcase/showcase_plugin.dart';
import 'package:app_template/modules/token_inspector/token_inspector_plugin.dart';

/// Single, ordered activation point for ALL optional modules.
///
/// Started from `main()` right after `configureInjection()`, and awaited by
/// `StartupResolver` before the first frame:
/// ```dart
/// await configureInjection(Env.flavor);
/// ModulesBootstrap.start(getIt);
/// ```
///
/// **The modules' own arguments are set here** (`enabled:`, `defaults:`,
/// `config:`) — each module initialises once, so a second call from anywhere
/// else is ignored.
///
/// To enable/disable a module → flip ONE flag in [AppFeatures]. Disabled
/// modules cost nothing (guarded `if` skips them entirely).
///
/// The startup ORDER is enforced here in code (not in comments):
/// Firebase core → crash reporting → analytics / remote config → push →
/// feature modules (multi-device, sync).
abstract final class ModulesBootstrap {
  static Future<void>? _pending;

  /// **يبدأ الإقلاع ولا ينتظره** — يُنادى من `main()` قبل `runApp`.
  ///
  /// الفصلُ بين البدء والانتظار هو كلُّ الفائدة: هذا العمل **لا يرسم شيئاً**
  /// (يفتح قواعد، ويجدول عمّالاً عبر platform channel)، فانتظارُه بـ`main()`
  /// يجعله يقع **قبل** أن يرى المستخدم شيئاً. وبالفصل يجري خلف شعار النظام
  /// وبالتوازي مع تسخين محرّك فلاتر.
  ///
  /// **ونداؤه مرّتين لا يعيد التهيئة**: نفس المهمّة تُعاد.
  static Future<void> start(GetIt di) => _pending ??= initializeAll(di);

  /// يكتمل حين تنتهي [start] — **ولا يرمي أبداً**.
  ///
  /// موديولٌ يُخفق إقلاعُه يُطفأ ويستمرّ التطبيق (وهذا عقد `AppFeatures` نفسُه:
  /// «أشعله أو دعه»). فلو نفذ الرمي من هنا لأوقف الإقلاعَ أمام شعارٍ لا يمضي —
  /// أي أن إخفاق موديولٍ **اختياريّ** يصير بابَ التطبيق المغلق.
  ///
  /// ويكتمل فوراً إن لم تُنادَ [start] أصلاً.
  static Future<void> get ready =>
      _pending?.catchError((Object e, StackTrace st) {
        LogService.error(
          'Module bootstrap failed — the app continues without those modules.',
          tag: 'BOOTSTRAP',
          error: e,
          stackTrace: st,
        );
      }) ??
      Future<void>.value();

  static Future<void> initializeAll(GetIt di) async {
    // 1. Firebase core — prerequisite for crashlytics / analytics / remote
    //    config / push. Initialised exactly once, and ONLY when at least one
    //    Firebase-backed module is enabled. Requires the native config files
    //    (google-services.json / GoogleService-Info.plist) in the app.
    if (_anyFirebaseModuleEnabled) {
      await Firebase.initializeApp();
    }

    // 2. Crash reporting first, so it captures errors thrown by later steps.
    // `!kDebugMode`: لا رفع ولا بيانات من جلسة تطوير — راجع SETUP كلٍّ منهما.
    if (AppFeatures.crashReporting) {
      await CrashReportingPlugin.initialize(enabled: !kDebugMode);
    }

    // 3. Analytics + remote config.
    if (AppFeatures.analytics) {
      await AnalyticsPlugin.initialize(di, enabled: !kDebugMode);
    }
    if (AppFeatures.remoteConfig) {
      await RemoteConfigPlugin.initialize(di);
    }

    // 4. Push notifications.
    //    For background messages, also register a top-level
    //    @pragma('vm:entry-point') handler via
    //    FirebaseMessaging.onBackgroundMessage(...) in main() — that is
    //    app-specific and cannot live here.
    if (AppFeatures.pushNotifications) {
      await PushNotificationsPlugin.initialize(di);
    }

    // 5. Feature modules.
    //    Access control comes first among them: it restores the cached ability
    //    set before the first frame, and anything registered after it may
    //    legitimately gate on `Can` from its own first build.
    if (AppFeatures.accessControl) {
      await AccessControlPlugin.initialize(di);
    }
    if (AppFeatures.multiDevice) {
      await MultiDevicePlugin.initialize(di);
    }
    if (AppFeatures.sessionGuard) {
      await SessionGuardPlugin.initialize(di);
    }
    // بعد الرقم ٤ — يستهلك بثّ `PushNotificationsService` إن كان مسجَّلاً،
    // ولا ينادي FCM بذاته أبداً.
    if (AppFeatures.notificationCenter) {
      await NotificationCenterPlugin.initialize(di);
    }
    // **يسجّل إعداداتَه المملوكة للخادم مهمّةَ تحديثٍ بالدورة — قبل بناء
    // المحرّك.** ولا نداءَ شبكةٍ هنا: اللافتةُ تُركَّب لاحقاً بـ`AppUpdateGate`
    // حيث يوجد `BuildContext`.
    if (AppFeatures.inAppUpdates) {
      await InAppUpdatesPlugin.initialize(di);
    }
    if (AppFeatures.offlineSync) {
      await SyncSDK.initialize(const SyncSdkConfig(enabled: true), di);
      // **رفعٌ والتطبيقُ مغلق** — أندرويد وحده بقرار، ولا شيء على iOS.
      //
      // والسيناريو الذي وُجد له: يكتب المستخدم عملَه حيث لا تغطية، **ويُغلق
      // التطبيق**. تمرّ التغطيةُ بالطريق — ولا شيء يرفع؛ فيصل وشغلُه ما زال
      // على جهازه وهو يظنّه وصل. راجع `SyncBackgroundWorker`.
      await SyncBackgroundWorker.initialize();
    }
    // Last, and order-independent: it registers a repository and two cubit
    // factories over the already-configured Dio, and nothing else waits on it.
    if (AppFeatures.dataTransfer) {
      await DataTransferPlugin.initialize(di);
    }
    if (AppFeatures.showcase) {
      await ShowcasePlugin.initialize(di);
    }
    // أداةُ مطوّر — لا يعتمد عليها شيء. وتعود من سطرها الأول بنسخة `prod`
    // release حتى لو بقي العلَم مُشعَلاً (`TokenInspector.enabled`).
    if (AppFeatures.tokenInspector) {
      await TokenInspectorPlugin.initialize(di);
    }
    // scaffold_module: موديولٌ جديد فوق هذا السطر
  }

  /// True when any module that depends on Firebase is enabled.
  static bool get _anyFirebaseModuleEnabled =>
      AppFeatures.crashReporting ||
      AppFeatures.analytics ||
      AppFeatures.remoteConfig ||
      AppFeatures.pushNotifications;
}
