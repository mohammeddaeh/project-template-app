import 'package:flutter/material.dart';

import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// One demo in a section: the API's name, as it is written in code, above the
/// widget itself — so a reader knows what to call, not only what it looks like.
class DemoBlock extends StatelessWidget {
  const DemoBlock({required this.code, required this.child, super.key});

  /// The class or call to write, e.g. `AppButton(variant: …)`.
  final String code;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              code,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          12.heightBox,
          child,
        ],
      ),
    ),
  );
}
