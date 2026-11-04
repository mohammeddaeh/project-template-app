import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The buttons as playgrounds — every option of [AppButton], [PrimaryButton]
/// and [StatusChip] as a control — then every variant at a glance.
class ButtonsDemo extends StatelessWidget {
  const ButtonsDemo({super.key});

  static void _noop() {}

  static const _icons = {
    'null': null,
    'Icons.add': Icons.add,
    'Icons.save_outlined': Icons.save_outlined,
    'Icons.send': Icons.send,
  };

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoPlayground(
          call: 'AppButton',
          knobs: [
            TextKnob('text', initial: LocaleKeys.save.tr(), required: true),
            EnumKnob(
              'variant',
              AppButtonVariant.values,
              AppButtonVariant.filled,
            ),
            EnumKnob('size', AppButtonSize.values, AppButtonSize.medium),
            ChoiceKnob<IconData?>(
              'leadingIcon',
              _icons,
              apiDefaultCode: 'null',
            ),
            const BoolKnob('isLoading'),
            const BoolKnob('isEnabled', initial: true, apiDefault: true),
          ],
          trailingCode: const ['onTap: () {}'],
          // onBrand is drawn for a brand surface — show it on one.
          builder: (context, k) => ColoredBox(
            color: k<AppButtonVariant>('variant') == AppButtonVariant.onBrand
                ? context.colors.bgBrand
                : Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(context.screen.space(12)),
              child: AppButton(
                text: k('text'),
                variant: k('variant'),
                size: k('size'),
                leadingIcon: k('leadingIcon'),
                isLoading: k('isLoading'),
                isEnabled: k('isEnabled'),
                onTap: _noop,
              ),
            ),
          ),
        ),
        DemoPlayground(
          call: 'PrimaryButton',
          knobs: [
            TextKnob(
              'text',
              initial: LocaleKeys.continueLabel.tr(),
              required: true,
            ),
            const BoolKnob('isLoading'),
            const BoolKnob('isEnabled', initial: true, apiDefault: true),
            const BoolKnob('isTextOnly'),
          ],
          trailingCode: const ['onTap: () {}'],
          builder: (context, k) => PrimaryButton(
            text: k('text'),
            isLoading: k('isLoading'),
            isEnabled: k('isEnabled'),
            isTextOnly: k('isTextOnly'),
            onTap: _noop,
          ),
        ),
        DemoPlayground(
          call: 'StatusChip',
          knobs: [
            TextKnob(
              'labelText',
              initial: LocaleKeys.showcaseSyncPending.tr(args: ['3']),
              required: true,
            ),
            EnumKnob(
              'tone',
              StatusTone.values,
              StatusTone.info,
              required: true,
            ),
          ],
          builder: (context, k) =>
              StatusChip(labelText: k('labelText'), tone: k('tone')),
        ),
        DemoBlock(
          code: 'AppButtonVariant.values',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in AppButtonVariant.values)
                if (v != AppButtonVariant.onBrand)
                  AppButton(text: v.name, variant: v, onTap: _noop),
            ],
          ),
        ),
        DemoBlock(
          code: 'AppButtonSize.values',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final s in AppButtonSize.values)
                AppButton(text: s.name, size: s, onTap: _noop),
            ],
          ),
        ),
      ],
    );
  }
}
