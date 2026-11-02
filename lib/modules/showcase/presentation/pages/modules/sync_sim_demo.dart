import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/sim_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `modules/sync/` played on the device: writes made offline wait in a queue,
/// and going online sends them one by one under [SyncProgressOverlay] — one of
/// them meets a conflict on the way and is resolved.
class SyncSimDemo extends StatefulWidget {
  const SyncSimDemo({super.key});

  @override
  State<SyncSimDemo> createState() => _SyncSimDemoState();
}

enum _JobStatus { queued, sent, conflict, resolved }

class _Job {
  _Job(this.number);

  final int number;
  _JobStatus status = _JobStatus.queued;
}

class _SyncSimDemoState extends State<SyncSimDemo> {
  final _jobs = <_Job>[];
  bool _offline = true;
  bool _flushing = false;
  int _done = 0;
  int _total = 0;
  int _next = 1;

  int get _pending => _jobs.where((j) => j.status == _JobStatus.queued).length;

  void _add() {
    setState(() => _jobs.insert(0, _Job(_next++)));
    if (!_offline) _flush();
  }

  void _setOffline(bool value) {
    setState(() => _offline = value);
    if (!value) _flush();
  }

  Future<void> _flush() async {
    // Oldest first, as the real queue drains.
    final batch = _jobs.reversed
        .where((j) => j.status == _JobStatus.queued)
        .toList();
    if (_flushing || batch.isEmpty) return;
    setState(() {
      _flushing = true;
      _done = 0;
      _total = batch.length;
    });
    for (var i = 0; i < batch.length; i++) {
      // Stands in for one push to the server.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      // The second write of a batch collides with a newer server copy.
      if (i == 1) {
        setState(() => batch[i].status = _JobStatus.conflict);
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        setState(() => batch[i].status = _JobStatus.resolved);
      } else {
        setState(() => batch[i].status = _JobStatus.sent);
      }
      setState(() => _done = i + 1);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _flushing = false);
  }

  (String, StatusTone) _status(_JobStatus s) => switch (s) {
    _JobStatus.queued => (
      LocaleKeys.showcaseSyncQueued.tr(),
      StatusTone.warning,
    ),
    _JobStatus.sent => (LocaleKeys.showcaseSyncSent.tr(), StatusTone.success),
    _JobStatus.conflict => (
      LocaleKeys.showcaseSyncConflict.tr(),
      StatusTone.error,
    ),
    _JobStatus.resolved => (
      LocaleKeys.showcaseSyncResolved.tr(),
      StatusTone.info,
    ),
  };

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
          code:
              'AppFeatures.offlineSync · SyncManagerCubit · '
              'SyncProgressOverlay(done:, total:) · '
              'AppBar(actions: [PendingChangesChip()])',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220),
            // The overlay fills a Stack — here this block, in an app the page.
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppListTile(
                      titleText: LocaleKeys.showcaseSyncOfflineMode.tr(),
                      leadingIcon: _offline
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_done_outlined,
                      trailing: Switch.adaptive(
                        value: _offline,
                        onChanged: _flushing ? null : _setOffline,
                      ),
                    ),
                    8.heightBox,
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // An empty queue shows the bare icon, not a "0" badge.
                        if (_pending > 0)
                          BadgeWidget(
                            count: _pending,
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              color: colors.iconSubtle,
                            ),
                          )
                        else
                          Icon(
                            Icons.cloud_done_outlined,
                            color: colors.iconSubtle,
                          ),
                        StatusChip(
                          labelText: LocaleKeys.showcaseSyncPending.tr(
                            args: ['$_pending'],
                          ),
                          tone: _pending > 0
                              ? StatusTone.warning
                              : StatusTone.neutral,
                        ),
                      ],
                    ),
                    12.heightBox,
                    AppButton(
                      text: LocaleKeys.showcaseAdd.tr(),
                      variant: AppButtonVariant.tonal,
                      leadingIcon: Icons.add,
                      isEnabled: !_flushing,
                      onTap: _add,
                    ),
                    12.heightBox,
                    if (_jobs.isEmpty)
                      Text(
                        LocaleKeys.showcaseSyncEmpty.tr(),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      )
                    else
                      for (final job in _jobs)
                        ListItemAppearWdg(
                          key: ValueKey(job.number),
                          child: AppListTile(
                            titleText: LocaleKeys.showcaseItem.tr(
                              args: ['${job.number}'],
                            ),
                            leadingIcon: Icons.description_outlined,
                            trailing: StatusChip(
                              labelText: _status(job.status).$1,
                              tone: _status(job.status).$2,
                            ),
                            dense: true,
                          ),
                        ),
                  ],
                ),
                if (_flushing) SyncProgressOverlay(done: _done, total: _total),
              ],
            ),
          ),
        ),
        DemoBlock(
          code:
              'SyncUiHost(child: …) → '
              'SyncStatusBanner(position: BannerPosition.top)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.showcaseSyncBannerHint.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              12.heightBox,
              AnimatedSwitcher(
                duration: AppMotion.of(context).base,
                child: _offline
                    ? _BannerPreview(
                        key: const ValueKey('offline'),
                        icon: Icons.cloud_off_rounded,
                        message: LocaleKeys.noInternetConnection.tr(),
                        color: colors.stateError,
                      )
                    : _pending > 0
                    ? _BannerPreview(
                        key: const ValueKey('pending'),
                        icon: Icons.sync_rounded,
                        message: LocaleKeys.showcaseSyncPending.tr(
                          args: ['$_pending'],
                        ),
                        color: colors.statusWarningFg,
                      )
                    : Text(
                        LocaleKeys.showcaseSyncBannerHidden.tr(),
                        key: const ValueKey('hidden'),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code:
              "AttachmentsSection(entityName: 'notes', entityLocalId: …) "
              '→ AttachmentView(attachmentId:)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.showcaseSyncAttachmentsHint.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              12.heightBox,
              Row(
                children: [
                  for (final (icon, label, tone) in [
                    (Icons.image_outlined, '', colors.primary),
                    (
                      Icons.cloud_off_rounded,
                      LocaleKeys.attachmentOfflineUnavailable.tr(),
                      colors.textMuted,
                    ),
                    (
                      Icons.error_outline_rounded,
                      LocaleKeys.attachmentFailed.tr(),
                      colors.stateError,
                    ),
                  ]) ...[
                    Expanded(
                      child: _AttachmentState(
                        icon: icon,
                        label: label,
                        color: tone,
                      ),
                    ),
                    if (icon != Icons.error_outline_rounded) 8.widthBox,
                  ],
                ],
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'lib/modules/sync/STATUS.md',
          child: Text(
            LocaleKeys.showcaseSyncRealNote.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// One of the three states [AttachmentView] resolves to — on disk, not here
/// while offline (neutral, not an error), and a real failure.
class _AttachmentState extends StatelessWidget {
  const _AttachmentState({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = context.screen;
    return Container(
      height: s.size(110),
      padding: EdgeInsets.all(s.space(6)),
      decoration: BoxDecoration(
        color: context.colors.bgNeutral,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: s.size(28)),
          if (label.isNotEmpty) ...[
            SizedBox(height: s.space(6)),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}

/// What `SyncStatusBanner` draws for the simulation's state — offline, or
/// changes waiting. The real one reads `OfflineUxCubit`, which lives with the
/// sync module and is not built here.
class _BannerPreview extends StatelessWidget {
  const _BannerPreview({
    required this.icon,
    required this.message,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadius.smRadius,
    child: ColoredBox(
      color: color.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            8.widthBox,
            Expanded(
              child: Text(
                message,
                style: context.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
