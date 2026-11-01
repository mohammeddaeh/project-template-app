import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kit_contracts/kit_contracts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'code_format.dart';
import 'kit_log.dart';

/// [CodeScanner] over `mobile_scanner` — ML Kit barcode reading on a CameraX
/// (Android) or AVFoundation (iOS) preview.
class CameraCodeScanner implements CodeScanner {
  @override
  Future<KitAvailability> availability() async {
    try {
      // Read, never requested: `mobile_scanner` would prompt on start, and
      // the app asks through its own permission service first.
      return await Permission.camera.isGranted
          ? const KitReady()
          : const KitNeedsPermission([KitPermission.camera]);
    } catch (e, s) {
      kitLog(e, s);
      return const KitUnsupported();
    }
  }

  @override
  ScanSession open() => _CameraSession();
}

class _CameraSession implements ScanSession {
  _CameraSession() {
    _subscription = _controller.barcodes.listen((capture) {
      for (final b in capture.barcodes) {
        final value = b.rawValue;
        if (value != null && value.isNotEmpty && !_codes.isClosed) {
          _codes.add(ScannedCode(value, codeFormatOf(b.format)));
        }
      }
    });
  }

  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _codes = StreamController<ScannedCode>.broadcast();
  late final StreamSubscription<BarcodeCapture> _subscription;
  bool _torch = false;

  @override
  Widget get preview => MobileScanner(controller: _controller);

  @override
  Stream<ScannedCode> get codes => _codes.stream;

  @override
  Future<void> setTorch(bool on) async {
    if (on == _torch) return;
    try {
      await _controller.toggleTorch();
      _torch = on;
    } catch (e, s) {
      kitLog(e, s);
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await _codes.close();
    try {
      await _controller.dispose();
    } catch (e, s) {
      kitLog(e, s);
    }
  }
}
