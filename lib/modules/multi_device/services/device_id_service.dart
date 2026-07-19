import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Manages the device-specific identity and session state stored locally.
///
/// - [deviceId]        : stable UUID, generated once, survives re-login
/// - [deviceSessionId] : updated after every successful login
/// - [isPrimary]       : true if this device was the first to log in to the account
/// - [deviceName]      : human-readable name from DeviceInfoPlugin
/// - [platform]        : "ios" | "android"
class DeviceIdService {
  DeviceIdService(this._storage, this._uuid);

  final StorageService _storage;
  final Uuid _uuid;

  // ── In-memory cache ───────────────────────────────────────────────────────
  String? _deviceId;
  String? _deviceSessionId;
  bool _isPrimary = false;
  String? _deviceName;

  static const String _tag = 'MULTI_DEVICE';

  // ── Public getters ────────────────────────────────────────────────────────

  /// Returns the cached device ID. Call [init] before using.
  String get deviceId => _deviceId ?? '';

  /// Returns the current device session ID, or empty string if not logged in.
  String get deviceSessionId => _deviceSessionId ?? '';

  /// True if this device is the primary (first-ever login) device.
  bool get isPrimary => _isPrimary;

  /// Human-readable device name, e.g. "iPhone 15 Pro" or "Samsung Galaxy S24".
  String get deviceName => _deviceName ?? platform;

  /// "ios" | "android"
  String get platform => Platform.isIOS ? 'ios' : 'android';

  // ── Initialization ────────────────────────────────────────────────────────

  /// Loads or generates the device ID and restores session state.
  /// Must be called once during [MultiDevicePlugin.initialize].
  Future<void> init() async {
    await _ensureDeviceId();
    await _restoreSessionState();
    _deviceName = await _resolveDeviceName();
    LogService.debug(
      'DeviceIdService ready | id=${_deviceId!.substring(0, 8)}... '
      'name=$_deviceName platform=$platform isPrimary=$_isPrimary',
      tag: _tag,
    );
  }

  // ── Session lifecycle ─────────────────────────────────────────────────────

  /// Persists session info returned by the login response.
  Future<void> saveSession({
    required String deviceSessionId,
    required bool isPrimary,
  }) async {
    _deviceSessionId = deviceSessionId;
    _isPrimary = isPrimary;
    await _storage.writeString(
        PersistenceKeys.deviceSessionId, deviceSessionId);
    await _storage.writeBool(PersistenceKeys.deviceIsPrimary, value: isPrimary);
  }

  /// Clears session state (called on logout or revocation).
  Future<void> clearSession() async {
    _deviceSessionId = null;
    _isPrimary = false;
    await _storage.delete(PersistenceKeys.deviceSessionId);
    await _storage.delete(PersistenceKeys.deviceIsPrimary);
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
    _deviceSessionId =
        await _storage.readString(PersistenceKeys.deviceSessionId);
    _isPrimary =
        await _storage.readBool(PersistenceKeys.deviceIsPrimary) ?? false;
  }

  Future<String> _resolveDeviceName() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return '${info.manufacturer} ${info.model}'.trim();
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return info.name;
      }
    } catch (e) {
      LogService.warning('Could not resolve device name: $e', tag: _tag);
    }
    return platform;
  }
}
