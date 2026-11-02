import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/modules/in_app_updates/domain/app_update_settings.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/sim_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `modules/in_app_updates/` played on the device: the server's settings
/// name a version, the real [isVersionOlder] compares it with the installed
/// one, and the prompt is optional or forced — a forced one cannot be
/// dismissed, by the barrier or by the back button.
class UpdatesSimDemo extends StatefulWidget {
  const UpdatesSimDemo({super.key});

  @override
  State<UpdatesSimDemo> createState() => _UpdatesSimDemoState();
}

class _UpdatesSimDemoState extends State<UpdatesSimDemo> {
  /// Stands in for `PackageInfo.fromPlatform().version`.
  static const _installed = '1.2.0';
  static const _served = ['1.2.0', '1.3.0', '2.0.0'];

  String _version = '1.3.0';
  bool _force = false;
  String? _result;

  /// The dialog the module shows when the store has no native flow — the same
  /// title, message and buttons, with the store link left out.
  Future<void> _check() async {
    if (!isVersionOlder(_installed, _version)) {
      setState(() => _result = LocaleKeys.showcaseUpdatesUpToDate.tr());
      return;
    }
    final settings = AppUpdateSettings(
      version: _version,
      downloadUrl: '',
      forceUpdate: _force,
    );
    final update = await showDialog<bool>(
      context: context,
      barrierDismissible: !settings.forceUpdate,
      builder: (dialog) => PopScope(
        canPop: !settings.forceUpdate,
        child: AlertDialog(
          title: Text(LocaleKeys.updateAvailableTitle.tr()),
          content: Text(LocaleKeys.updateAvailableMessage.tr()),
          actions: [
            if (!settings.forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: Text(LocaleKeys.later.tr()),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(LocaleKeys.updateNow.tr()),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (update == true) {
      context.feedback.toast(LocaleKeys.showcaseUpdatesWouldOpen.tr());
    }
    setState(
      () => _result = update == true
          ? LocaleKeys.updateNow.tr()
          : LocaleKeys.later.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    final older = isVersionOlder(_installed, _version);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SimNotice(),
        DemoBlock(
          code:
              'AppUpdateGate(child: MainShellPage) — app_version · force_update',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyValueRow(
                labelKey: LocaleKeys.showcaseUpdatesInstalled,
                value: _installed,
                ltr: true,
              ),
              8.heightBox,
              Text(
                LocaleKeys.showcaseUpdatesServed.tr(),
                style: context.textTheme.titleSmall,
              ),
              8.heightBox,
              ChipRow<String>(
                items: _served,
                labelResolver: (v) => v,
                selectedValue: _version,
                onSelected: (v) => setState(() => _version = v ?? _version),
                scrollable: false,
              ),
              8.heightBox,
              AppListTile(
                titleText: 'force_update',
                leadingIcon: Icons.priority_high_rounded,
                trailing: Switch.adaptive(
                  value: _force,
                  onChanged: (v) => setState(() => _force = v),
                ),
              ),
              8.heightBox,
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  "isVersionOlder('$_installed', '$_version') → $older",
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
              12.heightBox,
              AppButton(
                text: LocaleKeys.showcaseUpdatesCheck.tr(),
                leadingIcon: Icons.system_update_outlined,
                onTap: _check,
              ),
              if (_result != null) ...[
                8.heightBox,
                Text(
                  LocaleKeys.showcaseDialogsResult.tr(args: [_result!]),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        DemoBlock(
          code:
              'InAppUpdatesPlugin.checkAndPrompt(context, mode: UpdateMode.flexible)',
          child: Text(
            LocaleKeys.showcaseUpdatesRealNote.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
