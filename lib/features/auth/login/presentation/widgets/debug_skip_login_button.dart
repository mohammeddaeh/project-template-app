import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Skips sign-in straight into the shell. The page shows it in debug builds
/// only (`kDebugMode`) — the check stays at the call site, where it is seen.
class DebugSkipLoginButton extends StatelessWidget {
  const DebugSkipLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PrimaryButton(
        text: LocaleKeys.skipLoginDebug.tr(),
        isTextOnly: true,
        onTap: () => context.router.replaceAll([const MainShellRoute()]),
      ),
    );
  }
}
