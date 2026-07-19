import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:app_template/modules/multi_device/config/multi_device_config.dart';
import 'package:app_template/modules/multi_device/services/device_id_service.dart';

/// Processes silent FCM payloads related to device session events.
///
/// Call [handle] from your FCM `onMessage` / `onBackgroundMessage` handler,
/// passing the notification `data` map.
///
/// Handled types:
/// - [MultiDeviceConfig.fcmTypeSessionRevoked]  → fires [AuthEvent.sessionRevoked]
/// - [MultiDeviceConfig.fcmTypeNewDeviceLogin]  → no automatic action (UI-driven)
/// - [MultiDeviceConfig.fcmTypeDeviceRemoved]   → no automatic action (UI-driven)
class DeviceNotificationHandler {
  DeviceNotificationHandler(this._deviceIdService);

  final DeviceIdService _deviceIdService;

  static const String _tag = 'MULTI_DEVICE';

  /// Entry point — call this when an FCM message arrives.
  ///
  /// ```dart
  /// // In your Firebase messaging handler:
  /// DeviceNotificationHandler handler = getIt<DeviceNotificationHandler>();
  /// handler.handle(message.data);
  /// ```
  void handle(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) return;

    switch (type) {
      case MultiDeviceConfig.fcmTypeSessionRevoked:
        _onSessionRevoked(data);
      case MultiDeviceConfig.fcmTypeNewDeviceLogin:
        _onNewDeviceLogin(data);
      case MultiDeviceConfig.fcmTypeDeviceRemoved:
        _onDeviceRemoved(data);
    }
  }

  void _onSessionRevoked(Map<String, dynamic> data) {
    final targetSessionId = data['device_session_id'] as String?;

    // Only act if the FCM is meant for THIS device's session.
    if (targetSessionId == null ||
        targetSessionId != _deviceIdService.deviceSessionId) {
      LogService.debug(
        'session_revoked FCM ignored — not for this session.',
        tag: _tag,
      );
      return;
    }

    final reason = data['reason'] as String? ?? 'unknown';
    LogService.info(
      'Session revoked via FCM. reason=$reason',
      tag: _tag,
    );

    AuthEventBus.instance.emit(AuthEvent.sessionRevoked);
  }

  void _onNewDeviceLogin(Map<String, dynamic> data) {
    final deviceName = data['device_name'] as String? ?? 'Unknown device';
    LogService.info(
      'New device login detected: $deviceName',
      tag: _tag,
    );
    // Presentation layer listens to a separate stream if it needs to show
    // a "new device logged in" banner — no automatic navigation here.
  }

  void _onDeviceRemoved(Map<String, dynamic> data) {
    final deviceName = data['device_name'] as String? ?? 'Unknown device';
    LogService.info(
      'Device removed from account: $deviceName',
      tag: _tag,
    );
    // UI can refresh the active devices list via ActiveDevicesCubit.
  }
}
