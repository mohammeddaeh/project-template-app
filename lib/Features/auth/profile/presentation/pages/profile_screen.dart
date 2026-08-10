import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/Features/auth/logout/presentation/widgets/logout_section.dart';
import 'package:app_template/Features/auth/shared/current_user_repository.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/presentation/extensions/screen_sizes_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// The signed-in user, read-only, plus the way out.
///
/// ## Why it listens instead of reading once
///
/// It binds to [CurrentUserRepository.userStream] rather than taking a snapshot
/// in `initState`. The background `GET /users/me` can land at any moment, and
/// this is precisely the screen someone opens to find out whether their account
/// status changed — a snapshot would show them the state from launch and look
/// authoritative while doing it.
///
/// ## Why an empty state exists at all
///
/// A user can reach here with a valid token and no cached profile (first launch
/// after an install that restored the token, or a failed refresh). The answer is
/// not a blank screen: it names the situation and still offers sign-out, which
/// is the one action that always works and always fixes it.
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

          return ListView(
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
                  title: user.fullName,
                  subtitle: user.email,
                  leading: AvatarWidget(
                    initial: user.fullName.isNotEmpty ? user.fullName[0] : '?',
                    imageUrl: user.image ?? '',
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
                      icon: Icons.phone_outlined,
                      label: LocaleKeys.phone.tr(),
                      value: user.phone,
                      forceLtr: true,
                    ),
                    // Passed even when null: `DetailFact` states an absent
                    // value rather than dropping the row, so "no address on
                    // file" cannot be mistaken for "this screen forgot to
                    // show it".
                    DetailFact(
                      icon: Icons.place_outlined,
                      label: LocaleKeys.address.tr(),
                      value: user.address,
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              const LogoutSection(),
            ],
          );
        },
      ),
    );
  }
}
