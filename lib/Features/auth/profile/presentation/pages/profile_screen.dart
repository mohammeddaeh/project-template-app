import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/Features/auth/logout/presentation/widgets/logout_section.dart';
import 'package:app_template/Features/auth/me/domain/usecases/get_current_user_usecase.dart';
import 'package:app_template/Features/auth/shared/current_user_repository.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/foundation/domain/no_params.dart';
import 'package:app_template/presentation/extensions/screen_sizes_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// The signed-in user, read-only, plus the way out.
///
/// ## Why it listens instead of reading once
///
/// It binds to [CurrentUserRepository.userStream] rather than taking a snapshot
/// in `initState`. `GET /account/me` can land at any moment — on resume, or
/// from the pull-to-refresh below — and this is precisely the screen someone
/// opens to find out whether their account status changed. A snapshot would
/// show them the state from launch and look authoritative while doing it.
///
/// ## Why the fields are the fields they are
///
/// Six rows, and they are the six `WireAccount` carries. This screen used to
/// render phone and address off `AuthUser` fields no endpoint has ever sent, so
/// both rows read "—" on every account forever. Adding a row here means adding
/// the column server-side first — see the doc on [AuthUser].
///
/// ## Why an empty state exists at all
///
/// A user can reach here with a valid token and no cached profile (first launch
/// after an install that restored the token, or a failed refresh). The answer
/// is not a blank screen: it names the situation and still offers sign-out,
/// which is the one action that always works and always fixes it.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    final repo = getIt<CurrentUserRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.profile.tr())),
      body: StreamBuilder<AuthUser?>(
        stream: repo.userStream,
        initialData: repo.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;

          return RefreshIndicator(
            // Re-reads the account and republishes it; the stream above does the
            // redraw, so there is nothing to await into local state here.
            onRefresh: () => getIt<GetCurrentUserUseCase>()(const NoParams()),
            child: ListView(
              // Always scrollable, so pull-to-refresh still works on the empty
              // state — which is the state most in need of a retry.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                32 + context.bottomContentInset,
              ),
              children: [
                if (user == null)
                  EmptyStateWidget(
                    titleKey: LocaleKeys.noDataFound,
                    icon: Icons.person_off_outlined,
                  )
                else
                  DetailHeaderCard(
                    title: user.displayName,
                    subtitle: user.email,
                    leading: AvatarWidget(
                      initial: user.initial,
                      radius: 28,
                    ),
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
                  ),
                const SizedBox(height: 24),
                const LogoutSection(),
              ],
            ),
          );
        },
      ),
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
