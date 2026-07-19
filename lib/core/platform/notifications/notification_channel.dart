import 'notification_importance.dart';

/// Android notification channel configuration.
///
/// Define your channels once and pass them to [LocalNotificationsService.initialize].
/// iOS ignores channels — importance maps to presentation options instead.
///
/// Example:
/// ```dart
/// const defaultChannel = NotificationChannel(
///   id: 'default',
///   name: 'General',
///   importance: NotificationImportance.normal,
/// );
/// ```
class NotificationChannel {
  const NotificationChannel({
    required this.id,
    required this.name,
    this.description,
    this.importance = NotificationImportance.normal,
  });

  final String id;
  final String name;
  final String? description;
  final NotificationImportance importance;

  /// The default channel used when no channelId is specified in a payload.
  static const defaultChannel = NotificationChannel(
    id: 'default',
    name: 'Notifications',
    importance: NotificationImportance.normal,
  );
}
