import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:app_template/core/platform/notifications/local_notifications_service.dart';
import 'package:app_template/core/platform/notifications/notification_channel.dart';
import 'package:app_template/core/platform/notifications/notification_importance.dart';
import 'package:app_template/core/platform/notifications/notification_payload.dart';
import 'package:app_template/core/platform/notifications/notification_tap_event.dart';

/// [LocalNotificationsService] adapter backed by flutter_local_notifications.
///
/// To swap libraries: create a new adapter implementing
/// [LocalNotificationsService] and update injection_module.dart.
/// No other code in the project needs to change.
class FlnNotificationsAdapter implements LocalNotificationsService {
  FlnNotificationsAdapter();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _tapController = StreamController<NotificationTapEvent>.broadcast();

  @override
  Stream<NotificationTapEvent> get onTap => _tapController.stream;

  // ── Initialization ───────────────────────────────────────────────────────

  @override
  Future<void> initialize({
    List<NotificationChannel> channels = const [NotificationChannel.defaultChannel],
  }) async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    // Create Android channels
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    for (final ch in channels) {
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          ch.id,
          ch.name,
          description: ch.description,
          importance: _toAndroidImportance(ch.importance),
        ),
      );
    }
  }

  // ── Show ─────────────────────────────────────────────────────────────────

  @override
  Future<void> show(NotificationPayload payload) async {
    await _plugin.show(
      id: payload.id,
      title: payload.title,
      body: payload.body,
      notificationDetails: _buildDetails(payload),
      payload: payload.data,
    );
  }

  // ── Schedule ─────────────────────────────────────────────────────────────

  @override
  Future<void> schedule(
    NotificationPayload payload,
    DateTime scheduledAt,
  ) async {
    await _plugin.zonedSchedule(
      id: payload.id,
      title: payload.title,
      body: payload.body,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: _buildDetails(payload),
      payload: payload.data,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ── Cancel ───────────────────────────────────────────────────────────────

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Pending ──────────────────────────────────────────────────────────────

  @override
  Future<List<NotificationPayload>> getPending() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending
        .map(
          (n) => NotificationPayload(
            id: n.id,
            title: n.title ?? '',
            body: n.body ?? '',
            data: n.payload,
          ),
        )
        .toList(growable: false);
  }

  // ── Tap handlers ─────────────────────────────────────────────────────────

  void _onTap(NotificationResponse response) {
    _tapController.add(
      NotificationTapEvent(
        notificationId: response.id ?? 0,
        data: response.payload,
      ),
    );
  }

  // Top-level function required by flutter_local_notifications for background taps
  static void _onBackgroundTap(NotificationResponse response) {
    // Background taps are handled when the app resumes via onTap stream.
  }

  // ── Mapping helpers ──────────────────────────────────────────────────────

  NotificationDetails _buildDetails(NotificationPayload payload) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        payload.channelId,
        payload.channelId,
        importance: _toAndroidImportance(payload.importance),
        priority: _toAndroidPriority(payload.importance),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: payload.importance != NotificationImportance.low,
      ),
    );
  }

  Importance _toAndroidImportance(NotificationImportance i) => switch (i) {
        NotificationImportance.low    => Importance.low,
        NotificationImportance.normal => Importance.defaultImportance,
        NotificationImportance.high   => Importance.high,
        NotificationImportance.max    => Importance.max,
      };

  Priority _toAndroidPriority(NotificationImportance i) => switch (i) {
        NotificationImportance.low    => Priority.low,
        NotificationImportance.normal => Priority.defaultPriority,
        NotificationImportance.high   => Priority.high,
        NotificationImportance.max    => Priority.max,
      };
}
