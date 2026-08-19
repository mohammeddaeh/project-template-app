import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/Features/auth/logout/presentation/cubits/logout_cubit.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Self-contained logout tile — owns its [LogoutCubit] internally.
///
/// The ONLY sanctioned way to embed logout in another feature's UI
/// (e.g. settings, profile): consumers import this widget, never
/// [LogoutCubit] directly, so the cubit/state stay private to auth/logout.
///
/// ```dart
/// ListView(children: const [..., LogoutSection()])
/// ```
class LogoutSection extends StatefulWidget {
  const LogoutSection({super.key});

  @override
  State<LogoutSection> createState() => _LogoutSectionState();
}

class _LogoutSectionState extends State<LogoutSection> {
  late final LogoutCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<LogoutCubit>();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.logoutConfirmTitle,
      messageKey: LocaleKeys.logoutConfirmMessage,
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      _cubit.logout();
    }
  }

  /// Second gate: the user has already said "sign out", and the device turns
  /// out to be holding work that exists nowhere else.
  ///
  /// Signing out strands it — the queue outlives the token, and only the
  /// account that wrote those operations can ever push them. So this is not a
  /// warning to acknowledge; it is a decision, and it is the user's.
  Future<void> _confirmDiscardPending(int pendingOperations) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.logoutPendingWorkTitle,
      messageKey: LocaleKeys.logoutPendingWorkMessage,
      messageArgs: {'count': '$pendingOperations'},
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      _cubit.logout(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr() on locale change
    context.locale;
    return BlocConsumer<LogoutCubit, LogoutState>(
      bloc: _cubit,
      listener: (context, state) {
        state.maybeWhen(
          error: (msg) => context.feedback.error(msg),
          // The cubit refused to decide on the user's behalf, so ask. A second
          // dialog for a second question: the first asked "sign out?", this one
          // says what signing out costs *right now* — and the count is the whole
          // message. "You have unsynced work" is ignorable; "37 changes have not
          // been sent" is not.
          pendingWork: (count) => _confirmDiscardPending(count),
          orElse: () {},
        );
      },
      builder: (context, state) {
        final isLoading = state is LogoutLoading;
        return ListTile(
          leading: Icon(Icons.logout, color: context.colors.stateError),
          title: Text(
            LocaleKeys.logOut.tr(),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.stateError,
            ),
          ),
          trailing: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation(context.colors.stateError),
                  ),
                )
              : null,
          onTap: isLoading ? null : _confirmLogout,
        );
      },
    );
  }
}
