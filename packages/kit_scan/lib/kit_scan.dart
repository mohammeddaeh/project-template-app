/// Codes from the live camera — registered behind `kit_contracts`. Printed
/// text is `kit_ocr`.
///
/// Installed with `dart run scripts/kit.dart add scan`; the app never imports
/// this file — `lib/core/di/kits.g.dart` does.
library;

import 'package:get_it/get_it.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'src/camera_code_scanner.dart';

void registerScanKit(GetIt getIt) {
  getIt.registerLazySingleton<CodeScanner>(CameraCodeScanner.new);
}
