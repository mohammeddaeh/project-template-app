import 'package:flutter/widgets.dart';

import '../audio/audio_playback.dart';

/// One video player — an attachment opened, a clip in a page.
///
/// Provided by `kit_video` as a factory: every `getIt<VideoPlayback>()` is a
/// new player, owned by whoever asked and ended with [dispose]. Absent when the
/// kit is not installed.
abstract interface class VideoPlayback {
  /// Loads a file path or an `https` URL — its shape and length, or `null`
  /// when it cannot be played. Never throws.
  Future<VideoInfo?> open(String source);

  /// The picture, drawn by the platform. Fills the box it is given — the app
  /// sizes it with [VideoInfo.aspectRatio].
  Widget get surface;

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// Same shape as audio: where playback is, whether it plays, whether it
  /// reached the end.
  Stream<PlaybackState> get states;

  Future<void> dispose();
}

final class VideoInfo {
  const VideoInfo({required this.aspectRatio, required this.duration});

  /// Width over height, as displayed (rotation applied).
  final double aspectRatio;
  final Duration duration;
}
