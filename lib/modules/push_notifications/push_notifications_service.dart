import 'push_notification_event.dart';

/// Contract for the push-notifications module.
///
/// Features interact only with this interface — never with FCM directly.
/// The concrete implementation is [FcmPushNotificationsAdapter].
///
/// Usage (in a Cubit or UseCase):
/// ```dart
/// class NotificationCubit extends Cubit<...> {
///   NotificationCubit(this._push) : super(...) {
///     _push.foregroundStream.listen(_onMessage);
///     _push.tapStream.listen(_onTap);
///   }
///
///   final PushNotificationsService _push;
/// }
/// ```
abstract interface class PushNotificationsService {
  /// Stream of messages received **while the app is in the foreground**.
  Stream<PushNotificationEvent> get foregroundStream;

  /// Stream of [PushNotificationEvent]s the user **tapped** to open the app.
  /// Includes the initial notification if the app was launched from a tap.
  Stream<PushNotificationEvent> get tapStream;

  /// The current FCM device token, or `null` if not yet available.
  Future<String?> getToken();

  /// Deletes the current FCM token (e.g. on logout).
  Future<void> deleteToken();

  /// Subscribes to a FCM topic (e.g. `'announcements'`).
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribes from a FCM topic.
  Future<void> unsubscribeFromTopic(String topic);
}
