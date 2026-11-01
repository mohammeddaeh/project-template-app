import 'dart:async';
import 'dart:developer' as developer;

import 'package:just_audio/just_audio.dart';
import 'package:kit_contracts/kit_contracts.dart';

/// [AudioPlayback] over `just_audio` — one player per instance.
class JustAudioPlayback implements AudioPlayback {
  JustAudioPlayback([AudioPlayer? engine]) : _player = engine ?? AudioPlayer() {
    _subscriptions = [
      _player.positionStream.listen((_) => _emit()),
      _player.playerStateStream.listen((_) => _emit()),
      _player.durationStream.listen((_) => _emit()),
    ];
  }

  final AudioPlayer _player;
  late final List<StreamSubscription<Object?>> _subscriptions;
  final _states = StreamController<PlaybackState>.broadcast();

  void _emit() {
    if (_states.isClosed) return;
    final state = _player.playerState;
    final completed = state.processingState == ProcessingState.completed;
    _states.add(
      PlaybackState(
        position: _player.position,
        duration: _player.duration,
        playing: state.playing && !completed,
        completed: completed,
      ),
    );
  }

  @override
  Future<Duration?> open(String source) async {
    try {
      final uri = Uri.tryParse(source);
      final length =
          uri != null && (uri.scheme == 'https' || uri.scheme == 'http')
          ? await _player.setUrl(source)
          : await _player.setFilePath(source);
      // A fresh recording's header may not state its length; the player learns
      // it while playing. Loaded is loaded — failure is the exception below.
      return length ?? Duration.zero;
    } catch (e, s) {
      _log(e, s);
      return null;
    }
  }

  @override
  Future<void> play() async {
    try {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      // `play` completes when playback stops, not when it starts.
      unawaited(_player.play());
    } catch (e, s) {
      _log(e, s);
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e, s) {
      _log(e, s);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e, s) {
      _log(e, s);
    }
  }

  @override
  Stream<PlaybackState> get states => _states.stream;

  @override
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _states.close();
    try {
      await _player.dispose();
    } catch (e, s) {
      _log(e, s);
    }
  }
}

void _log(Object error, StackTrace stack) => developer.log(
  'kit_audio',
  name: 'kit_audio',
  error: error,
  stackTrace: stack,
);
