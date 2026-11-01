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
