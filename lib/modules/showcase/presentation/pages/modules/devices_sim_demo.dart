import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/multi_device/domain/device_session.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/sim_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `modules/multi_device/` played on the device: where the account is signed
/// in, and ending one session or every other one — the same confirmations
/// `ActiveDevicesScreen` asks, over a local list instead of the server's.
class DevicesSimDemo extends StatefulWidget {
  const DevicesSimDemo({super.key});

  @override
  State<DevicesSimDemo> createState() => _DevicesSimDemoState();
}

class _DevicesSimDemoState extends State<DevicesSimDemo> {
  late List<DeviceSession> _sessions = _seed();
  int? _revoking;

  /// The labels are what a device reports at sign-in — data, not UI text.
  static List<DeviceSession> _seed() {
    final now = DateTime.now();
    DeviceSession session(int id, String? label, Duration idle, bool current) =>
        DeviceSession(
          id: id,
          deviceInfo: label,
          provider: 'local',
          createdAt: now.subtract(Duration(days: id * 3)),
          lastActiveAt: now.subtract(idle),
          expiresAt: now.add(Duration(days: 30 - id)),
          isCurrent: current,
        );
    return [
      session(1, 'Pixel 8 · android · v1.2.0', Duration.zero, true),
      session(2, 'iPad Air · ios · v1.2.0', const Duration(hours: 5), false),
      session(3, null, const Duration(days: 2), false),
    ];
  }

  int get _others => _sessions.where((s) => !s.isCurrent).length;

  Future<void> _revoke(DeviceSession session) async {
    final ok = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.deviceRevokeConfirmTitle,
      messageKey: LocaleKeys.deviceRevokeConfirmMessage,
      confirmKey: LocaleKeys.deviceRevoke,
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _revoking = session.id);
    // Stands in for DELETE /account/sessions/{id}.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _sessions = _sessions.where((s) => s.id != session.id).toList();
      _revoking = null;
    });
  }

  Future<void> _revokeOthers() async {
    final count = _others;
    final ok = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.deviceRevokeOthersConfirmTitle,
      messageKey: LocaleKeys.deviceRevokeOthersConfirmMessage,
      confirmKey: LocaleKeys.deviceRevokeOthers,
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _sessions = _sessions.where((s) => s.isCurrent).toList());
    context.feedback.success(
      LocaleKeys.deviceRevokeOthersDone.tr(args: ['$count']),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    final s = context.screen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SimNotice(),
        DemoBlock(
          code: 'DevicesSection() → ActiveDevicesScreen',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.activeDevicesSubtitle.tr(),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              SizedBox(height: s.space(12)),
              for (final session in _sessions)
                ListItemAppearWdg(
                  key: ValueKey(session.id),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: s.space(12)),
                    child: _SessionCard(
                      session: session,
                      isRevoking: _revoking == session.id,
                      onRevoke: () => _revoke(session),
                    ),
                  ),
                ),
              AppButton(
                text: _others == 0
                    ? LocaleKeys.deviceNoOthers.tr()
                    : LocaleKeys.deviceRevokeOthers.tr(),
                variant: AppButtonVariant.outlined,
                leadingIcon: Icons.logout,
                isEnabled: _others > 0,
                onTap: _revokeOthers,
              ),
              8.heightBox,
              AppButton(
                text: LocaleKeys.showcaseReplay.tr(),
                variant: AppButtonVariant.text,
                onTap: () => setState(() => _sessions = _seed()),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'AppFeatures.multiDevice · MultiDeviceInterceptor',
          child: Text(
            LocaleKeys.showcaseDevicesRealNote.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// One session, as the real screen lays it out: the device's label, when it
/// was last used, and a sign-out on every row but this device's own.
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
    final s = context.screen;
    final label = session.deviceInfo ?? LocaleKeys.deviceUnknown.tr();
    final when = DateFormat.yMMMd(
      context.locale.languageCode,
    ).add_jm().format(session.lastActiveAt);

    return Container(
      padding: EdgeInsets.all(s.space(12)),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: session.isCurrent
              ? colors.statusSuccessFg
              : colors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.devices_outlined,
                size: s.size(20),
                color: colors.textMuted,
              ),
              8.widthBox,
              Expanded(child: Text(label, style: context.textTheme.titleSmall)),
              if (session.isCurrent)
                StatusChip(
                  labelText: LocaleKeys.deviceThisDevice.tr(),
                  tone: StatusTone.success,
                ),
            ],
          ),
          SizedBox(height: s.space(8)),
          Text(
            '${LocaleKeys.deviceLastActive.tr()}: $when',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (!session.isCurrent)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: isRevoking
                  ? Padding(
                      padding: 8.allPadding,
                      child: const AppProgress.circular(
                        size: AppProgressSize.sm,
                      ),
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
      ),
    );
  }
}
