import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/analytics/analytics_service.dart';

/// [AnalyticsService] implementation backed by Firebase Analytics.
class FirebaseAnalyticsAdapter implements AnalyticsService {
  FirebaseAnalyticsAdapter() : _fa = FirebaseAnalytics.instance;

  final FirebaseAnalytics _fa;

  @override
  Future<void> track(String name, [Map<String, Object>? params]) async {
    try {
      await _fa.logEvent(name: name, parameters: params);
    } catch (e) {
      LogService.warning('Analytics.track($name) failed: $e', tag: 'ANALYTICS');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      await _fa.setUserId(id: userId);
    } catch (e) {
      LogService.warning('Analytics.setUserId failed: $e', tag: 'ANALYTICS');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _fa.setUserProperty(name: name, value: value);
    } catch (e) {
      LogService.warning(
          'Analytics.setUserProperty($name) failed: $e', tag: 'ANALYTICS');
    }
  }

  @override
  Future<void> logScreen(String screenName) async {
    try {
      await _fa.logScreenView(screenName: screenName);
    } catch (e) {
      LogService.warning(
          'Analytics.logScreen($screenName) failed: $e', tag: 'ANALYTICS');
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    await _fa.setAnalyticsCollectionEnabled(enabled);
  }
}
