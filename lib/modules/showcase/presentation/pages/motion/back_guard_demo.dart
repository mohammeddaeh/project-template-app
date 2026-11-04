import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `PopScope` guarding unsaved input: once the form is dirty, leaving it —
/// by the system back button, the gesture, or the app bar arrow — asks first.
class BackGuardDemo extends StatelessWidget {
  const BackGuardDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code:
              'PopScope(canPop: !dirty, onPopInvokedWithResult: (didPop, _) '
              '{ if (!didPop) AppConfirmDialog.show(…) })',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.showcaseBackGuardHint.tr(),
                style: context.textTheme.bodyMedium,
              ),
              const ResponsiveGap(12),
              AppButton(
                text: LocaleKeys.showcaseBackGuardOpen.tr(),
                leadingIcon: Icons.edit_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const _GuardedForm()),
                ),
              ),
              const ResponsiveGap(12),
              Text(
                LocaleKeys.showcaseBackGuardPredictive.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuardedForm extends StatefulWidget {
  const _GuardedForm();

  @override
  State<_GuardedForm> createState() => _GuardedFormState();
}

class _GuardedFormState extends State<_GuardedForm> {
  final _text = TextEditingController();

  bool get _dirty => _text.text.trim().isNotEmpty;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _askToLeave() async {
    final discard = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.showcaseBackGuardDiscardTitle,
      messageKey: LocaleKeys.showcaseBackGuardDiscardMessage,
      confirmKey: LocaleKeys.showcaseBackGuardDiscard,
      isDestructive: true,
    );
    // `pop`, not `maybePop`: the answer is in, and asking again would loop.
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return PopScope<Object?>(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askToLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.showcaseBackGuardFormTitle.tr())),
        body: Padding(
          padding: EdgeInsets.all(context.screen.space(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _text,
                labelText: LocaleKeys.showcaseCrudTitle.tr(),
                onChanged: (_) => setState(() {}),
              ),
              const ResponsiveGap(8),
              AnimatedSwitcher(
                layoutBuilder: (current, previous) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Stack(children: [...previous, ?current]),
                ),
                duration: AppMotion.of(context).base,
                child: _dirty
                    ? StatusChip(
                        key: const ValueKey('dirty'),
                        labelKey: LocaleKeys.showcaseBackGuardUnsaved,
                        tone: StatusTone.warning,
                      )
                    : const SizedBox.shrink(),
              ),
              const Spacer(),
              AppButton(
                text: LocaleKeys.save.tr(),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
