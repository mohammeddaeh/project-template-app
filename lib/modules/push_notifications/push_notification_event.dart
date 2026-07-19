/// A normalised push notification event delivered to the app.
///
/// Produced by [PushNotificationsService] from FCM [RemoteMessage]s.
/// Contains only the data the app needs — no platform-specific types.
final class PushNotificationEvent {
  const PushNotificationEvent({
    required this.id,
    this.title,
    this.body,
    this.imageUrl,
    this.data = const {},
  });

  /// Unique message ID from FCM.
  final String id;

  final String? title;
  final String? body;
  final String? imageUrl;

  /// Arbitrary key-value payload sent from the server (e.g. `{'type': 'chat'}`).
  final Map<String, dynamic> data;

  @override
  String toString() =>
      'PushNotificationEvent(id: $id, title: $title, data: $data)';
}
