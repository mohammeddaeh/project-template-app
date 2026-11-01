import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The motion the template ships — each demo replays on a tap. All of it
/// stands still when the system asks to reduce motion.
class MotionDemo extends StatefulWidget {
  const MotionDemo({super.key});

  @override
  State<MotionDemo> createState() => _MotionDemoState();
}

class _MotionDemoState extends State<MotionDemo> {
  int _count = 1200;
  int _step = 0;
  int _listRun = 0;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code: 'ListItemAppearWdg(staggerIndex: i)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A new key per run plays the entrance again.
              Column(
                key: ValueKey(_listRun),
                children: [
                  for (var i = 0; i < 4; i++)
                    ListItemAppearWdg(
                      staggerIndex: i,
                      child: AppListTile(
                        titleText: LocaleKeys.showcaseItem.tr(
                          args: ['${i + 1}'],
                        ),
                        leadingIcon: Icons.circle_outlined,
                        dense: true,
                      ),
                    ),
                ],
              ),
              AppButton(
                text: LocaleKeys.showcaseReplay.tr(),
                variant: AppButtonVariant.text,
                onTap: () => setState(() => _listRun++),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'AppOpenContainer',
          child: AppOpenContainer<void>(
            closedBuilder: (context, open) => AppListTile(
              titleKey: LocaleKeys.showcaseOpenCard,
              leadingIcon: Icons.open_in_full,
              onTap: open,
            ),
            openBuilder: (context, close) => Scaffold(
              appBar: AppBar(title: Text(LocaleKeys.showcaseMotion.tr())),
              body: Center(
                child: AppButton(
                  text: LocaleKeys.showcaseBack.tr(),
                  onTap: close,
                ),
              ),
            ),
          ),
        ),
        DemoBlock(
          code: 'AppStepSwitcher(step: …)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppStepSwitcher(
                step: _step,
                child: _StepCard(step: _step),
              ),
              12.heightBox,
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: LocaleKeys.showcaseBack.tr(),
                      variant: AppButtonVariant.outlined,
                      isEnabled: _step > 0,
                      onTap: () => setState(() => _step--),
                    ),
                  ),
                  8.widthBox,
                  Expanded(
                    child: AppButton(
                      text: LocaleKeys.showcaseNext.tr(),
                      isEnabled: _step < 2,
                      onTap: () => setState(() => _step++),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'AnimatedCount(value: …)',
          child: Row(
            children: [
              Expanded(
                child: AnimatedCount(
                  value: _count,
                  style: context.textTheme.headlineMedium,
                ),
              ),
              AppButton(
                text: LocaleKeys.showcaseAdd.tr(),
                variant: AppButtonVariant.tonal,
                leadingIcon: Icons.add,
                onTap: () => setState(() => _count += 250),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'PressableScale',
          child: PressableScale(
            child: AppCard(
              variant: AppCardVariant.container,
              child: Center(
                child: Icon(
                  Icons.touch_app_outlined,
                  color: context.colors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: AppCardVariant.container,
    child: Center(
      child: Text(
        LocaleKeys.showcaseStep.tr(args: ['${step + 1}']),
        style: context.textTheme.headlineSmall,
      ),
    ),
  );
}
