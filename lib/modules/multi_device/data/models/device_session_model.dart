import 'package:app_template/modules/multi_device/domain/device_session.dart';

/// Wire shape of `GET /api/v1/auth/sessions`.
class DeviceSessionModel {
  const DeviceSessionModel({
    required this.id,
    required this.provider,
    required this.createdAt,
    required this.lastActiveAt,
    required this.expiresAt,
    required this.isCurrent,
    this.deviceInfo,
  });

  final int id;
  final String? deviceInfo;
  final String provider;
  final String createdAt;
  final String lastActiveAt;
  final String expiresAt;
  final bool isCurrent;

  factory DeviceSessionModel.fromJson(Map<String, dynamic> json) =>
      DeviceSessionModel(
        id: json['id'] as int? ?? 0,
        deviceInfo: json['device_info'] as String?,
        provider: json['provider'] as String? ?? 'local',
        createdAt: json['created_at'] as String? ?? '',
        lastActiveAt: json['last_active_at'] as String? ?? '',
        expiresAt: json['expires_at'] as String? ?? '',
        isCurrent: json['is_current'] == true,
      );

  DeviceSession toDomain() => DeviceSession(
        id: id,
        deviceInfo: deviceInfo,
        provider: provider,
        // `DateTime(2000)` on an unparseable value rather than throwing: one
        // malformed timestamp must not blank the whole devices list, which is
        // the screen someone opens *because* something is wrong. An obviously
        // stale date is visible; an empty screen is not explicable.
        createdAt: DateTime.tryParse(createdAt) ?? DateTime(2000),
        lastActiveAt: DateTime.tryParse(lastActiveAt) ?? DateTime(2000),
        expiresAt: DateTime.tryParse(expiresAt) ?? DateTime(2000),
        isCurrent: isCurrent,
      );
}
