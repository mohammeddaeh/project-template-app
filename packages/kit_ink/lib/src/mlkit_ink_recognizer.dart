import 'dart:developer' as developer;

import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;
import 'package:kit_contracts/kit_contracts.dart';

/// [InkRecognizer] over ML Kit digital ink recognition.
class MlkitInkRecognizer implements InkRecognizer {
  final _models = mlkit.DigitalInkRecognizerModelManager();

  @override
  Future<KitAvailability> availability() async => const KitReady();

  @override
  Future<bool> hasModel(String languageCode) async {
    try {
      return await _models.isModelDownloaded(languageCode);
    } catch (e, s) {
      _log(e, s);
      return false;
    }
  }

  @override
  Future<bool> downloadModel(String languageCode) async {
    try {
      // Any network, not only Wi-Fi: the user asked for it just now.
      return await _models.downloadModel(languageCode, isWifiRequired: false);
    } catch (e, s) {
      _log(e, s);
      return false;
    }
  }

  @override
  Future<List<String>?> recognize(
    List<InkStroke> strokes, {
    required String languageCode,
  }) async {
    final recognizer = mlkit.DigitalInkRecognizer(languageCode: languageCode);
    try {
      final candidates = await recognizer.recognize(toMlkitInk(strokes));
      return [for (final c in candidates) c.text];
    } catch (e, s) {
      _log(e, s);
      return null;
    } finally {
      await recognizer.close();
    }
  }
}

mlkit.Ink toMlkitInk(List<InkStroke> strokes) {
  final ink = mlkit.Ink();
  for (final stroke in strokes) {
    final s = mlkit.Stroke();
    for (final p in stroke.points) {
      s.points.add(mlkit.StrokePoint(x: p.x, y: p.y, t: p.time));
    }
    if (s.points.isNotEmpty) ink.strokes.add(s);
  }
  return ink;
}

/// No exception crosses the kit's boundary, and none disappears either: the
/// app's log service is out of reach here, so the platform log carries it.
void _log(Object error, StackTrace stack) =>
    developer.log('kit_ink', name: 'kit_ink', error: error, stackTrace: stack);
