import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as mlkit;
import 'package:kit_contracts/kit_contracts.dart';

import 'kit_log.dart';

/// [TextRecognizer] over ML Kit's on-device Latin model.
class MlkitTextRecognizer implements TextRecognizer {
  @override
  Future<KitAvailability> availability() async => const KitReady();

  @override
  Future<String?> read(String imagePath) async {
    final recognizer = mlkit.TextRecognizer(
      script: mlkit.TextRecognitionScript.latin,
    );
    try {
      final result = await recognizer.processImage(
        mlkit.InputImage.fromFilePath(imagePath),
      );
      return result.text;
    } catch (e, s) {
      kitLog(e, s);
      return null;
    } finally {
      await recognizer.close();
    }
  }
}
