import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/kit_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `kit_scan` — a code from the live camera and paper pages through the
/// platform's scanner — and `kit_ocr`, the printed text of a page.
class ScanDemo extends StatefulWidget {
  const ScanDemo({super.key});

  @override
  State<ScanDemo> createState() => _ScanDemoState();
}

class _ScanDemoState extends State<ScanDemo> {
  ScannedCode? _code;
  List<String> _pages = const [];
  String? _text;

  Future<void> _scanCode() async {
    final code = await DeviceScan.code(context);
    if (code != null && mounted) setState(() => _code = code);
  }

  Future<void> _scanDocument() async {
    final pages = await DeviceScan.document(context, maxPages: 3);
    if (pages != null && mounted) {
      setState(() {
        _pages = pages;
        _text = null;
      });
    }
  }

  Future<void> _readText() async {
    final text = await DeviceScan.text(context, _pages.first);
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
          code: 'final pages = await DeviceScan.document(context);',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                text: LocaleKeys.showcaseScanDocument.tr(),
                variant: AppButtonVariant.tonal,
                leadingIcon: Icons.document_scanner_outlined,
                isEnabled: DeviceScan.canScanDocuments,
                onTap: _scanDocument,
              ),
              if (_pages.isNotEmpty) ...[
                8.heightBox,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final page in _pages)
                      SizedBox.square(
                        dimension: 96,
                        child: CapturedPhotoTile(
                          photo: CapturedPhoto(
                            localPath: page,
                            mimeType: 'image/jpeg',
                          ),
                          showMeta: false,
                          onTap: () => AttachmentPreview.open(
                            context,
                            photo: CapturedPhoto(
                              localPath: page,
                              mimeType: 'image/jpeg',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (_pages.isNotEmpty)
          DemoBlock(
            code: 'final text = await DeviceScan.text(context, pages.first);',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitNotice(kit: 'ocr', installed: DeviceScan.canReadText),
                AppButton(
                  text: LocaleKeys.showcaseScanText.tr(),
                  isEnabled: DeviceScan.canReadText,
                  variant: AppButtonVariant.outlined,
                  leadingIcon: Icons.text_fields,
                  onTap: _readText,
                ),
                if (text != null) ...[
                  8.heightBox,
                  SelectableText(
                    text,
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
