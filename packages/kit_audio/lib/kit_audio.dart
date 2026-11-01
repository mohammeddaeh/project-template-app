/// Audio recording and playback — registered behind `kit_contracts`.
///
/// Installed with `dart run scripts/kit.dart add audio`; the app never imports
/// this file — `lib/core/di/kits.g.dart` does.
library;

import 'package:get_it/get_it.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'src/just_audio_playback.dart';
import 'src/record_recorder.dart';

void registerAudioKit(GetIt getIt) {
  // One microphone, so one recorder.
  getIt.registerLazySingleton<AudioRecorder>(RecordRecorder.new);
  // A player per screen element — each owns its own and disposes it.
  getIt.registerFactory<AudioPlayback>(JustAudioPlayback.new);
}
