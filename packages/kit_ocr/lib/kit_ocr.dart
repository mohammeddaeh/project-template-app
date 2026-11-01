/// Printed text read from an image, on the device — registered behind
/// `kit_contracts`.
///
/// A kit of its own because its model is most of `kit_scan`'s weight: a
/// project that scans codes does not carry it. Installed with
/// `dart run scripts/kit.dart add ocr`; the app never imports this file —
/// `lib/core/di/kits.g.dart` does.
library;

import 'package:get_it/get_it.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'src/mlkit_text_recognizer.dart';

void registerOcrKit(GetIt getIt) {
  getIt.registerLazySingleton<TextRecognizer>(MlkitTextRecognizer.new);
}
