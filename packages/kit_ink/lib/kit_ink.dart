/// Handwriting recognition — registered behind `kit_contracts`.
///
/// Installed with `dart run scripts/kit.dart add ink`; the app never imports
/// this file — `lib/core/di/kits.g.dart` does. Drawing (and signatures) needs
/// no kit: that is the app's own `SignaturePad`.
library;

import 'package:get_it/get_it.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'src/mlkit_ink_recognizer.dart';

void registerInkKit(GetIt getIt) {
  getIt.registerLazySingleton<InkRecognizer>(MlkitInkRecognizer.new);
}
