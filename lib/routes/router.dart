import 'package:auto_route/auto_route.dart';
import 'package:app_template/modules/access_control/guards/permission_route_guard.dart';
import 'package:app_template/resources/permission_keys.g.dart';
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


    // ── Import / export (modules/data_transfer) ────────────────────────────
    //
    // Generic: `:resource` is a wire name, so these two routes serve every
    // transferable feature the backend declares. They stay registered even when
    // `AppFeatures.dataTransfer` is off — `DataTransferSheet.show` is the guard,
    // and it refuses before navigating, so an unreachable route costs nothing
    // while a conditionally-registered one would break deep links per build.
    AutoRoute(page: TransferExportRoute.page, path: '/transfer/:resource/export'),
    AutoRoute(page: TransferImportRoute.page, path: '/transfer/:resource/import'),

    // ── Roles & permissions (modules/access_control) ───────────────────────
    //
    // Generic in the same way: the roles screen renders whatever permissions
    // the backend declares, so these two routes serve every guarded feature
    // that will ever exist in this application.
    //
    // Guarded by `roles.view` / `user_access.view` — the module's own keys,
    // declared by the same `requirePermission()` calls a feature would use.
    // `PermissionRouteGuard` passes through untouched when
    // `AppFeatures.accessControl` is off, so these stay registered in every
    // build rather than appearing and disappearing with a flag.
    //
    // Named through `PermKeys`, never as a literal: a key the server stops
    // enforcing vanishes from the generated file and **breaks this build**,
    // instead of leaving a route nobody can reach and nothing complains about.
    AutoRoute(
      page: RolesRoute.page,
      path: '/roles',
      guards: [PermissionRouteGuard(PermKeys.rolesView)],
    ),
    AutoRoute(
      page: UserAccessRoute.page,
      path: '/users/:userId/access',
      guards: [PermissionRouteGuard(PermKeys.userAccessView)],
    ),


    AutoRoute(page: ErrorRoute.page, path: '/error'),
  ];
}
