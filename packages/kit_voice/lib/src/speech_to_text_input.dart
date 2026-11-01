import 'dart:async';
import 'dart:developer' as developer;

import 'package:kit_contracts/kit_contracts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'voice_language.dart';

/// [SpeechInput] over `speech_to_text` — the platform recogniser (Google on
/// Android, Apple's on iOS).
class SpeechToTextInput implements SpeechInput {
  SpeechToTextInput([SpeechToText? engine]) : _stt = engine ?? SpeechToText();

  final SpeechToText _stt;
  bool _initialized = false;
  StreamController<SpeechEvent>? _session;

  /// `initialize` asks for the permissions itself when they are missing, so it
  /// runs only after [availability] has seen them granted — the app asks, not
  /// the kit. A failed attempt is retried next time: it fails before the grant.
  Future<bool> _init() async {
    if (_initialized) return true;
    try {
      _initialized = await _stt.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
    } catch (e, s) {
      _log(e, s);
      _initialized = false;
    }
    return _initialized;
  }

  @override
  Future<KitAvailability> availability() async {
    try {
      if (!await _stt.hasPermission) {
        return const KitNeedsPermission([
          KitPermission.microphone,
          KitPermission.speechRecognition,
        ]);
      }
      return await _init() ? const KitReady() : const KitUnsupported();
    } catch (e, s) {
      _log(e, s);
      return const KitUnsupported();
    }
  }

  @override
  Stream<SpeechEvent> listen({required String languageCode}) {
    _end(_session);
    final session = StreamController<SpeechEvent>();
    _session = session;
    unawaited(_start(session, languageCode));
    return session.stream;
  }

  Future<void> _start(
    StreamController<SpeechEvent> session,
    String languageCode,
  ) async {
    try {
      if (!await _init()) {
        return _fail(session, SpeechFailure.unknown);
      }
      final locales = await _stt.locales();
      final system = await _stt.systemLocale();
      final localeId = pickLocale(
        [for (final l in locales) l.localeId],
        languageCode,
        preferred: system?.localeId,
      );
      if (localeId == null) return _fail(session, SpeechFailure.language);
      if (session.isClosed) return;
      await _stt.listen(
        onResult: (r) {
          if (session.isClosed) return;
          session.add(SpeechHeard(r.recognizedWords, isFinal: r.finalResult));
          if (r.finalResult) _end(session);
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (e, s) {
      _log(e, s);
      _fail(session, SpeechFailure.unknown);
    }
  }

  void _onError(SpeechRecognitionError error) {
    final session = _session;
    if (session != null) _fail(session, speechFailureOf(error.errorMsg));
  }

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus) _end(_session);
  }

  void _fail(StreamController<SpeechEvent> session, SpeechFailure reason) {
    if (!session.isClosed) session.add(SpeechFailed(reason));
    _end(session);
  }

  void _end(StreamController<SpeechEvent>? session) {
    if (session == null) return;
    if (!session.isClosed) unawaited(session.close());
    if (identical(_session, session)) _session = null;
  }

  @override
  Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (e, s) {
      _log(e, s);
      _end(_session);
    }
  }
}

/// No exception crosses the kit's boundary, and none disappears either: the
/// app's log service is out of reach here, so the platform log carries it.
void _log(Object error, StackTrace stack) => developer.log(
  'kit_voice',
  name: 'kit_voice',
  error: error,
  stackTrace: stack,
);
