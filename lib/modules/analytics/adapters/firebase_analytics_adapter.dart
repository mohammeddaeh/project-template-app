import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/analytics/analytics_service.dart';
import 'package:app_template/modules/analytics/pii_guard.dart';

/// [AnalyticsService] implementation backed by Firebase Analytics.
class FirebaseAnalyticsAdapter implements AnalyticsService {
  FirebaseAnalyticsAdapter() : _fa = FirebaseAnalytics.instance;

  final FirebaseAnalytics _fa;

  @override
  Future<void> track(String name, [Map<String, Object>? params]) async {
    assert(() {
      assertNoPii('track:$name', name);
      assertNoPii('track:$name', params);
      return true;
    }());
    try {
      await _fa.logEvent(name: name, parameters: params);
    } catch (e) {
      LogService.warning('Analytics.track($name) failed: $e', tag: 'ANALYTICS');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    assert(() {
      assertNoPii('setUserId', userId);
      return true;
    }());
    try {
      await _fa.setUserId(id: userId);
    } catch (e) {
      LogService.warning('Analytics.setUserId failed: $e', tag: 'ANALYTICS');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    assert(() {
      assertNoPii('setUserProperty:$name', name);
      assertNoPii('setUserProperty:$name', value);
      return true;
    }());
    try {
      await _fa.setUserProperty(name: name, value: value);
    } catch (e) {
      LogService.warning(
        'Analytics.setUserProperty($name) failed: $e',
        tag: 'ANALYTICS',
      );
    }
  }

  @override
  Future<void> logScreen(String screenName) async {
    assert(() {
      assertNoPii('logScreen', screenName);
      return true;
    }());
    try {
      await _fa.logScreenView(screenName: screenName);
    } catch (e) {
      LogService.warning(
        'Analytics.logScreen($screenName) failed: $e',
        tag: 'ANALYTICS',
      );
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    await _fa.setAnalyticsCollectionEnabled(enabled);
  }
}
