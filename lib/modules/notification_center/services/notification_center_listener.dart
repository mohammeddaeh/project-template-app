import 'dart:async';

import 'package:app_template/modules/notification_center/data/notification_center_store.dart';
import 'package:app_template/modules/notification_center/domain/notification_center_item.dart';
import 'package:app_template/modules/push_notifications/push_notification_event.dart';
import 'package:app_template/modules/push_notifications/push_notifications_service.dart';

/// Bridges [PushNotificationsService] into [NotificationCenterStore] — the
/// only place this module touches the push module. It never calls FCM, and
/// [PushNotificationsService] never knows this module exists.
///
/// Only [PushNotificationsService.foregroundStream] is consumed. A tap that
/// opens the app (`tapStream`) already delivered its notification once while
/// it was still foregrounded in almost every real flow, and a background/
/// terminated tap belongs to deep-link routing, not to this list — recording
/// it here as well would double it.
class NotificationCenterListener {
  NotificationCenterListener(this._store, this._push);

  final NotificationCenterStore _store;
  final PushNotificationsService _push;
  StreamSubscription<PushNotificationEvent>? _subscription;

  /// Idempotent — a second call is a no-op rather than a second subscription.
  void start() {
    if (_subscription != null) return;
    _subscription = _push.foregroundStream.listen(_onEvent);
  }

  void _onEvent(PushNotificationEvent event) {
    _store.add(
      NotificationCenterItem(
        id: event.id,
        title: event.title,
        body: event.body,
        data: event.data,
        receivedAt: DateTime.now(),
      ),
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
