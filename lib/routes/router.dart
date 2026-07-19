import 'package:auto_route/auto_route.dart';
import 'package:app_template/routes/router.gr.dart';

CustomRoute customRouteWithAnimation({required PageInfo page}) {
  return CustomRoute(
    page: page,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: true,
        child: child,
      );
    },
  );
}

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
    // ── Splash ─────────────────────────────────────────────────────────────
    AutoRoute(page: SplashRoute.page, path: '/splash', initial: true),

    // ── Home ───────────────────────────────────────────────────────────────
    AutoRoute(page: HomeRoute.page, path: '/home'),

    // ── Utility ────────────────────────────────────────────────────────────
    // ── Widget Library (demo) ──────────────────────────────────────────────────
    AutoRoute(page: WidgetLibraryDemoRoute.page, path: '/widgets-demo'),

    // ── Test / Template Showcase (debug — AppFeatures.debugSkipLogin) ─────────
    AutoRoute(page: TestDashboardRoute.page, path: '/test'),
    AutoRoute(page: TestFormsDemoRoute.page, path: '/test/forms'),
    AutoRoute(page: TestStatesDemoRoute.page, path: '/test/states'),
    AutoRoute(page: TestThemeDemoRoute.page, path: '/test/theme'),
    AutoRoute(page: TestSettingsDemoRoute.page, path: '/test/settings'),
    AutoRoute(
      page: TestFormValidationRoute.page,
      path: '/test/form-validation',
    ),
    AutoRoute(page: TestPaginationDemoRoute.page, path: '/test/pagination'),
    AutoRoute(page: TestCrudDemoRoute.page, path: '/test/crud'),
    AutoRoute(
      page: TestPredictiveBackDemoRoute.page,
      path: '/test/predictive-back',
    ),
    AutoRoute(page: TestHapticsDemoRoute.page, path: '/test/haptics'),
    AutoRoute(page: TestFeatureWizardRoute.page, path: '/test/feature-wizard'),
    AutoRoute(page: TestNavStackRoute.page, path: '/test/nav-stack'),
    AutoRoute(
      page: TestPlatformServicesRoute.page,
      path: '/test/platform-services',
    ),
    AutoRoute(page: TestFailureDemoRoute.page, path: '/test/failures'),
    AutoRoute(page: TestConnectivityRoute.page, path: '/test/connectivity'),
    AutoRoute(page: TestSyncQueueRoute.page, path: '/test/sync-queue'),
    AutoRoute(page: TestBlocStatesRoute.page, path: '/test/bloc-states'),
    AutoRoute(page: TestApiSimulatorRoute.page, path: '/test/api-simulator'),

    AutoRoute(page: ErrorRoute.page, path: '/error'),
  ];
}
