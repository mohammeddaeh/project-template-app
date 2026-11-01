import 'package:app_template/features/auth/shared/entities/auth_user.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The signed-in user's card: name, address, and the facts `WireAccount`
/// carries — nothing more (see the doc on `ProfileScreen`).
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return DetailHeaderCard(
      title: user.displayName,
      subtitle: user.email,
      leading: AvatarWidget(initial: user.initial, radius: 28),
      facts: [
        DetailFact(
          icon: Icons.alternate_email,
          label: LocaleKeys.eMail.tr(),
          value: user.email,
          // Digits reorder visibly in an RTL layout without this.
          forceLtr: true,
        ),
        DetailFact(
          icon: user.emailVerified
              ? Icons.verified_outlined
              : Icons.gpp_maybe_outlined,
          label: LocaleKeys.eMail.tr(),
          value: user.emailVerified
              ? LocaleKeys.emailVerifiedYes.tr()
              : LocaleKeys.emailVerifiedNo.tr(),
        ),
        DetailFact(
          icon: Icons.badge_outlined,
          label: LocaleKeys.accountStatus.tr(),
          value: _statusLabel(user.status),
        ),
        DetailFact(
          icon: Icons.event_outlined,
          label: LocaleKeys.memberSince.tr(),
          value: DateFormat.yMMMd(
            context.locale.languageCode,
          ).format(user.createdAt),
        ),
      ],
    );
  }

  /// Exhaustive by construction — `switch` over a Dart enum has no default arm,
  /// so a status added to [AuthUserStatus] fails to compile here rather than
  /// rendering as a blank row.
  String _statusLabel(AuthUserStatus status) => switch (status) {
    AuthUserStatus.pendingVerification =>
      LocaleKeys.statusPendingVerification.tr(),
    AuthUserStatus.active => LocaleKeys.statusActive.tr(),
    AuthUserStatus.disabled => LocaleKeys.statusDisabled.tr(),
  };
}
