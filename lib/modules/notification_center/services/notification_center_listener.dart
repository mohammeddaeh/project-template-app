import 'dart:async';

import 'package:app_template/core/platform/logging/log_service.dart';
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
    _subscription = _push.foregroundStream.listen(_onEvent, onError: _onError);
  }

  void _onEvent(PushNotificationEvent event) {
    // غير مُنتظَرة بقصد — هذا مستدعًى تزامنياً من `listen()`. وبلا `catchError`
    // هنا كان فشل الكتابة (`_store._persist`) يسقط كخطأ Future غير ملتقَط.
    unawaited(
      _store
          .add(
            NotificationCenterItem(
              id: event.id,
              title: event.title,
              body: event.body,
              data: event.data,
              receivedAt: DateTime.now(),
            ),
          )
          .catchError((Object error, StackTrace stackTrace) {
        LogService.error(
          'NotificationCenterListener persist error',
          tag: 'NOTIFICATION_CENTER',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  /// بلا هذا كان خطأ الستريم يسقط كخطأ Future غير ملتقَط — لا يظهر بالواجهة
  /// (لا شاشة تنتظر حدثاً هنا أصلاً)، لكنه كان يضيع بصمت بدل أن يُسجَّل.
  void _onError(Object error, StackTrace stackTrace) {
    LogService.error(
      'NotificationCenterListener stream error',
      tag: 'NOTIFICATION_CENTER',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
