import 'dart:developer' as developer;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'voice_language.dart';

/// [SpeechOutput] over `flutter_tts` — the platform's text-to-speech engine.
class FlutterTtsOutput implements SpeechOutput {
  FlutterTtsOutput([FlutterTts? engine]) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;
  bool _stopped = false;

  /// Reading needs no permission; a missing voice is answered per language by
  /// [speak] as [SpeakOutcome.noVoice].
  @override
  Future<KitAvailability> availability() async => const KitReady();

  @override
  Future<SpeakOutcome> speak(
    String text, {
    required String languageCode,
  }) async {
    try {
      if (!_configured) {
        // `speak` then completes when reading ends, not when it starts.
        await _tts.awaitSpeakCompletion(true);
        _configured = true;
      }
      await stop();
      final languages = await _tts.getLanguages;
      final language = pickLocale([
        if (languages is List) ...languages.whereType<String>(),
      ], languageCode);
      if (language == null ||
          await _tts.isLanguageAvailable(language) != true) {
        return SpeakOutcome.noVoice;
      }
      await _tts.setLanguage(language);
      _stopped = false;
      final result = await _tts.speak(text);
      if (_stopped) return SpeakOutcome.stopped;
      return result == 1 ? SpeakOutcome.done : SpeakOutcome.failed;
    } catch (e, s) {
      _log(e, s);
      return SpeakOutcome.failed;
    }
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    try {
      await _tts.stop();
    } catch (e, s) {
      _log(e, s);
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
