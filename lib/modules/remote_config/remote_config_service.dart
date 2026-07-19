/// Contract for remote configuration values.
///
/// Allows toggling features and changing app behaviour without a new release.
/// Default implementation: [FirebaseRemoteConfigAdapter].
///
/// Usage:
/// ```dart
/// final config = getIt<RemoteConfigService>();
///
/// if (config.getBool('new_payment_flow')) { ... }
/// final minVersion = config.getString('min_app_version');
/// ```
abstract interface class RemoteConfigService {
  /// Fetches fresh values from the server and activates them.
  /// Call on app start (after [RemoteConfigModule.initialize]).
  Future<void> fetchAndActivate();

  /// Returns a `bool` remote config value.
  /// Falls back to [defaultValue] if the key is not set.
  bool getBool(String key, {bool defaultValue = false});

  /// Returns a `String` remote config value.
  String getString(String key, {String defaultValue = ''});

  /// Returns an `int` remote config value.
  int getInt(String key, {int defaultValue = 0});

  /// Returns a `double` remote config value.
  double getDouble(String key, {double defaultValue = 0.0});

  /// Stream that emits whenever remote config values are updated in real-time.
  /// Useful for live feature flags without app restart.
  Stream<void> get onUpdated;
}
