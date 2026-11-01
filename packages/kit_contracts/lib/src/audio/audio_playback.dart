/// One audio player — a voice note in a list, an attachment opened.
///
/// Provided by `kit_audio` as a factory: every `getIt<AudioPlayback>()` is a
/// new player, owned by whoever asked and ended with [dispose]. Absent when the
/// kit is not installed.
abstract interface class AudioPlayback {
  /// Loads a file path or an `https` URL — its length; [Duration.zero] when
  /// the file does not state one (it arrives later through [states]); `null`
  /// only when it cannot be played. Never throws.
  Future<Duration?> open(String source);

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// Where playback is, whether it is playing, and whether it reached the end.
  Stream<PlaybackState> get states;

  Future<void> dispose();
}

final class PlaybackState {
  const PlaybackState({
    required this.position,
    required this.playing,
    this.duration,
    this.completed = false,
  });

  final Duration position;
  final Duration? duration;
  final bool playing;

  /// Reached the end; [AudioPlayback.play] starts again from the start.
  final bool completed;
}
