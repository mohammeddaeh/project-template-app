part of 'active_devices_cubit.dart';

sealed class ActiveDevicesState {
  const ActiveDevicesState();
}

final class ActiveDevicesInitial extends ActiveDevicesState {
  const ActiveDevicesInitial();
}

final class ActiveDevicesLoading extends ActiveDevicesState {
  const ActiveDevicesLoading();
}

final class ActiveDevicesLoaded extends ActiveDevicesState {
  const ActiveDevicesLoaded({
    required this.sessions,
    required this.maxDevices,
    required this.isCurrentDevicePrimary,
  });

  final List<DeviceSession> sessions;
  final int maxDevices;

  /// True when the device running the app is the primary device.
  /// Controls whether revoke buttons are visible.
  final bool isCurrentDevicePrimary;
}

final class ActiveDevicesError extends ActiveDevicesState {
  const ActiveDevicesError({required this.message});
  final String message;
}

final class ActiveDevicesRevoking extends ActiveDevicesState {
  const ActiveDevicesRevoking({required this.deviceSessionId});
  final String deviceSessionId;
}
