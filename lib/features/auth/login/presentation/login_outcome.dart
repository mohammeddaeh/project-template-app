import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/features/auth/login/domain/entities/login_entity.dart';
import 'package:app_template/features/auth/shared/entities/auth_user.dart';
import 'package:app_template/features/auth/shared/remembered_accounts_repository.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

/// Everything that happens after the server accepts a sign-in — shared by the
/// two screens that can produce one.
///
/// `LoginScreen` (email + password) and `AccountLoginScreen` (password for a
/// saved account) both end here. Written once because the two halves must agree
/// forever: where each account status lands, and when the save prompt appears.
/// A second copy would drift on the first change, and the drift would be
/// invisible — both screens would still sign people in, just to different
/// places. (Found in Qirtas, which had the table in one screen only.)
Future<void> handleLoginSuccess(
  BuildContext context,
  LoginEntity entity, {
  required RememberedAccountsRepository remembered,
}) async {
  final user = entity.user;

  if (AppFeatures.rememberedAccounts) {
    // Memoised and already warm from `main()` — but a sign-in on the very first
    // frame would otherwise offer to save an account that IS saved, because an
    // unloaded list reads exactly like an empty one.
    await remembered.ensureLoaded();

    if (remembered.isRemembered(user.email)) {
      // Keep the card's name/recency current, and do not ask again about an
      // account the user has already answered for. This is also the whole path
      // for `AccountLoginScreen`, which by definition signs in a saved account.
      await remembered.touch(user);
    } else if (context.mounted) {
      // Asked only now, never before submitting: offering to save an address
      // before the server has confirmed it works would preserve typos and dead
      // accounts as one-tap suggestions.
      final save = await AppConfirmDialog.show(
        context,
        titleKey: LocaleKeys.rememberAccountTitle,
        messageKey: LocaleKeys.rememberAccountMessage,
        confirmKey: LocaleKeys.save,
        cancelKey: LocaleKeys.notNow,
      );
      if (save) await remembered.remember(user);
    }
  }

  if (!context.mounted) return;

  // A successful sign-in does not always mean "go into the app".
  //
  // `pendingApproval` and `rejected` are successes at the credential level and
  // dead ends at the account level: the password was right and there is
  // nothing inside to show them. This template ships no approval flow, so
  // everyone else goes to the shell. If your project has one, add a status
  // screen and a case here.
  //
  // `pendingVerification` IS wired, because the backend ships it: such an
  // account signs in successfully and belongs on the code screen — the one
  // destination it can act on.
  context.router.replaceAll([
    if (user.status == AuthUserStatus.pendingVerification)
      VerifyEmailRoute(email: user.email)
    else
      const MainShellRoute(),
  ]);
}
