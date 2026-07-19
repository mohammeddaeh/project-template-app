import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';
import 'package:app_template/modules/push_notifications/push_notification_event.dart';
import 'package:app_template/modules/push_notifications/push_notifications_config.dart';
import 'package:app_template/modules/push_notifications/push_notifications_service.dart';

/// [PushNotificationsService] implementation backed by Firebase Cloud Messaging.
///
/// Initialised exclusively through [PushNotificationsModule.initialize].
/// Do NOT construct directly.
class FcmPushNotificationsAdapter implements PushNotificationsService {
  FcmPushNotificationsAdapter({
    required SecureStorageService secureStorage,
    required PushNotificationsConfig config,
  })  : _secureStorage = secureStorage,
        _config = config;

  final SecureStorageService _secureStorage;
  final PushNotificationsConfig _config;

  final _foregroundController =
      StreamController<PushNotificationEvent>.broadcast();
  final _tapController =
      StreamController<PushNotificationEvent>.broadcast();

  @override
  Stream<PushNotificationEvent> get foregroundStream =>
      _foregroundController.stream;

  @override
  Stream<PushNotificationEvent> get tapStream => _tapController.stream;

  // ── Initialisation (called once by PushNotificationsModule) ─────────────────

  Future<void> init() async {
    if (_config.requestPermissionOnInit) {
      await _requestPermission();
    }

    await _persistAndNotifyToken();

    FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Background / terminated → app opened via tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App launched from a terminated state via notification tap
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleTap(initial);

    LogService.info('PushNotificationsModule ready', tag: 'PUSH');
  }

  // ── PushNotificationsService ─────────────────────────────────────────────────

  @override
  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      LogService.warning('PUSH: getToken failed: $e', tag: 'PUSH');
      return null;
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      await _secureStorage.delete(_config.tokenStorageKey);
      LogService.info('PUSH: token deleted', tag: 'PUSH');
    } catch (e) {
      LogService.warning('PUSH: deleteToken failed: $e', tag: 'PUSH');
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (e) {
      LogService.warning('PUSH: subscribeToTopic($topic) failed: $e',
          tag: 'PUSH');
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (e) {
      LogService.warning('PUSH: unsubscribeFromTopic($topic) failed: $e',
          tag: 'PUSH');
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    LogService.info(
      'PUSH: permission status = ${settings.authorizationStatus}',
      tag: 'PUSH',
    );
  }

  Future<void> _persistAndNotifyToken() async {
    final token = await getToken();
    if (token == null) return;

    await _secureStorage.write(_config.tokenStorageKey, token);
    LogService.info('PUSH: token persisted', tag: 'PUSH');

    await _config.onTokenRefresh?.call(token);
  }

  Future<void> _onTokenRefresh(String token) async {
    await _secureStorage.write(_config.tokenStorageKey, token);
    LogService.info('PUSH: token refreshed', tag: 'PUSH');
    await _config.onTokenRefresh?.call(token);
  }

  void _handleForeground(RemoteMessage message) {
    _foregroundController.add(_toEvent(message));
  }

  void _handleTap(RemoteMessage message) {
    _tapController.add(_toEvent(message));
  }

  static PushNotificationEvent _toEvent(RemoteMessage msg) =>
      PushNotificationEvent(
        id: msg.messageId ?? DateTime.now().toIso8601String(),
        title: msg.notification?.title,
        body: msg.notification?.body,
        imageUrl: msg.notification?.android?.imageUrl ??
            msg.notification?.apple?.imageUrl,
        data: msg.data,
      );
}
