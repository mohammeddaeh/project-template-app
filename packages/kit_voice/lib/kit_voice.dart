/// Speech to text and text to speech — registered behind `kit_contracts`.
///
/// Installed with `dart run scripts/kit.dart add voice`; the app never imports
/// this file — `lib/core/di/kits.g.dart` does.
library;

import 'package:get_it/get_it.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'src/flutter_tts_output.dart';
import 'src/speech_to_text_input.dart';

void registerVoiceKit(GetIt getIt) {
  getIt.registerLazySingleton<SpeechInput>(SpeechToTextInput.new);
  getIt.registerLazySingleton<SpeechOutput>(FlutterTtsOutput.new);
}
