import '../kit_availability.dart';

/// The microphone recorded to a file — a voice note, a spoken report.
///
/// Provided by `kit_audio`. Absent when the kit is not installed: ask
/// `getIt.isRegistered<AudioRecorder>()` before drawing a record button.
abstract interface class AudioRecorder {
  /// Whether recording can start now. Asks for nothing — a missing permission
  /// comes back as [KitNeedsPermission] for the app to request.
  Future<KitAvailability> availability();

  /// Starts recording AAC into [path] (`.m4a`). `false` when it could not
  /// start — another recording running, the microphone taken.
  ///
  /// [path] is the app's to choose and to keep: a temporary file the caller
  /// copies into private storage once [stop] returns, like any captured file.
  Future<bool> start(String path);

  /// The input level while recording, `0`–`1`, a few times a second.
  Stream<double> get levels;

  /// Ends the recording — its file and length, or `null` when nothing was
  /// recorded.
  Future<Recording?> stop();

  /// Ends the recording and deletes its file.
  Future<void> cancel();
}

final class Recording {
  const Recording({required this.path, required this.duration});

  final String path;
  final Duration duration;

  /// What [AudioRecorder.start] writes — AAC in an MPEG-4 container.
  static const mimeType = 'audio/mp4';
}
