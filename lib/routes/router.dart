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

    // ── Auth ───────────────────────────────────────────────────────────────
    // `LoginRoute` is what the whole app falls back to: `app.dart` listens to
    // AuthEventBus and does `replaceAll([LoginRoute()])` when a session
    // expires, so this entry is load-bearing far beyond the login screen.
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(page: RegisterRoute.page, path: '/register'),
    AutoRoute(page: ForgotPasswordRoute.page, path: '/forgot-password'),
    AutoRoute(page: ResetPasswordRoute.page, path: '/reset-password'),
    AutoRoute(page: ChangePasswordRoute.page, path: '/change-password'),
    // Literal path, not '/verify-email/:email': the screen takes the address as
    // a constructor argument for display only, and a path parameter would
    // advertise a deep link that cannot be honoured — the server identifies the
    // account from the session, never from the URL.
    AutoRoute(page: VerifyEmailRoute.page, path: '/verify-email'),

    // ── Signed in ──────────────────────────────────────────────────────────
    // `MainShellRoute` is where every authenticated path lands: splash with a
    // restored token, and login on success. It was NOT registered here until
    // 2026-08-11 while `login_screen.dart` already navigated to it — a
    // `@RoutePage()` widget gets a generated `PageRouteInfo` class whether or
    // not it appears in this list, so the call compiled cleanly and threw at
    // runtime. `dart analyze` cannot see this; `test/router_contract_test.dart`
    // can, and does.
    AutoRoute(page: MainShellRoute.page, path: '/app'),

    // The Home tab on its own, outside the shell — kept for deep links that
    // should not restore the tab bar. Ordinary navigation goes to the shell.
    AutoRoute(page: HomeRoute.page, path: '/home'),

    // ── Reference feature — delete with `Features/notes/` ───────────────────
    AutoRoute(page: NotesRoute.page, path: '/notes'),
    AutoRoute(page: NoteFormRoute.page, path: '/notes/form'),

    // ── Import / export (modules/data_transfer) ────────────────────────────
    //
    // Generic: `:resource` is a wire name, so these two routes serve every
    // transferable feature the backend declares. They stay registered even when
    // `AppFeatures.dataTransfer` is off — `DataTransferSheet.show` is the guard,
    // and it refuses before navigating, so an unreachable route costs nothing
    // while a conditionally-registered one would break deep links per build.
    AutoRoute(page: TransferExportRoute.page, path: '/transfer/:resource/export'),
    AutoRoute(page: TransferImportRoute.page, path: '/transfer/:resource/import'),

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
    AutoRoute(page: TestDataTransferRoute.page, path: '/test/data-transfer'),

    AutoRoute(page: ErrorRoute.page, path: '/error'),
  ];
}
