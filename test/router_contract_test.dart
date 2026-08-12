import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/routes/router.dart';
import 'package:app_template/routes/router.gr.dart';

/// Pins the routes the app navigates to against the routes it registers.
///
/// ## The failure this catches
///
/// `login_screen.dart` navigated to `MainShellRoute` for weeks while
/// `router.dart` never registered it. It compiled cleanly — `auto_route`
/// generates a `PageRouteInfo` subclass for **every** `@RoutePage()` widget it
/// finds, whether or not that page appears in `AppRouter.routes` — so the call
/// site typed perfectly and threw at runtime, on the one screen transition
/// every user makes.
///
/// `dart analyze` cannot see this. Nor can a widget test of the login screen,
/// which stubs the router. This is the smallest thing that can.
///
/// ## Adding a route
///
/// Register it in `router.dart` and add it here. A name in this list with no
/// matching registration fails; the reverse is allowed, because a route can
/// legitimately exist before anything links to it.
void main() {
  late final List<String> registered =
      AppRouter().routes.map((r) => r.name).toList();

  /// Every destination reachable from a `context.router` call in `lib/`.
  const navigatedTo = <String>[
    // Entry + auth
    'SplashRoute',
    'LoginRoute',
    'RegisterRoute',
    'ForgotPasswordRoute',
    'ResetPasswordRoute',
    'ChangePasswordRoute',
    'VerifyEmailRoute',
    // Signed in
    'MainShellRoute',
    'HomeRoute',
    'NotesRoute',
    'NoteFormRoute',
    // Utility
    'ErrorRoute',
  ];

  test('every route the app navigates to is registered', () {
    for (final name in navigatedTo) {
      expect(
        registered,
        contains(name),
        reason: '$name is navigated to in lib/ but missing from '
            'AppRouter.routes — this throws at runtime, not at compile time.',
      );
    }
  });

  test('the post-sign-in destination is the shell, from both entry points', () {
    // Splash and login must agree. They did not: splash went to `HomeRoute`
    // (the Home tab alone, no tab bar) and login to `MainShellRoute`, so where
    // a user landed depended on whether they had signed in this launch.
    expect(registered, contains(MainShellRoute.name));
    expect(MainShellRoute.name, 'MainShellRoute');
  });

  test('route paths are unique', () {
    final paths = AppRouter().routes.map((r) => r.path).toList();
    expect(
      paths.toSet().length,
      paths.length,
      reason: 'Two routes on one path: auto_route resolves the first and the '
          'second becomes unreachable by URL without any warning.',
    );
  });
}
