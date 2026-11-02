import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/features/startup/startup_destination.dart';
import 'package:app_template/features/startup/startup_resolver.dart';

/// Where the first frame lands, for every auth mode — and where the welcome
/// screen goes on to, since it asks the same function with `welcomeSeen: true`.
void main() {
  StartupDestination decide(
    AuthMode mode, {
    bool seen = true,
    bool signedIn = false,
  }) => decideStartup(mode: mode, welcomeSeen: seen, signedIn: signedIn);

  test('a first launch shows the welcome, whatever the mode', () {
    for (final mode in AuthMode.values) {
      expect(
        decide(mode, seen: false),
        StartupDestination.welcome,
        reason: '$mode',
      );
      expect(
        decide(mode, seen: false, signedIn: true),
        StartupDestination.welcome,
        reason: '$mode',
      );
    }
  });

  test('none and optional go home, signed in or not', () {
    for (final mode in [AuthMode.none, AuthMode.optional]) {
      expect(decide(mode), StartupDestination.shell, reason: '$mode');
      expect(
        decide(mode, signedIn: true),
        StartupDestination.shell,
        reason: '$mode',
      );
    }
  });

  test('required sends a guest to sign in and a session home', () {
    expect(decide(AuthMode.required), StartupDestination.login);
    expect(decide(AuthMode.required, signedIn: true), StartupDestination.shell);
  });
}
