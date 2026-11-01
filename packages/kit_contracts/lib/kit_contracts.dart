/// What the app knows of a device kit.
///
/// The app depends on this package and nothing else from `packages/`: a kit is
/// installed or removed with `dart run scripts/kit.dart`, and the app keeps
/// compiling either way. A screen asks `getIt.isRegistered<Contract>()` and
/// draws nothing when the kit is absent.
library;

export 'src/audio/audio_playback.dart';
export 'src/audio/audio_recorder.dart';
export 'src/kit_availability.dart';
export 'src/voice/speech_input.dart';
export 'src/voice/speech_output.dart';
