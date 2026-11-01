import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart'
    as mlkit;
import 'package:kit_contracts/kit_contracts.dart';

import 'kit_log.dart';

/// [DocumentScanner] over ML Kit's document scanner — Google's own screen,
/// delivered by Play services. Android only.
class MlkitDocumentScanner implements DocumentScanner {
  @override
  Future<KitAvailability> availability() async =>
      Platform.isAndroid ? const KitReady() : const KitUnsupported();

  @override
  Future<DocumentScanResult> scan({int maxPages = 5}) async {
    final scanner = mlkit.DocumentScanner(
      options: mlkit.DocumentScannerOptions(
        pageLimit: maxPages,
        mode: mlkit.ScannerMode.full,
        isGalleryImport: true,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      final pages = result.images ?? const <String>[];
      return pages.isEmpty
          ? const DocumentScanCancelled()
          : DocumentScanned(pages);
    } on PlatformException catch (e, s) {
      // The plugin reports a back-out as an error, not as an empty result.
      if (documentScanCancelled(e.message)) {
        return const DocumentScanCancelled();
      }
      kitLog(e, s);
      return const DocumentScanFailed();
    } catch (e, s) {
      kitLog(e, s);
      return const DocumentScanFailed();
    } finally {
      await scanner.close();
    }
  }
}

/// The plugin's message for the user closing the scanner.
bool documentScanCancelled(String? message) =>
    message?.toLowerCase().contains('cancel') ?? false;
