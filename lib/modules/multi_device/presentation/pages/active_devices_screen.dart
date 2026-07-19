import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/multi_device/domain/device_session.dart';
import 'package:app_template/modules/multi_device/presentation/active_devices_cubit.dart';
import 'package:app_template/resources/locale_keys.g.dart';

/// Screen showing all active sessions for the current user.
///
/// Revoke buttons are visible only when the current device is primary.
/// Add to your settings/profile section:
/// ```dart
/// // In your router:
/// AutoRoute(page: ActiveDevicesRoute.page)
///
/// // Navigate:
/// context.pushRoute(const ActiveDevicesRoute())
/// ```
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
      appBar: AppBar(title: Text(LocaleKeys.activeDevicesTitle.tr())),
      body: BlocBuilder<ActiveDevicesCubit, ActiveDevicesState>(
        builder: (context, state) => switch (state) {
          ActiveDevicesInitial() ||
          ActiveDevicesLoading() =>
            const Center(child: CircularProgressIndicator()),

          ActiveDevicesError(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message.isEmpty
                      ? LocaleKeys.somethingWrong.tr()
                      : message),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.read<ActiveDevicesCubit>().load(),
                    child: Text(LocaleKeys.retry.tr()),
                  ),
                ],
              ),
            ),

          ActiveDevicesRevoking() => const Center(
              child: CircularProgressIndicator(),
            ),

          ActiveDevicesLoaded(
            :final sessions,
            :final maxDevices,
            :final isCurrentDevicePrimary,
          ) =>
            _LoadedBody(
              sessions: sessions,
              maxDevices: maxDevices,
              isCurrentDevicePrimary: isCurrentDevicePrimary,
            ),
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.sessions,
    required this.maxDevices,
    required this.isCurrentDevicePrimary,
  });

  final List<DeviceSession> sessions;
  final int maxDevices;
  final bool isCurrentDevicePrimary;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  LocaleKeys.activeDevicesCount.tr(namedArgs: {
                    'count': '${sessions.length}',
                    'max': '$maxDevices',
                  }),
                  style: context.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _DeviceTile(
              session: sessions[index],
              isCurrentDevicePrimary: isCurrentDevicePrimary,
            ),
          ),
        ),
        if (isCurrentDevicePrimary && sessions.length > 1)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: OutlinedButton(
              onPressed: () => _confirmRevokeAll(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: context.colorScheme.error,
                side: BorderSide(color: context.colorScheme.error),
              ),
              child: Text(LocaleKeys.revokeAllDevices.tr()),
            ),
          ),
      ],
    );
  }

  void _confirmRevokeAll(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.revokeAllDevices.tr()),
        content: Text(LocaleKeys.revokeAllDevicesMessage.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context
                  .read<ActiveDevicesCubit>()
                  .revokeAllExceptCurrent();
            },
            child: Text(
              LocaleKeys.logOut.tr(),
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.session,
    required this.isCurrentDevicePrimary,
  });

  final DeviceSession session;
  final bool isCurrentDevicePrimary;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    return ListTile(
      leading: Icon(
        session.platform == 'ios' ? Icons.phone_iphone : Icons.phone_android,
        color: session.isCurrent ? context.colorScheme.primary : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              session.deviceName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (session.isPrimary) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                LocaleKeys.primaryDeviceBadge.tr(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        session.isCurrent
            ? LocaleKeys.thisDeviceActiveNow.tr()
            : LocaleKeys.lastActive.tr(
                namedArgs: {'date': _formatDate(session.lastActiveAt)}),
      ),
      trailing: _buildTrailing(context),
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    // Current device: no revoke button (can't revoke yourself from this screen)
    if (session.isCurrent) return null;

    // Non-primary devices: read-only
    if (!isCurrentDevicePrimary) return null;

    // Primary device viewing others: show revoke button
    return TextButton(
      onPressed: () => _confirmRevoke(context),
      style: TextButton.styleFrom(
        foregroundColor: context.colorScheme.error,
      ),
      child: Text(LocaleKeys.logOut.tr()),
    );
  }

  void _confirmRevoke(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.revokeDeviceTitle.tr()),
        content: Text(LocaleKeys.revokeDeviceMessage
            .tr(namedArgs: {'device': session.deviceName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context
                  .read<ActiveDevicesCubit>()
                  .revokeSession(session.deviceSessionId);
            },
            child: Text(
              LocaleKeys.logOut.tr(),
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return LocaleKeys.today.tr();
    if (diff.inDays == 1) return LocaleKeys.yesterday.tr();
    return LocaleKeys.daysAgo.tr(namedArgs: {'days': '${diff.inDays}'});
  }
}
