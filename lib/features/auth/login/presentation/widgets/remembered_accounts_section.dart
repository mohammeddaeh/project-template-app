import 'dart:async';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/features/auth/login/presentation/widgets/remembered_account_card.dart';
import 'package:app_template/features/auth/shared/entities/remembered_account.dart';
import 'package:app_template/features/auth/shared/remembered_accounts_repository.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The saved-accounts row above the login form — or nothing at all.
///
/// A shortcut above the form rather than a replacement for it: the form stays
/// exactly where a returning user last saw it, and a device with nothing saved
/// — or a build with `AppFeatures.rememberedAccounts` off — gets the original
/// screen unchanged: no empty section, no header over a blank strip.
///
/// **Checks the flag itself**, so the login screen mounts it unconditionally
/// and cannot forget the condition (same shape as `DevicesSection`).
class RememberedAccountsSection extends StatefulWidget {
  const RememberedAccountsSection({super.key});

  @override
  State<RememberedAccountsSection> createState() =>
      _RememberedAccountsSectionState();
}

class _RememberedAccountsSectionState extends State<RememberedAccountsSection> {
  late final RememberedAccountsRepository _remembered;

  @override
  void initState() {
    super.initState();
    if (!AppFeatures.rememberedAccounts) return;
    _remembered = getIt<RememberedAccountsRepository>();
    // `main()` already warmed this, but the login screen is also reachable
    // straight from a 401 (`AuthEventBus.sessionExpired`). Rebuild once it is
    // in, so the saved row is never silently missing.
    unawaited(_load());
  }

  Future<void> _load() async {
    await _remembered.ensureLoaded();
    if (mounted) setState(() {});
  }

  /// The password lives on its own route — Back then means "wrong person" with
  /// no bespoke handling, and the account being signed into is the only thing
  /// on that screen.
  Future<void> _open(RememberedAccount account) async {
    await context.router.push(AccountLoginRoute(account: account));
    // Returning here means the sign-in did not happen (a success replaces the
    // whole stack). The saved row may have changed while away, so rebuild
    // rather than trusting a stale list.
    if (mounted) setState(() {});
  }

  Future<void> _forget(RememberedAccount account) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.forgetAccountTitle,
      messageKey: LocaleKeys.forgetAccountMessage,
      confirmKey: LocaleKeys.remove,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    await _remembered.forget(account.email);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!AppFeatures.rememberedAccounts) return const SizedBox.shrink();
    final accounts = _remembered.accounts;
    if (accounts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Text(
          LocaleKeys.chooseSavedAccount.tr(),
          style: context.textTheme.headlineSmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.separated(
            // Horizontal, so five accounts never push the email field off the
            // first screen — the form has to stay reachable without scrolling
            // for anyone whose account is not on the list.
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: accounts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final account = accounts[index];
              return RememberedAccountCard(
                account: account,
                onTap: () => unawaited(_open(account)),
                onRemove: () => unawaited(_forget(account)),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const DashedDivider(),
        const SizedBox(height: 4),
        Text(
          LocaleKeys.orLoginWithAnotherAccount.tr(),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
      ],
    );
  }
}
