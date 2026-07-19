import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/analytics/adapters/firebase_analytics_adapter.dart';
import 'package:app_template/modules/analytics/analytics_service.dart';
import 'package:get_it/get_it.dart';

/// Entry point for the analytics module.
///
/// ## Setup — see `SETUP.md` in this folder.
///
/// ## Usage
/// ```dart
/// // main.dart — after Firebase.initializeApp()
/// await AnalyticsModule.initialize(getIt);
///
/// // In any Cubit / UseCase:
/// getIt<AnalyticsService>().track('purchase_completed', {
///   'product_id': 'prod_123',
///   'amount': 99,
/// });
///
/// // After login:
/// AnalyticsModule.identify(userId: user.id, plan: user.plan);
///
/// // After logout:
/// await AnalyticsModule.reset(getIt);
/// ```
abstract final class AnalyticsModule {
  static bool _initialized = false;

  /// Registers [AnalyticsService] in [di].
  ///
  /// [enabled] — pass `false` during development to silence Firebase uploads.
  static Future<void> initialize(
    GetIt di, {
    bool enabled = true,
  }) async {
    if (_initialized) return;

    final adapter = FirebaseAnalyticsAdapter();
    await adapter.setEnabled(enabled);

    di.registerSingleton<AnalyticsService>(adapter);

    _initialized = true;
    LogService.info('AnalyticsModule initialized (enabled=$enabled)',
        tag: 'ANALYTICS');
  }

  // ── Convenience helpers ───────────────────────────────────────────────────

  /// Resets user identity and disables collection until re-initialized.
  static Future<void> reset(GetIt di) async {
    if (!_initialized) return;
    if (di.isRegistered<AnalyticsService>()) {
      await di<AnalyticsService>().setUserId(null);
      await di.unregister<AnalyticsService>();
    }
    _initialized = false;
  }
}
