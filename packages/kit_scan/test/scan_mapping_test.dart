import 'package:flutter_test/flutter_test.dart';
import 'package:kit_contracts/kit_contracts.dart';
import 'package:kit_scan/src/code_format.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  test('every barcode format maps, the rest to other', () {
    expect(codeFormatOf(BarcodeFormat.qrCode), CodeFormat.qr);
    expect(codeFormatOf(BarcodeFormat.ean13), CodeFormat.ean13);
    expect(codeFormatOf(BarcodeFormat.itf14), CodeFormat.itf);
    expect(codeFormatOf(BarcodeFormat.unknown), CodeFormat.other);
  });
}
