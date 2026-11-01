import '../kit_availability.dart';

/// Printed text read from a photo, on the device.
///
/// Provided by `kit_scan`. ⚠️ **Latin script only** — the on-device model does
/// not read Arabic. It suits identifiers, plates, serial numbers and English
/// documents; Arabic text comes back empty or garbled.
abstract interface class TextRecognizer {
  Future<KitAvailability> availability();

  /// The text in the image at [imagePath], lines joined by `\n`; empty when
  /// none was found, `null` when the image could not be read.
  Future<String?> read(String imagePath);
}
