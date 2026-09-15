import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/notification_center/domain/notification_center_item.dart';
import 'package:app_template/modules/notification_center/presentation/cubits/notification_center_cubit.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// "What did I miss?" — every push notification received in the foreground,
/// kept for review after its toast/banner is gone.
///
/// ## Mounting
/// Only reachable when `AppFeatures.notificationCenter` is true — see
/// `NotificationCenterPlugin`. Push it from a bell icon in the shell or from
/// settings:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
/// );
/// ```
/// Deliberately NOT an `@RoutePage()` — same reason as `ActiveDevicesScreen`
/// in `modules/multi_device/`: an auto_route entry would put this screen in
/// the router of every project built on this template, including the ones
/// that ship with the module disabled.
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotificationCenterCubit>(),
      child: const _NotificationCenterView(),
    );
  }
}

class _NotificationCenterView extends StatelessWidget {
  const _NotificationCenterView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPage,
      appBar: AppBar(
        title: Text(LocaleKeys.notificationCenterTitle.tr()),
        actions: const [_MarkAllReadAction(), _ClearAllAction()],
      ),
      body: SafeArea(
        child: BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
          builder: (context, state) => switch (state) {
            NotificationCenterLoading() => const Center(
              child: LoadingWidget(),
            ),
            NotificationCenterLoaded(:final items) => items.isEmpty
                ? const EmptyStateWidget(
                    titleKey: LocaleKeys.notificationCenterEmpty,
                    icon: Icons.notifications_none_rounded,
                  )
                : _List(items: items),
          },
        ),
      ),
    );
  }
}

class _MarkAllReadAction extends StatelessWidget {
  const _MarkAllReadAction();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationCenterCubit>().state;
    final unread = state is NotificationCenterLoaded ? state.unreadCount : 0;

    return IconButton(
      icon: const Icon(Icons.done_all),
      tooltip: LocaleKeys.notificationCenterMarkAllRead.tr(),
      onPressed: unread == 0
          ? null
          : () => context.read<NotificationCenterCubit>().markAllRead(),
    );
  }
}

class _ClearAllAction extends StatelessWidget {
  const _ClearAllAction();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationCenterCubit>().state;
    final isEmpty =
        state is NotificationCenterLoaded ? state.items.isEmpty : true;

    return IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: LocaleKeys.notificationCenterClearAll.tr(),
      onPressed: isEmpty ? null : () => _confirmClear(context),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final cubit = context.read<NotificationCenterCubit>();
    final ok = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.notificationCenterClearConfirmTitle,
      messageKey: LocaleKeys.notificationCenterClearConfirmMessage,
      confirmKey: LocaleKeys.notificationCenterClearAll,
      isDestructive: true,
    );
    if (!ok) return;
    await cubit.clearAll();
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});

  final List<NotificationCenterItem> items;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationCenterCubit>();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const DividerWidget(),
      itemBuilder: (context, index) {
        final item = items[index];
        return AppListTile(
          titleText: item.title?.trim().isNotEmpty == true
              ? item.title!.trim()
              : LocaleKeys.notificationCenterUntitled.tr(),
          subtitleText: item.body,
          titleColor: item.read ? context.colors.textMuted : null,
          leading: item.read
              ? null
              : Icon(Icons.circle, size: 10, color: context.colors.error),
          trailing: Text(
            DateFormat.MMMd(
              context.locale.languageCode,
            ).add_jm().format(item.receivedAt.toLocal()),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textMuted,
            ),
          ),
          onTap: item.read ? null : () => cubit.markRead(item.id),
        );
      },
    );
  }
}
