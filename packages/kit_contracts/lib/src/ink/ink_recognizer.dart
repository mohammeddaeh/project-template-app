import '../kit_availability.dart';

/// Handwriting turned into text, on the device — a finger or stylus writing in
/// a box instead of typing.
///
/// Provided by `kit_ink`. Each language has its own model, downloaded once
/// from Google and kept: [hasModel] before offering the pad, [downloadModel]
/// with the user's consent (it is several megabytes).
abstract interface class InkRecognizer {
  Future<KitAvailability> availability();

  /// Whether the model for [languageCode] (`ar` · `en`) is on the device.
  Future<bool> hasModel(String languageCode);

  /// Fetches the model — `false` when the download failed (no network, or a
  /// network that blocks Google). Never throws.
  Future<bool> downloadModel(String languageCode);

  /// What [strokes] say, the likeliest first — empty when nothing was
  /// recognised, `null` when recognition could not run.
  Future<List<String>?> recognize(
    List<InkStroke> strokes, {
    required String languageCode,
  });
}

/// One touch from finger down to finger up.
final class InkStroke {
  const InkStroke(this.points);

  final List<InkPoint> points;
}

final class InkPoint {
  const InkPoint(this.x, this.y, this.time);

  final double x;
  final double y;

  /// Milliseconds since epoch — the recogniser reads the order and pace.
  final int time;
}
