import 'package:flutter/widgets.dart';

import '../kit_availability.dart';

/// QR codes and barcodes read from the live camera.
///
/// Provided by `kit_scan`. Absent when the kit is not installed: ask
/// `getIt.isRegistered<CodeScanner>()` before offering a scan.
abstract interface class CodeScanner {
  /// Asks for nothing — a missing camera permission comes back as
  /// [KitNeedsPermission] for the app to request.
  Future<KitAvailability> availability();

  /// A live camera session — the app places [ScanSession.preview] and listens
  /// to [ScanSession.codes]. One at a time; the owner disposes it.
  ScanSession open();
}

abstract interface class ScanSession {
  /// The camera picture, drawn by the platform. Fills the box it is given.
  Widget get preview;

  /// Every code the camera reads — the same code again while it stays in view.
  Stream<ScannedCode> get codes;

  Future<void> setTorch(bool on);

  Future<void> dispose();
}

final class ScannedCode {
  const ScannedCode(this.value, this.format);

  /// The decoded text — a URL, an identifier, a payload.
  final String value;
  final CodeFormat format;
}

enum CodeFormat {
  qr,
  dataMatrix,
  pdf417,
  aztec,
  ean13,
  ean8,
  upcA,
  upcE,
  code128,
  code39,
  code93,
  codabar,
  itf,
  other,
}
