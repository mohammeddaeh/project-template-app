/// Fakes of every kit contract — the app's tests register these and never touch
/// a platform package.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'kit_contracts.dart';

/// Plays back the [script] it is given on [listen].
class FakeSpeechInput implements SpeechInput {
  FakeSpeechInput({this.answer = const KitReady(), this.script = const []});

  KitAvailability answer;
  List<SpeechEvent> script;
  String? lastLanguage;
  bool stopped = false;

  @override
  Future<KitAvailability> availability() async => answer;

  @override
  Stream<SpeechEvent> listen({required String languageCode}) {
    lastLanguage = languageCode;
    return Stream.fromIterable(script);
  }

  @override
  Future<void> stop() async => stopped = true;
}

/// Records what it was asked to read; [speak] completes when [finish] is
/// called (or at once with [outcome] when [holdUntilFinished] is false).
class FakeSpeechOutput implements SpeechOutput {
  FakeSpeechOutput({
    this.answer = const KitReady(),
    this.outcome = SpeakOutcome.done,
    this.holdUntilFinished = false,
  });

  KitAvailability answer;
  SpeakOutcome outcome;
  bool holdUntilFinished;
  final spoken = <String>[];
  Completer<SpeakOutcome>? _current;

  @override
  Future<KitAvailability> availability() async => answer;

  @override
  Future<SpeakOutcome> speak(String text, {required String languageCode}) {
    spoken.add(text);
    if (!holdUntilFinished) return Future.value(outcome);
    _current = Completer<SpeakOutcome>();
    return _current!.future;
  }

  /// Ends a held reading.
  void finish([SpeakOutcome? result]) => _current?.complete(result ?? outcome);

  @override
  Future<void> stop() async {
    final c = _current;
    _current = null;
    if (c != null && !c.isCompleted) c.complete(SpeakOutcome.stopped);
  }
}

/// Records nothing: [stop] answers [result], and [levels] plays [levelScript].
class FakeAudioRecorder implements AudioRecorder {
  FakeAudioRecorder({
    this.answer = const KitReady(),
    this.result,
    this.levelScript = const [],
  });

  KitAvailability answer;
  Recording? result;
  List<double> levelScript;
  String? startedAt;
  bool cancelled = false;

  @override
  Future<KitAvailability> availability() async => answer;

  @override
  Future<bool> start(String path) async {
    startedAt = path;
    return true;
  }

  @override
  Stream<double> get levels => Stream.fromIterable(levelScript);

  @override
  Future<Recording?> stop() async => result;

  @override
  Future<void> cancel() async => cancelled = true;
}

/// A player that moves only when told: [emit] pushes a state, [length] is
/// what [open] answers.
class FakeAudioPlayback implements AudioPlayback {
  FakeAudioPlayback({this.length = const Duration(seconds: 30)});

  Duration? length;
  String? opened;
  bool playing = false;
  bool disposed = false;
  Duration? seekedTo;
  final _states = StreamController<PlaybackState>.broadcast();

  void emit(PlaybackState state) => _states.add(state);

  @override
  Future<Duration?> open(String source) async {
    opened = source;
    return length;
  }

  @override
  Future<void> play() async {
    playing = true;
    emit(
      PlaybackState(position: Duration.zero, duration: length, playing: true),
    );
  }

  @override
  Future<void> pause() async {
    playing = false;
    emit(
      PlaybackState(position: Duration.zero, duration: length, playing: false),
    );
  }

  @override
  Future<void> seek(Duration position) async => seekedTo = position;

  @override
  Stream<PlaybackState> get states => _states.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _states.close();
  }
}

/// A camera that reads what [FakeScanSession.read] is given.
class FakeCodeScanner implements CodeScanner {
  FakeCodeScanner({this.answer = const KitReady()});

  KitAvailability answer;
  FakeScanSession? session;

  @override
  Future<KitAvailability> availability() async => answer;

  @override
  ScanSession open() => session = FakeScanSession();
}

class FakeScanSession implements ScanSession {
  final _codes = StreamController<ScannedCode>.broadcast();
  bool torch = false;
  bool disposed = false;

  void read(String value, [CodeFormat format = CodeFormat.qr]) =>
      _codes.add(ScannedCode(value, format));

  @override
  Widget get preview => const SizedBox.expand(key: Key('fake-camera'));

  @override
  Stream<ScannedCode> get codes => _codes.stream;

  @override
  Future<void> setTorch(bool on) async => torch = on;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _codes.close();
  }
}

class FakeTextRecognizer implements TextRecognizer {
  FakeTextRecognizer({this.answer = const KitReady(), this.text = ''});

  KitAvailability answer;
  String? text;
  String? readFrom;

  @override
  Future<KitAvailability> availability() async => answer;

  @override
  Future<String?> read(String imagePath) async {
    readFrom = imagePath;
    return text;
  }
}

/// A video player that moves only when told, like [FakeAudioPlayback].
class FakeVideoPlayback implements VideoPlayback {
  FakeVideoPlayback({
    this.info = const VideoInfo(
      aspectRatio: 16 / 9,
      duration: Duration(seconds: 12),
    ),
  });

  VideoInfo? info;
  String? opened;
  bool playing = false;
  bool disposed = false;
  final _states = StreamController<PlaybackState>.broadcast();

  void emit(PlaybackState state) => _states.add(state);

  @override
  Future<VideoInfo?> open(String source) async {
    opened = source;
    return info;
  }

  @override
  Widget get surface => const SizedBox.expand(key: Key('fake-video'));

  @override
  Future<void> play() async {
    playing = true;
    emit(
      PlaybackState(
        position: Duration.zero,
        duration: info?.duration,
        playing: true,
      ),
    );
  }

  @override
  Future<void> pause() async {
    playing = false;
    emit(
      PlaybackState(
        position: Duration.zero,
        duration: info?.duration,
        playing: false,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Stream<PlaybackState> get states => _states.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _states.close();
  }
}
