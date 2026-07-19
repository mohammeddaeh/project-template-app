import 'notification_importance.dart';

/// Data passed when showing or scheduling a notification.
///
/// [data] is an optional JSON string for navigation:
/// ```dart
/// data: jsonEncode({'route': 'orders', 'id': 42})
/// ```
/// The app reads [data] inside the [NotificationTapEvent] listener
/// and navigates accordingly.
class NotificationPayload {
  const NotificationPayload({
    required this.id,
    required this.title,
    required this.body,
    this.data,
    this.channelId = 'default',
    this.importance = NotificationImportance.normal,
  });

  /// Unique notification id — used to cancel or replace later.
  final int id;

  final String title;
  final String body;

  /// Optional JSON string — forwarded as-is inside [NotificationTapEvent].
  final String? data;

  /// Android channel id. Must match a channel passed to [initialize].
  final String channelId;

  final NotificationImportance importance;
}
