import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';
import 'package:app_template/modules/push_notifications/adapters/fcm_push_notifications_adapter.dart';
import 'package:app_template/modules/push_notifications/push_notifications_config.dart';
import 'package:app_template/modules/push_notifications/push_notifications_service.dart';
import 'package:get_it/get_it.dart';

/// Entry point for the push-notifications module.
///
/// ## Setup
///
/// ### 1. Firebase project
/// Run `flutterfire configure` and add `google-services.json` (Android) /
/// `GoogleService-Info.plist` (iOS) as described in FlutterFire docs.
///
/// ### 2. Background handler (required for FCM background messages)
/// Declare a top-level function annotated with `@pragma('vm:entry-point')`
/// and pass it before calling [initialize]:
///
/// ```dart
/// @pragma('vm:entry-point')
/// Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
///   // Must be a top-level function. Keep it lightweight.
///   await Firebase.initializeApp();
/// }
///
/// // Inside `_bootstrap()` in main.dart, before runApp:
/// FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
/// ```
///
/// The module itself is started by `ModulesBootstrap` when
/// `AppFeatures.pushNotifications` is on — its `config:` is set there, since
/// it initialises once and a second call is ignored. See `SETUP.md`.
///
/// ### 3. Usage in a Feature
/// ```dart
/// class NotificationCubit extends SafeCubit<NotificationState> {
///   NotificationCubit(this._push) : super(...) {
///     _push.foregroundStream.listen(_onMessage);
///     _push.tapStream.listen(_onTap);     // deep-link routing
///   }
///   final PushNotificationsService _push;
/// }
/// ```
abstract final class PushNotificationsPlugin {
  static bool _initialized = false;

  /// Initialises Firebase Messaging and registers [PushNotificationsService]
  /// in [di].
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  /// Must be called **after** `Firebase.initializeApp()` and
  /// **after** `configureInjection()`.
  static Future<void> initialize(
    GetIt di, {
    PushNotificationsConfig config = const PushNotificationsConfig(),
  }) async {
    if (_initialized) return;

    // On iOS/macOS: show alerts in foreground (default is silent)
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    final adapter = FcmPushNotificationsAdapter(
      secureStorage: di<SecureStorageService>(),
      config: config,
    );

    await adapter.init();

    di.registerSingleton<PushNotificationsService>(adapter);

    _initialized = true;
    LogService.info('PushNotificationsPlugin initialized', tag: 'PUSH');
  }

  /// Removes the [PushNotificationsService] registration and resets state.
  /// Call on logout if the token must be revoked.
  static Future<void> shutdown(GetIt di) async {
    if (!_initialized) return;
    if (di.isRegistered<PushNotificationsService>()) {
      await di<PushNotificationsService>().deleteToken();
      await di.unregister<PushNotificationsService>();
    }
    _initialized = false;
  }
}

/// الاسم السابق — يبقى ليُصرَّف `modules_bootstrap.dart` بمشروعٍ قائم حتى يُحدَّث.
@Deprecated('Use PushNotificationsPlugin')
typedef PushNotificationsModule = PushNotificationsPlugin;
