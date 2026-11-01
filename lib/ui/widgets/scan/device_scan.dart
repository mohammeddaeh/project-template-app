import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/permissions/kit_readiness.dart';
import 'package:app_template/core/platform/permissions/permissions_service.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/feedback/kit_readiness_feedback.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/dialogs/app_bottom_sheet.dart';

/// The camera as an input — a code and paper pages through `kit_scan`,
/// printed text through `kit_ocr`. Each call asks for the camera itself and says why when it
/// cannot go on.
///
/// Check [canScanCodes] / [canScanDocuments] / [canReadText] before drawing
/// the button: without the kit there is nothing to call.
abstract final class DeviceScan {
  static bool get canScanCodes => getIt.isRegistered<CodeScanner>();
  static bool get canScanDocuments => getIt.isRegistered<DocumentScanner>();
  static bool get canReadText => getIt.isRegistered<TextRecognizer>();

  /// A sheet with the live camera — the first code read, or `null` when the
  /// sheet is closed.
  static Future<ScannedCode?> code(BuildContext context) async {
    final scanner = getIt<CodeScanner>();
    final readiness = await ensureKitReady(
      scanner.availability,
      getIt<PermissionsService>(),
    );
    if (!context.mounted) return null;
    if (readiness != KitReadiness.ready) {
      showKitReadiness(
        context,
        readiness,
        deniedKey: LocaleKeys.scanCameraDenied,
        blockedKey: LocaleKeys.scanCameraBlocked,
        unsupportedKey: LocaleKeys.scanUnsupported,
      );
      return null;
    }
    return AppBottomSheet.show<ScannedCode>(
      context,
      title: LocaleKeys.scanCodeTitle.tr(),
      isScrollable: false,
      child: _CodeScanView(session: scanner.open()),
    );
  }

  /// The platform's document scanner — page images in order, or `null`.
  ///
  /// ⚠️ The files are temporary: copy them into private storage at once, as
  /// with a captured photo (`PrivateFileIngestService.ingest`).
  static Future<List<String>?> document(
    BuildContext context, {
    int maxPages = 5,
  }) async {
    final scanner = getIt<DocumentScanner>();
    if (await scanner.availability() is! KitReady) {
      if (context.mounted) {
        context.feedback.warning(LocaleKeys.scanDocumentUnsupported.tr());
      }
      return null;
    }
    final result = await scanner.scan(maxPages: maxPages);
    if (!context.mounted) return null;
    switch (result) {
      case DocumentScanned(:final pages):
        return pages;
      case DocumentScanCancelled():
        return null;
      case DocumentScanFailed():
        context.feedback.warning(LocaleKeys.scanDocumentFailed.tr());
        return null;
    }
  }

  /// The printed text in an image — `null` when there is none or it could not
  /// be read, said to the user either way.
  ///
  /// ⚠️ Latin script only: Arabic text comes back empty or garbled.
  static Future<String?> text(BuildContext context, String imagePath) async {
    final text = await getIt<TextRecognizer>().read(imagePath);
    if (!context.mounted) return null;
    if (text == null) {
      context.feedback.warning(LocaleKeys.scanTextFailed.tr());
      return null;
    }
    if (text.trim().isEmpty) {
      context.feedback.info(LocaleKeys.scanTextEmpty.tr());
      return null;
    }
    return text;
  }
}

/// The camera in a square, a hint under it, a torch beside it; closes on the
/// first code.
class _CodeScanView extends StatefulWidget {
  const _CodeScanView({required this.session});

  final ScanSession session;

  @override
  State<_CodeScanView> createState() => _CodeScanViewState();
}

class _CodeScanViewState extends State<_CodeScanView> {
  late final StreamSubscription<ScannedCode> _codes;
  bool _torch = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _codes = widget.session.codes.listen((code) {
      if (_done || !mounted) return;
      _done = true;
      Navigator.of(context).pop(code);
    });
  }

  @override
  void dispose() {
    unawaited(_codes.cancel());
    unawaited(widget.session.dispose());
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await widget.session.setTorch(!_torch);
    if (mounted) setState(() => _torch = !_torch);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Square while it fits; smaller on a short or landscape screen, where a
        // full-width square is taller than the sheet.
        Flexible(
          child: Center(
            child: ClipRRect(
              borderRadius: AppRadius.lgRadius,
              child: AspectRatio(aspectRatio: 1, child: widget.session.preview),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                LocaleKeys.scanCodeHint.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            IconButton(
              tooltip:
                  (_torch ? LocaleKeys.scanTorchOff : LocaleKeys.scanTorchOn)
                      .tr(),
              onPressed: _toggleTorch,
              icon: Icon(
                _torch ? Icons.flashlight_off_outlined : Icons.flashlight_on,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
