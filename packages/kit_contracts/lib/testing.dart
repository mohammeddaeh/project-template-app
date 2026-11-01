/// Fakes of every kit contract — the app's tests register these and never touch
/// a platform package.
library;

import 'dart:async';

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
