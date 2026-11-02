import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:kit_contracts/kit_contracts.dart';
import 'package:video_player/video_player.dart';

/// [VideoPlayback] over `video_player` — ExoPlayer (Android), AVPlayer (iOS).
class VideoPlayerPlayback implements VideoPlayback {
  VideoPlayerController? _controller;
  final _states = StreamController<PlaybackState>.broadcast();

  void _emit() {
    final c = _controller;
    if (c == null || _states.isClosed) return;
    final v = c.value;
    final completed = v.isCompleted;
    _states.add(
      PlaybackState(
        position: v.position,
        duration: v.duration,
        playing: v.isPlaying && !completed,
        completed: completed,
      ),
    );
  }

  @override
  Future<VideoInfo?> open(String source) async {
    await _release();
    final uri = Uri.tryParse(source);
    final controller =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http')
        ? VideoPlayerController.networkUrl(uri)
        : VideoPlayerController.file(File(source));
    try {
      await controller.initialize();
      controller.addListener(_emit);
      _controller = controller;
      final v = controller.value;
      return VideoInfo(aspectRatio: v.aspectRatio, duration: v.duration);
    } catch (e, s) {
      _log(e, s);
      await controller.dispose();
      return null;
    }
  }

  @override
  Widget get surface {
    final c = _controller;
    return c == null ? const SizedBox.expand() : VideoPlayer(c);
  }

  @override
  Future<void> play() async {
    final c = _controller;
    if (c == null) return;
    try {
      if (c.value.isCompleted) await c.seekTo(Duration.zero);
      await c.play();
    } catch (e, s) {
      _log(e, s);
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _controller?.pause();
    } catch (e, s) {
      _log(e, s);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _controller?.seekTo(position);
    } catch (e, s) {
      _log(e, s);
    }
  }

  @override
  Stream<PlaybackState> get states => _states.stream;

  Future<void> _release() async {
    final c = _controller;
    _controller = null;
    if (c == null) return;
    c.removeListener(_emit);
    try {
      await c.dispose();
    } catch (e, s) {
      _log(e, s);
    }
  }

  @override
  Future<void> dispose() async {
    await _release();
    await _states.close();
  }
}

/// No exception crosses the kit's boundary, and none disappears either: the
/// app's log service is out of reach here, so the platform log carries it.
void _log(Object error, StackTrace stack) => developer.log(
  'kit_video',
  name: 'kit_video',
  error: error,
  stackTrace: stack,
);
