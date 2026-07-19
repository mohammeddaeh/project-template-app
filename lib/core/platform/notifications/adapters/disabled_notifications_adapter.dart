import 'dart:async';

import 'package:app_template/core/platform/notifications/local_notifications_service.dart';
import 'package:app_template/core/platform/notifications/notification_channel.dart';
import 'package:app_template/core/platform/notifications/notification_payload.dart';
import 'package:app_template/core/platform/notifications/notification_tap_event.dart';

/// No-op adapter used when [AppFeatures.localNotifications] == false.
///
/// All calls are silently ignored — no plugin is initialised, no
/// permission is requested, and the app still compiles without any
/// conditional import guards at the call site.
class DisabledNotificationsAdapter implements LocalNotificationsService {
  @override
  Stream<NotificationTapEvent> get onTap => const Stream.empty();

  @override
  Future<void> initialize({
    List<NotificationChannel> channels = const [NotificationChannel.defaultChannel],
  }) async {}

  @override
  Future<void> show(NotificationPayload payload) async {}

  @override
  Future<void> schedule(NotificationPayload payload, DateTime scheduledAt) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<List<NotificationPayload>> getPending() async => const [];
}
