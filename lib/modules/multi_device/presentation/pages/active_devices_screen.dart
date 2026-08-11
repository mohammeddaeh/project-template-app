import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/multi_device/domain/device_session.dart';
import 'package:app_template/modules/multi_device/presentation/active_devices_cubit.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// "Where is my account signed in, and how do I stop that?"
///
/// ## Mounting
/// Only reachable when `AppFeatures.multiDevice` is true — see
/// `MultiDevicePlugin`. Push it from settings or the profile screen:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (_) => const ActiveDevicesScreen()),
/// );
/// ```
/// Deliberately NOT an `@RoutePage()`: an auto_route entry would put the screen
/// in the router of every project built on this template, including the ones
/// that ship with the module disabled — a route that resolves to a screen whose
/// dependencies were never registered.
class ActiveDevicesScreen extends StatelessWidget {
  const ActiveDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ActiveDevicesCubit>()..load(),
      child: const _ActiveDevicesView(),
    );
  }
}

class _ActiveDevicesView extends StatelessWidget {
  const _ActiveDevicesView();

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return Scaffold(
      backgroundColor: context.colors.bgPage,
      appBar: AppBar(title: Text(LocaleKeys.activeDevicesTitle.tr())),
      body: SafeArea(
        child: BlocConsumer<ActiveDevicesCubit, ActiveDevicesState>(
          listener: (context, state) {
            if (state is ActiveDevicesError && state.message.isNotEmpty) {
              context.feedback.error(state.message);
            }
          },
          builder: (context, state) {
            final cubit = context.read<ActiveDevicesCubit>();

            return switch (state) {
              ActiveDevicesInitial() ||
              ActiveDevicesLoading() =>
                const Center(child: LoadingWidget()),
              // `messageKey` receives an already-translated string, matching
              // how every other screen here does it: `.tr()` returns its input
              // unchanged when the input is not a known key.
              ActiveDevicesError(:final message) => ErrorStateWidget(
                  messageKey: message,
                  onRetry: cubit.load,
                ),
              ActiveDevicesLoaded(:final sessions) => _List(
                  sessions: sessions,
                  otherCount: state.otherCount,
                  revokingId: null,
                ),
              ActiveDevicesRevoking(:final sessions, :final id) => _List(
                  sessions: sessions,
                  otherCount: sessions.where((s) => !s.isCurrent).length,
                  revokingId: id,
                ),
            };
          },
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.sessions,
    required this.otherCount,
    required this.revokingId,
  });

  final List<DeviceSession> sessions;
  final int otherCount;
  final int? revokingId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ActiveDevicesCubit>();

    if (sessions.isEmpty) {
      // Barely reachable — reading this screen requires a live session, which
      // is itself a row. Handled anyway rather than rendering an empty list
      // with no explanation.
      return const EmptyStateWidget(titleKey: LocaleKeys.deviceEmpty);
    }

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          Text(
            LocaleKeys.activeDevicesSubtitle.tr(),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          for (final session in sessions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SessionCard(
                session: session,
                isRevoking: revokingId == session.id,
                onRevoke: () => _confirmRevoke(context, session),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              // Disabled at zero rather than hidden: a control that disappears
              // reads as a bug, while a disabled one with "no other devices"
              // beside it has already answered the question.
              onPressed: otherCount == 0
                  ? null
                  : () => _confirmRevokeOthers(context, otherCount),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(
                otherCount == 0
                    ? LocaleKeys.deviceNoOthers.tr()
                    : LocaleKeys.deviceRevokeOthers.tr(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // The reason someone opens this screen at all. Naming the second step
          // matters: ending a session logs an intruder out, but they still know
          // the password that let them in.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 16,
                color: context.colors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LocaleKeys.deviceSecurityNote.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRevoke(
    BuildContext context,
    DeviceSession session,
  ) async {
    final cubit = context.read<ActiveDevicesCubit>();
    final ok = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.deviceRevokeConfirmTitle,
      messageKey: LocaleKeys.deviceRevokeConfirmMessage,
      confirmKey: LocaleKeys.deviceRevoke,
      isDestructive: true,
    );
    if (!ok || !context.mounted) return;
    await cubit.revokeSession(session.id);
  }

  Future<void> _confirmRevokeOthers(BuildContext context, int count) async {
    final cubit = context.read<ActiveDevicesCubit>();
    final ok = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.deviceRevokeOthersConfirmTitle,
      messageKey: LocaleKeys.deviceRevokeOthersConfirmMessage,
      confirmKey: LocaleKeys.deviceRevokeOthers,
      isDestructive: true,
    );
    if (!ok || !context.mounted) return;
    await cubit.revokeOthers();
    if (!context.mounted) return;
    context.feedback.success(
      LocaleKeys.deviceRevokeOthersDone.tr(args: ['$count']),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.isRevoking,
    required this.onRevoke,
  });

  final DeviceSession session;
  final bool isRevoking;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = session.deviceInfo?.trim().isNotEmpty == true
        ? session.deviceInfo!.trim()
        // Named rather than left blank. A session opened by an older build, by
        // curl, or with this module disabled carries no label — and "unknown
        // device" is a fact the reader can act on; an empty row is not.
        : LocaleKeys.deviceUnknown.tr();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: session.isCurrent ? colors.statusSuccessFg : colors.borderSubtle,
          width: session.isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.devices_outlined, size: 20, color: colors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (session.isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.statusSuccessBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    LocaleKeys.deviceThisDevice.tr(),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.statusSuccessFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _fact(context, LocaleKeys.deviceLastActive.tr(), session.lastActiveAt),
          _fact(context, LocaleKeys.deviceSignedInAt.tr(), session.createdAt),
          _fact(context, LocaleKeys.deviceExpiresAt.tr(), session.expiresAt),
          // No "sign out" on the current session: that is logout, it lives
          // elsewhere, and offering it here would make the obvious button on
          // the obvious row do something other than what the screen is for.
          if (!session.isCurrent) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: isRevoking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton.icon(
                      onPressed: onRevoke,
                      icon: const Icon(Icons.logout, size: 16),
                      label: Text(LocaleKeys.deviceRevoke.tr()),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.statusErrorFg,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fact(BuildContext context, String label, DateTime value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textMuted,
            ),
          ),
          Text(
            // Localised through easy_localization's DateFormat so an Arabic
            // reader gets Arabic month names, not an ISO string.
            DateFormat.yMMMd(context.locale.languageCode).add_jm().format(
                  value.toLocal(),
                ),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
