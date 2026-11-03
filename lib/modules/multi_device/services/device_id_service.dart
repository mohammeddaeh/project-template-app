import 'dart:io';

import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Manages the device-specific identity and session state stored locally.
///
/// - [deviceId]        : stable UUID, generated once, survives re-login — sent
///   as `X-Device-ID` by `MultiDeviceInterceptor`
/// - [deviceSessionId] : the server's id for this device's session, once
///   [saveSession] is called — `DeviceNotificationHandler` compares against it
/// - [platform]        : "ios" | "android"
///
/// The human-readable device label is `DeviceLabelService` in core, sent on
/// every request whether or not this module is on.
class DeviceIdService {
  DeviceIdService(this._storage, this._uuid);

  final StorageService _storage;
  final Uuid _uuid;

  // ── In-memory cache ───────────────────────────────────────────────────────
  String? _deviceId;
  String? _deviceSessionId;

  static const String _tag = 'MULTI_DEVICE';

  // ── Public getters ────────────────────────────────────────────────────────

  /// Returns the cached device ID. Call [init] before using.
  String get deviceId => _deviceId ?? '';

  /// Returns the current device session ID, or empty string if not logged in.
  String get deviceSessionId => _deviceSessionId ?? '';

  /// "ios" | "android"
  String get platform => Platform.isIOS ? 'ios' : 'android';

  // ── Initialization ────────────────────────────────────────────────────────

  /// Loads or generates the device ID and restores session state.
  /// Must be called once during [MultiDevicePlugin.initialize].
  Future<void> init() async {
    await _ensureDeviceId();
    await _restoreSessionState();
    LogService.debug(
      'DeviceIdService ready | id=${_deviceId!.substring(0, 8)}... '
      'platform=$platform',
      tag: _tag,
    );
  }

  // ── Session lifecycle ─────────────────────────────────────────────────────

  /// Persists the session id the login response carries — **nothing calls
  /// this in the template** (see SETUP.md «ما ليس موصولاً»).
  Future<void> saveSession({required String deviceSessionId}) async {
    _deviceSessionId = deviceSessionId;
    await _storage.writeString(
      PersistenceKeys.deviceSessionId,
      deviceSessionId,
    );
  }

  /// Clears session state (called on logout or revocation).
  Future<void> clearSession() async {
    _deviceSessionId = null;
    await _storage.delete(PersistenceKeys.deviceSessionId);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _ensureDeviceId() async {
    final stored = await _storage.readString(PersistenceKeys.deviceId);
    if (stored != null && stored.isNotEmpty) {
      _deviceId = stored;
      return;
    }
    _deviceId = _uuid.v4();
    await _storage.writeString(PersistenceKeys.deviceId, _deviceId!);
    LogService.debug('Generated new device_id: $_deviceId', tag: _tag);
  }

  Future<void> _restoreSessionState() async {
    _deviceSessionId = await _storage.readString(
      PersistenceKeys.deviceSessionId,
    );
  }
}
