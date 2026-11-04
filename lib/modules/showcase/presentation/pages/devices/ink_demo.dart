import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/kit_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// A signature drawn and saved as an image (no kit), and handwriting turned
/// into text (`kit_ink`).
class InkDemo extends StatefulWidget {
  const InkDemo({super.key});

  @override
  State<InkDemo> createState() => _InkDemoState();
}

class _InkDemoState extends State<InkDemo> {
  final _signature = InkController();
  Uint8List? _png;
  String _written = '';

  @override
  void dispose() {
    _signature.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final png = await _signature.toPng(color: context.colors.textPrimary);
    if (mounted) setState(() => _png = png);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final png = _png;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code:
              'SignaturePad(controller: ink, hint: …)\n'
              'final png = await ink.toPng(color: …);',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SignaturePad(
                controller: _signature,
                hint: LocaleKeys.showcaseSignatureHint.tr(),
              ),
              const ResponsiveGap(8),
              AppButton(
                text: LocaleKeys.showcaseSignatureSave.tr(),
                variant: AppButtonVariant.outlined,
                leadingIcon: Icons.draw_outlined,
                onTap: _save,
              ),
              if (png != null) ...[
                const ResponsiveGap(8),
                SizedBox(
                  height: context.screen.size(96),
                  child: CapturedPhotoImage(
                    photo: CapturedPhoto(bytes: png, mimeType: 'image/png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ],
          ),
        ),
        KitNotice(kit: 'ink', installed: getIt.isRegistered<InkRecognizer>()),
        DemoBlock(
          code: 'HandwritingInput(onText: (t) => controller.text += t)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HandwritingInput(
                onText: (t) => setState(
                  () => _written = _written.isEmpty ? t : '$_written $t',
                ),
              ),
              if (_written.isNotEmpty) ...[
                const ResponsiveGap(8),
                Text(
                  '${LocaleKeys.showcaseInkResult.tr()} $_written',
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
