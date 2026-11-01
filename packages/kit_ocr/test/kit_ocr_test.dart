import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_contracts/kit_contracts.dart';
import 'package:kit_ocr/kit_ocr.dart';

void main() {
  test('registers the text recognizer, and nothing else', () {
    final getIt = GetIt.asNewInstance();
    registerOcrKit(getIt);
    expect(getIt.isRegistered<TextRecognizer>(), isTrue);
    expect(getIt.isRegistered<CodeScanner>(), isFalse);
  });
}
