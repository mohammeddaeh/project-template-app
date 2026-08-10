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

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr() on locale change
    context.locale;
    return BlocConsumer<LogoutCubit, LogoutState>(
      bloc: _cubit,
      listener: (context, state) {
        state.maybeWhen(
          error: (msg) => context.feedback.error(msg),
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
