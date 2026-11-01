import '../kit_availability.dart';

/// Text read aloud — reading content, accessibility.
///
/// Provided by `kit_voice`. Absent when the kit is not installed: ask
/// `getIt.isRegistered<SpeechOutput>()` before drawing a speaker.
abstract interface class SpeechOutput {
  Future<KitAvailability> availability();

  /// Reads [text] in [languageCode] and completes when reading ends — finished,
  /// stopped, or not started. One reading at a time: a new call stops the last.
  Future<SpeakOutcome> speak(String text, {required String languageCode});

  /// Stops the current reading; its [speak] completes with
  /// [SpeakOutcome.stopped].
  Future<void> stop();
}

enum SpeakOutcome {
  done,
  stopped,

  /// The device has no voice installed for the language.
  noVoice,
  failed,
}
