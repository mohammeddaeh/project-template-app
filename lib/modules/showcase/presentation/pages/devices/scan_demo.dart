import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/media/media_service.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/kit_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `kit_scan` — a code from the live camera — and `kit_ocr`, the printed text
/// of an image.
class ScanDemo extends StatefulWidget {
  const ScanDemo({super.key});

  @override
  State<ScanDemo> createState() => _ScanDemoState();
}

class _ScanDemoState extends State<ScanDemo> {
  ScannedCode? _code;
  String? _text;

  Future<void> _scanCode() async {
    final code = await DeviceScan.code(context);
    if (code != null && mounted) setState(() => _code = code);
  }

  Future<void> _readText() async {
    final image = await getIt<MediaService>().pickFromGallery();
    if (image == null || !mounted) return;
    final text = await DeviceScan.text(context, image.path);
    if (text != null && mounted) setState(() => _text = text);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final muted = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textMuted,
    );
    final code = _code;
    final text = _text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitNotice(kit: 'scan', installed: DeviceScan.canScanCodes),
        DemoBlock(
          code: 'final code = await DeviceScan.code(context);',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                text: LocaleKeys.showcaseScanCode.tr(),
                leadingIcon: Icons.qr_code_scanner,
                isEnabled: DeviceScan.canScanCodes,
                onTap: _scanCode,
              ),
              8.heightBox,
              code == null
                  ? Text(LocaleKeys.showcaseScanNothing.tr(), style: muted)
                  : SelectableText(
                      '${code.format.name} · ${code.value}',
                      textDirection: TextDirection.ltr,
                      style: context.textTheme.bodyMedium,
                    ),
            ],
          ),
        ),
        DemoBlock(
          code: 'final text = await DeviceScan.text(context, image.path);',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KitNotice(kit: 'ocr', installed: DeviceScan.canReadText),
              AppButton(
                text: LocaleKeys.showcaseScanText.tr(),
                variant: AppButtonVariant.tonal,
                leadingIcon: Icons.text_fields,
                isEnabled: DeviceScan.canReadText,
                onTap: _readText,
              ),
              8.heightBox,
              text == null
                  ? Text(LocaleKeys.showcaseScanNothing.tr(), style: muted)
                  : SelectableText(
                      text,
                      textDirection: TextDirection.ltr,
                      style: context.textTheme.bodySmall,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
