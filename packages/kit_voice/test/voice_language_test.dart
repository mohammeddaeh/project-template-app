import 'package:flutter_test/flutter_test.dart';
import 'package:kit_contracts/kit_contracts.dart';
import 'package:kit_voice/src/voice_language.dart';

void main() {
  group('pickLocale', () {
    const engine = ['en_US', 'ar_SA', 'ar_EG', 'fr_FR'];

    test('the first locale of the language', () {
      expect(pickLocale(engine, 'ar'), 'ar_SA');
      expect(pickLocale(engine, 'en'), 'en_US');
    });

    test("the device's own locale wins when it speaks the language", () {
      expect(pickLocale(engine, 'ar', preferred: 'ar_EG'), 'ar_EG');
      expect(pickLocale(engine, 'ar', preferred: 'en_US'), 'ar_SA');
    });

    test('both separators and any case', () {
      expect(pickLocale(['AR-sa'], 'ar'), 'AR-sa');
      expect(pickLocale(['ar'], 'ar'), 'ar');
    });

    test('a prefix of another language is not a match', () {
      // `ar` must not take `arn` (Mapudungun).
      expect(pickLocale(['arn_CL'], 'ar'), isNull);
    });

    test('an engine that lists nothing gets the bare code', () {
      expect(pickLocale([], 'ar'), 'ar');
    });
  });

  test('speech_to_text error codes', () {
    expect(speechFailureOf('error_no_match'), SpeechFailure.noMatch);
    expect(speechFailureOf('error_speech_timeout'), SpeechFailure.noMatch);
    expect(speechFailureOf('error_network'), SpeechFailure.network);
    expect(speechFailureOf('error_busy'), SpeechFailure.busy);
    expect(
      speechFailureOf('error_language_unavailable'),
      SpeechFailure.language,
    );
    expect(speechFailureOf('error_audio_error'), SpeechFailure.unknown);
  });
}
