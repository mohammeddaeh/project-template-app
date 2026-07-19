import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/analytics/analytics_module.dart';
import 'package:app_template/modules/crash_reporting/crash_reporting_module.dart';
import 'package:app_template/modules/multi_device/multi_device_plugin.dart';
import 'package:app_template/modules/push_notifications/push_notifications_module.dart';
import 'package:app_template/modules/remote_config/remote_config_module.dart';
import 'package:app_template/modules/sync/sdk/sync_sdk.dart';
import 'package:app_template/modules/sync/sdk/sync_sdk_config.dart';

/// Single, ordered activation point for ALL optional modules.
///
/// Call once from `main()` right after `configureInjection()`:
/// ```dart
/// await configureInjection(Env.currentConfig);
/// await ModulesBootstrap.initializeAll(getIt);
/// ```
///
/// To enable/disable a module → flip ONE flag in [AppFeatures]. Disabled
/// modules cost nothing (guarded `if` skips them entirely).
///
/// The startup ORDER is enforced here in code (not in comments):
/// Firebase core → crash reporting → analytics / remote config → push →
/// feature modules (multi-device, sync).
abstract final class ModulesBootstrap {
  static Future<void> initializeAll(GetIt di) async {
    // 1. Firebase core — prerequisite for crashlytics / analytics / remote
    //    config / push. Initialised exactly once, and ONLY when at least one
    //    Firebase-backed module is enabled. Requires the native config files
    //    (google-services.json / GoogleService-Info.plist) in the app.
    if (_anyFirebaseModuleEnabled) {
      await Firebase.initializeApp();
    }

    // 2. Crash reporting first, so it captures errors thrown by later steps.
    if (AppFeatures.crashReporting) {
      await CrashReportingModule.initialize();
    }

    // 3. Analytics + remote config.
    if (AppFeatures.analytics) {
      await AnalyticsModule.initialize(di);
    }
    if (AppFeatures.remoteConfig) {
      await RemoteConfigModule.initialize(di);
    }

    // 4. Push notifications.
    //    For background messages, also register a top-level
    //    @pragma('vm:entry-point') handler via
    //    FirebaseMessaging.onBackgroundMessage(...) in main() — that is
    //    app-specific and cannot live here.
    if (AppFeatures.pushNotifications) {
      await PushNotificationsModule.initialize(di);
    }

    // 5. Feature modules.
    if (AppFeatures.multiDevice) {
      await MultiDevicePlugin.initialize(di);
    }
    if (AppFeatures.offlineSync) {
      await SyncSDK.initialize(const SyncSdkConfig(enabled: true), di);
    }
  }

  /// True when any module that depends on Firebase is enabled.
  static bool get _anyFirebaseModuleEnabled =>
      AppFeatures.crashReporting ||
      AppFeatures.analytics ||
      AppFeatures.remoteConfig ||
      AppFeatures.pushNotifications;
}
