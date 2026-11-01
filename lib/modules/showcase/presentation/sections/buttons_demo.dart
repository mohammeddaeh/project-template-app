import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/sections/demo_block.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Every [AppButtonVariant] and size, the loading and disabled states, and the
/// status chips — each labelled with the name to write in code.
class ButtonsDemo extends StatelessWidget {
  const ButtonsDemo({super.key});

  static void _noop() {}

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DemoBlock(
        code: 'AppButton(variant: AppButtonVariant.…)',
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
        code: 'AppButtonVariant.onBrand',
        child: ColoredBox(
          color: context.colors.bgBrand,
          child: Padding(
            padding: 16.allPadding,
            child: AppButton(
              text: AppButtonVariant.onBrand.name,
              variant: AppButtonVariant.onBrand,
              onTap: _noop,
            ),
          ),
        ),
      ),
      DemoBlock(
        code: 'AppButton(size: AppButtonSize.…)',
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
      const DemoBlock(
        code: 'isLoading: true · isEnabled: false',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppButton(text: 'isLoading', isLoading: true, onTap: _noop),
            AppButton(text: 'isEnabled', isEnabled: false, onTap: _noop),
          ],
        ),
      ),
      DemoBlock(
        code: 'StatusChip(tone: StatusTone.…)',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in StatusTone.values)
              StatusChip(labelText: t.name, tone: t),
          ],
        ),
      ),
    ],
  );
}
