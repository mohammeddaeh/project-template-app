part of 'notification_center_cubit.dart';

/// Hand-written rather than `@freezed` — same documented exception as
/// `ActiveDevicesState` in `modules/multi_device/`: this module ships
/// disabled by default, and `@freezed` would force a `build_runner` step on
/// a project that never turns it on.
sealed class NotificationCenterState {
  const NotificationCenterState();
}

class NotificationCenterLoading extends NotificationCenterState {
  const NotificationCenterLoading();
}

class NotificationCenterLoaded extends NotificationCenterState {
  const NotificationCenterLoaded({required this.items});

  final List<NotificationCenterItem> items;

  int get unreadCount => items.where((i) => !i.read).length;
}
