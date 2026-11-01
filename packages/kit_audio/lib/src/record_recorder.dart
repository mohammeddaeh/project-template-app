import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:kit_contracts/kit_contracts.dart' as kit;
import 'package:record/record.dart';

import 'audio_level.dart';

/// [kit.AudioRecorder] over `record` — AAC into an `.m4a` file.
class RecordRecorder implements kit.AudioRecorder {
  RecordRecorder([AudioRecorder? engine]) : _rec = engine ?? AudioRecorder();

  final AudioRecorder _rec;
  final _clock = Stopwatch();
  String? _path;

  @override
  Future<kit.KitAvailability> availability() async {
    try {
      // `request: false` — the app asks through its own permission service.
      return await _rec.hasPermission(request: false)
          ? const kit.KitReady()
          : const kit.KitNeedsPermission([kit.KitPermission.microphone]);
    } catch (e, s) {
      _log(e, s);
      return const kit.KitUnsupported();
    }
  }

  @override
  Future<bool> start(String path) async {
    try {
      if (await _rec.isRecording()) return false;
      await _rec.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _path = path;
      _clock
        ..reset()
        ..start();
      return true;
    } catch (e, s) {
      _log(e, s);
      return false;
    }
  }

  @override
  Stream<double> get levels => _rec
      .onAmplitudeChanged(const Duration(milliseconds: 120))
      .map((a) => levelOfDbfs(a.current));

  @override
  Future<kit.Recording?> stop() async {
    _clock.stop();
    try {
      final path = await _rec.stop() ?? _path;
      _path = null;
      if (path == null || !File(path).existsSync()) return null;
      return kit.Recording(path: path, duration: _clock.elapsed);
    } catch (e, s) {
      _log(e, s);
      return null;
    }
  }

  @override
  Future<void> cancel() async {
    _clock.stop();
    try {
      // `cancel` stops and deletes the file itself.
      await _rec.cancel();
    } catch (e, s) {
      _log(e, s);
    }
    _path = null;
  }
}

/// No exception crosses the kit's boundary, and none disappears either: the
/// app's log service is out of reach here, so the platform log carries it.
void _log(Object error, StackTrace stack) => developer.log(
  'kit_audio',
  name: 'kit_audio',
  error: error,
  stackTrace: stack,
);
