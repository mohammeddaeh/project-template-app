import 'package:shared_preferences/shared_preferences.dart';

import 'sync_mode.dart';
import 'sync_settings.dart';

abstract class SyncSettingsStore {
  Future<SyncSettings> getSettings();
  Future<void> setMode(SyncMode mode);
  Future<void> setSyncEnabled(bool value);
  Future<void> setWifiOnly(bool value);
  Future<void> setPeriodicIntervalSeconds(int? value);

  /// «نزّل الصور والملفّات على Wi‑Fi وحده» — راجع [SyncSettings.mediaWifiOnly].
  Future<void> setMediaWifiOnly(bool value);

  /// إذنُ التنزيل على بيانات الجوّال — راجع
  /// [SyncSettings.mediaOverMobileApproved].
  Future<void> setMediaOverMobileApproved(bool value);
}

class SharedPrefsSyncSettingsStore implements SyncSettingsStore {
  SharedPrefsSyncSettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _modeKey = 'sync_mode';
  static const _enabledKey = 'sync_enabled';
  static const _wifiOnlyKey = 'sync_wifi_only';
  static const _periodicIntervalKey = 'sync_periodic_interval_seconds';
  static const _mediaWifiOnlyKey = 'sync_media_wifi_only';
  static const _mediaOverMobileKey = 'sync_media_over_mobile_approved';

  @override
  Future<SyncSettings> getSettings() async {
    return SyncSettings(
      mode: SyncMode.fromRaw(_prefs.getString(_modeKey)),
      syncEnabled: _prefs.getBool(_enabledKey) ?? true,
      wifiOnly: _prefs.getBool(_wifiOnlyKey) ?? false,
      periodicIntervalSeconds: _prefs.getInt(_periodicIntervalKey),
      // **مُشعَلٌ افتراضياً** — راجع [SyncSettings.mediaWifiOnly] لسبب أن
      // الافتراضين معكوسان بين الرفع والتنزيل.
      mediaWifiOnly: _prefs.getBool(_mediaWifiOnlyKey) ?? true,
      mediaOverMobileApproved: _prefs.getBool(_mediaOverMobileKey) ?? false,
    );
  }

  @override
  Future<void> setMode(SyncMode mode) async {
    await _prefs.setString(_modeKey, mode.raw);
  }

  @override
  Future<void> setSyncEnabled(bool value) async {
    await _prefs.setBool(_enabledKey, value);
  }

  @override
  Future<void> setWifiOnly(bool value) async {
    await _prefs.setBool(_wifiOnlyKey, value);
  }

  @override
  Future<void> setPeriodicIntervalSeconds(int? value) async {
    if (value == null) {
      await _prefs.remove(_periodicIntervalKey);
      return;
    }
    await _prefs.setInt(_periodicIntervalKey, value);
  }

  @override
  Future<void> setMediaWifiOnly(bool value) async {
    await _prefs.setBool(_mediaWifiOnlyKey, value);
  }

  @override
  Future<void> setMediaOverMobileApproved(bool value) async {
    await _prefs.setBool(_mediaOverMobileKey, value);
  }
}
