import 'package:equatable/equatable.dart';

/// Represents one active session for the current user's account.
class DeviceSession extends Equatable {
  const DeviceSession({
    required this.deviceSessionId,
    required this.deviceName,
    required this.platform,
    required this.lastActiveAt,
    required this.createdAt,
    required this.isCurrent,
    required this.isPrimary,
    this.appVersion,
  });

  final String deviceSessionId;
  final String deviceName;
  final String platform;
  final DateTime lastActiveAt;
  final DateTime createdAt;

  /// True when this session belongs to the device making the request.
  final bool isCurrent;

  /// True for the first device that ever logged in to this account.
  /// Only the primary device can revoke other sessions.
  final bool isPrimary;

  final String? appVersion;

  @override
  List<Object?> get props => [
        deviceSessionId,
        deviceName,
        platform,
        lastActiveAt,
        createdAt,
        isCurrent,
        isPrimary,
        appVersion,
      ];
}
