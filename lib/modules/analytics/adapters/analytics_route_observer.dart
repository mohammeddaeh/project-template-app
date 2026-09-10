import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:app_template/modules/analytics/analytics_service.dart';

/// Logs a `screen_view` for every route AutoRoute pushes, pops or switches
/// to — including bottom-tab switches, which plain [Route] push/pop never
/// sees.
///
/// Reads `getIt` directly rather than taking [AnalyticsService] by
/// constructor: it is built once in `app.dart` before [AnalyticsModule] has
/// necessarily registered the service (the module starts async, unawaited,
/// from `main()` — see `ModulesBootstrap`), and it must stay a harmless
/// no-op for the entire lifetime of a build with `AppFeatures.analytics`
/// off.
class AnalyticsRouteObserver extends AutoRouterObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log(route.settings.name);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log(previousRoute?.settings.name);

  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) =>
      _log(route.name);

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) =>
      _log(route.name);

  void _log(String? screenName) {
    if (screenName == null || screenName.isEmpty) return;
    if (!GetIt.instance.isRegistered<AnalyticsService>()) return;
    GetIt.instance<AnalyticsService>().logScreen(screenName);
  }
}
