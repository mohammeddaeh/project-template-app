import '../kit_availability.dart';

/// Speech turned into text — dictation into a field, a spoken search.
///
/// Provided by `kit_voice`. Absent when the kit is not installed: ask
/// `getIt.isRegistered<SpeechInput>()` before drawing a microphone.
abstract interface class SpeechInput {
  /// Whether listening can start now. Asks for nothing — a missing permission
  /// comes back as [KitNeedsPermission] for the app to request.
  Future<KitAvailability> availability();

  /// Listens in [languageCode] (`ar` · `en`) until the speaker pauses or
  /// [stop] is called; the stream closes when listening ends.
  ///
  /// Partial results arrive as the words are heard, each replacing the last —
  /// the final one has [SpeechHeard.isFinal] set. A failure arrives as
  /// [SpeechFailed] and closes the stream; nothing is thrown.
  Stream<SpeechEvent> listen({required String languageCode});

  /// Ends listening early; the words heard so far arrive as the final result.
  Future<void> stop();
}

sealed class SpeechEvent {
  const SpeechEvent();
}

/// The words heard so far in this session.
final class SpeechHeard extends SpeechEvent {
  const SpeechHeard(this.text, {required this.isFinal});

  final String text;
  final bool isFinal;
}

final class SpeechFailed extends SpeechEvent {
  const SpeechFailed(this.reason);

  final SpeechFailure reason;
}

enum SpeechFailure {
  /// Nothing recognisable was said before the pause.
  noMatch,

  /// The recogniser needs the network and has none.
  network,

  /// Another app holds the recogniser.
  busy,

  /// The device has no recogniser for the requested language.
  language,

  unknown,
}
