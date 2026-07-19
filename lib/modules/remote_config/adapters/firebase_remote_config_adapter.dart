import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/remote_config/remote_config_service.dart';

/// [RemoteConfigService] backed by Firebase Remote Config.
class FirebaseRemoteConfigAdapter implements RemoteConfigService {
  FirebaseRemoteConfigAdapter({
    required Map<String, dynamic> defaults,
    Duration fetchTimeout = const Duration(minutes: 1),
    Duration minimumFetchInterval = const Duration(hours: 12),
  })  : _defaults = defaults,
        _fetchTimeout = fetchTimeout,
        _minimumFetchInterval = minimumFetchInterval;

  final Map<String, dynamic> _defaults;
  final Duration _fetchTimeout;
  final Duration _minimumFetchInterval;

  final _updatedController = StreamController<void>.broadcast();

  Future<void> init() async {
    final rc = FirebaseRemoteConfig.instance;

    await rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: _fetchTimeout,
      minimumFetchInterval: _minimumFetchInterval,
    ));

    await rc.setDefaults(_defaults);
    await fetchAndActivate();

    // Real-time updates
    rc.onConfigUpdated.listen((_) async {
      await rc.activate();
      _updatedController.add(null);
      LogService.info('RemoteConfig: values updated', tag: 'RCONFIG');
    });
  }

  @override
  Future<void> fetchAndActivate() async {
    try {
      await FirebaseRemoteConfig.instance.fetchAndActivate();
    } catch (e) {
      LogService.warning('RemoteConfig.fetchAndActivate failed: $e',
          tag: 'RCONFIG');
    }
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    try {
      return FirebaseRemoteConfig.instance.getBool(key);
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    try {
      return FirebaseRemoteConfig.instance.getString(key);
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    try {
      return FirebaseRemoteConfig.instance.getInt(key);
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      return FirebaseRemoteConfig.instance.getDouble(key);
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  Stream<void> get onUpdated => _updatedController.stream;
}
