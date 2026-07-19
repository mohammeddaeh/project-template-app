import 'package:app_template/modules/multi_device/domain/device_session.dart';

class DeviceSessionModel {
  const DeviceSessionModel({
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
  final bool isCurrent;
  final bool isPrimary;
  final String? appVersion;

  factory DeviceSessionModel.fromJson(Map<String, dynamic> json) {
    return DeviceSessionModel(
      deviceSessionId: json['device_session_id'] as String,
      deviceName:      json['device_name'] as String,
      platform:        json['platform'] as String,
      lastActiveAt:    DateTime.parse(json['last_active_at'] as String),
      createdAt:       DateTime.parse(json['created_at'] as String),
      isCurrent:       json['is_current'] as bool? ?? false,
      isPrimary:       json['is_primary'] as bool? ?? false,
      appVersion:      json['app_version'] as String?,
    );
  }

  DeviceSession toDomain() => DeviceSession(
        deviceSessionId: deviceSessionId,
        deviceName:      deviceName,
        platform:        platform,
        lastActiveAt:    lastActiveAt,
        createdAt:       createdAt,
        isCurrent:       isCurrent,
        isPrimary:       isPrimary,
        appVersion:      appVersion,
      );
}
