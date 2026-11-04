import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The template's own screens keep their body to a readable width on a tablet
/// (readme/ui/22_RESPONSIVE.md §6). Without it a form stretches to 1200 pixels:
/// the label at one edge, its value at the other — and on a phone nothing
/// shows the difference, so nothing else catches it coming back.
///
/// Named one by one, not every `*_screen.dart`: a project's own screens follow
/// the rule from lib/CLAUDE.md, and this file does not decide for them.
void main() {
  const screens = {
    'lib/features/auth/change_password/presentation/pages/change_password_screen.dart':
        'AuthFormBody(',
    'lib/features/auth/forgot_password/presentation/pages/forgot_password_screen.dart':
        'AuthFormBody(',
    'lib/features/auth/forgot_password/presentation/pages/reset_password_screen.dart':
        'AuthFormBody(',
    'lib/features/auth/login/presentation/pages/account_login_screen.dart':
        'AuthFormBody(',
    'lib/features/auth/login/presentation/pages/login_screen.dart':
        'AuthFormBody(',
    'lib/features/auth/register/presentation/pages/register_screen.dart':
        'AuthFormBody(',
    'lib/features/auth/verify_email/presentation/pages/verify_email_screen.dart':
        'AuthFormBody(',
    'lib/features/auth/profile/presentation/pages/profile_screen.dart':
        'ContentWidth.content',
    'lib/features/settings/presentation/pages/settings_screen.dart':
        'ContentWidth.content',
    'lib/features/startup/presentation/pages/welcome_screen.dart':
        'ContentWidth.form',
    // Every account form above draws through it.
    'lib/features/auth/shared/presentation/auth_form_body.dart':
        'ContentWidth.form',
  };

  for (final MapEntry(key: path, value: width) in screens.entries) {
    test(path.split('/').last, () {
      final file = File(path);
      if (!file.existsSync()) return; // a project removed the screen
      final src = file.readAsStringSync();
      expect(src, contains(width));
      if (!width.endsWith('(')) {
        expect(src, contains('ResponsiveContentBox('));
      }
    });
  }
}
