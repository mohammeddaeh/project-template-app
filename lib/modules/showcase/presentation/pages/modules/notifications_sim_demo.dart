import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/notification_center/domain/notification_center_item.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/sim_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `modules/notification_center/` played on the device: notifications that
/// arrived in the foreground kept in a list, read and unread, with the two
/// actions of the real screen's app bar.
class NotificationsSimDemo extends StatefulWidget {
  const NotificationsSimDemo({super.key});

  @override
  State<NotificationsSimDemo> createState() => _NotificationsSimDemoState();
}

class _NotificationsSimDemoState extends State<NotificationsSimDemo> {
  late List<NotificationCenterItem> _items = [_arrive(2), _arrive(1)];
  int _next = 3;

  int get _unread => _items.where((i) => !i.read).length;

  /// Stands in for one push received while the app is open.
  NotificationCenterItem _arrive(int n) => NotificationCenterItem(
    id: 'sim-$n',
    title: LocaleKeys.showcaseNotifTitle.tr(args: ['$n']),
    body: LocaleKeys.showcaseNotifBody.tr(),
    receivedAt: DateTime.now().subtract(Duration(minutes: 30 * (3 - n))),
  );

  void _markRead(String id) => setState(
    () => _items = [
      for (final i in _items) i.id == id ? i.copyWith(read: true) : i,
    ],
  );

  Future<void> _clear() async {
    final ok = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.notificationCenterClearConfirmTitle,
      messageKey: LocaleKeys.notificationCenterClearConfirmMessage,
      confirmKey: LocaleKeys.notificationCenterClearAll,
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _items = []);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SimNotice(),
        DemoBlock(
          code: 'NotificationCenterScreen',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (_unread > 0)
                    BadgeWidget(
                      count: _unread,
                      child: Icon(
                        Icons.notifications_outlined,
                        color: colors.iconSubtle,
                      ),
                    )
                  else
                    Icon(
                      Icons.notifications_none_outlined,
                      color: colors.iconSubtle,
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.done_all),
                    tooltip: LocaleKeys.notificationCenterMarkAllRead.tr(),
                    onPressed: _unread == 0
                        ? null
                        : () => setState(
                            () => _items = [
                              for (final i in _items) i.copyWith(read: true),
                            ],
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: LocaleKeys.notificationCenterClearAll.tr(),
                    onPressed: _items.isEmpty ? null : _clear,
                  ),
                ],
              ),
              if (_items.isEmpty)
                const EmptyStateWidget(
                  titleKey: LocaleKeys.notificationCenterEmpty,
                  icon: Icons.notifications_none_rounded,
                )
              else
                for (final item in _items)
                  ListItemAppearWdg(
                    key: ValueKey(item.id),
                    child: AppListTile(
                      titleText: item.title!,
                      subtitleText: item.body,
                      titleColor: item.read ? colors.textMuted : null,
                      leading: item.read
                          ? null
                          : Icon(Icons.circle, size: 10, color: colors.error),
                      trailing: Text(
                        DateFormat.MMMd(
                          context.locale.languageCode,
                        ).add_jm().format(item.receivedAt),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      onTap: item.read ? null : () => _markRead(item.id),
                      showDivider: item != _items.last,
                    ),
                  ),
              12.heightBox,
              AppButton(
                text: LocaleKeys.showcaseNotifArrive.tr(),
                variant: AppButtonVariant.tonal,
                leadingIcon: Icons.add_alert_outlined,
                onTap: () =>
                    setState(() => _items = [_arrive(_next++), ..._items]),
              ),
            ],
          ),
        ),
        DemoBlock(
          code:
              'AppFeatures.notificationCenter · '
              'NotificationCenterListener — pushes received in the foreground',
          child: Text(
            LocaleKeys.showcaseNotifRealNote.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
