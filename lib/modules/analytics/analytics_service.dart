/// Contract for the analytics module.
///
/// Features call this interface — never Firebase directly.
/// Default implementation: [FirebaseAnalyticsAdapter].
/// Can be swapped for Mixpanel, Amplitude, or a no-op in tests.
///
/// Usage:
/// ```dart
/// final _analytics = getIt<AnalyticsService>();
///
/// _analytics.track('login_success', {'method': 'email'});
/// _analytics.setUserId(user.id);
/// _analytics.setUserProperty('plan', 'premium');
/// ```
abstract interface class AnalyticsService {
  /// Logs a named event with optional parameters.
  ///
  /// [name] must be ≤ 40 characters, start with a letter, contain only
  /// letters, numbers and underscores (Firebase requirement).
  Future<void> track(String name, [Map<String, Object>? params]);

  /// Associates all future events with [userId].
  /// Pass `null` to clear (e.g. on logout).
  Future<void> setUserId(String? userId);

  /// Sets a user-scoped property (e.g. `'plan'`, `'locale'`).
  /// Pass `null` as [value] to clear.
  Future<void> setUserProperty(String name, String? value);

  /// Logs the current screen name (used for funnel analysis).
  Future<void> logScreen(String screenName);

  /// Enables or disables analytics collection at runtime.
  /// Useful for GDPR consent flows.
  Future<void> setEnabled(bool enabled);
}
