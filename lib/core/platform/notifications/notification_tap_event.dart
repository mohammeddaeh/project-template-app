/// Emitted by [LocalNotificationsService.onTap] when the user taps
/// a notification.
///
/// Listen in app.dart and navigate based on [data]:
/// ```dart
/// getIt<LocalNotificationsService>().onTap.listen((event) {
///   if (event.data == null) return;
///   final map = jsonDecode(event.data!);
///   router.navigate(map['route'], map['id']);
/// });
/// ```
class NotificationTapEvent {
  const NotificationTapEvent({
    required this.notificationId,
    this.data,
  });

  /// The id of the notification that was tapped.
  final int notificationId;

  /// The [NotificationPayload.data] string passed when showing the notification.
  final String? data;
}
