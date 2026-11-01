import 'package:kit_contracts/kit_contracts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

CodeFormat codeFormatOf(BarcodeFormat format) => switch (format) {
  BarcodeFormat.qrCode => CodeFormat.qr,
  BarcodeFormat.dataMatrix => CodeFormat.dataMatrix,
  BarcodeFormat.pdf417 => CodeFormat.pdf417,
  BarcodeFormat.aztec => CodeFormat.aztec,
  BarcodeFormat.ean13 => CodeFormat.ean13,
  BarcodeFormat.ean8 => CodeFormat.ean8,
  BarcodeFormat.upcA => CodeFormat.upcA,
  BarcodeFormat.upcE => CodeFormat.upcE,
  BarcodeFormat.code128 => CodeFormat.code128,
  BarcodeFormat.code39 => CodeFormat.code39,
  BarcodeFormat.code93 => CodeFormat.code93,
  BarcodeFormat.codabar => CodeFormat.codabar,
  BarcodeFormat.itf14 => CodeFormat.itf,
  _ => CodeFormat.other,
};
