import 'notification_channel.dart';
import 'notification_payload.dart';
import 'notification_tap_event.dart';

/// Abstract contract for local notification management.
///
/// ─── Adapters (implementations) ──────────────────────────────────────────
/// • [adapters/fln_notifications_adapter.dart]  flutter_local_notifications
/// • Add a new adapter to swap libraries — no other code changes required.
///
/// ─── Setup (main.dart) ───────────────────────────────────────────────────
/// ```dart
/// await getIt<LocalNotificationsService>().initialize();
/// ```
///
/// ─── Tap handling (app.dart) ─────────────────────────────────────────────
/// ```dart
/// getIt<LocalNotificationsService>().onTap.listen((event) {
///   final data = jsonDecode(event.data ?? '{}');
///   router.navigate(data['route']);
/// });
/// ```
///
/// ─── Usage in any feature ────────────────────────────────────────────────
/// ```dart
/// await _notifications.show(NotificationPayload(
///   id: 1, title: 'Reminder', body: 'Your appointment is in 1 hour.',
/// ));
/// ```
abstract interface class LocalNotificationsService {
  /// Initialises the notification plugin and registers [channels] on Android.
  ///
  /// Call once from main() before runApp. Safe to call multiple times.
  Future<void> initialize({
    List<NotificationChannel> channels = const [NotificationChannel.defaultChannel],
  });

  /// Stream of tap events — subscribe once in app.dart.
  Stream<NotificationTapEvent> get onTap;

  /// Shows an immediate notification.
  Future<void> show(NotificationPayload payload);

  /// Schedules a notification to fire at [scheduledAt].
  Future<void> schedule(NotificationPayload payload, DateTime scheduledAt);

  /// Cancels a single notification by [id].
  Future<void> cancel(int id);

  /// Cancels all pending and displayed notifications.
  Future<void> cancelAll();

  /// Returns all currently scheduled (pending) notifications.
  Future<List<NotificationPayload>> getPending();
}
