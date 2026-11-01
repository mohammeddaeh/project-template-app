import '../kit_availability.dart';

/// Paper pages photographed flat — edges found, perspective corrected,
/// cropped — by the platform's own scanner screen.
///
/// Provided by `kit_scan`. Android with Google Play services only: elsewhere
/// [availability] answers [KitUnsupported].
abstract interface class DocumentScanner {
  Future<KitAvailability> availability();

  /// Opens the scanner for up to [maxPages] pages — their JPEG paths in
  /// order, or `null` when the user backs out.
  ///
  /// The files are temporary, as a captured photo is: copy them into private
  /// storage at once.
  Future<DocumentScanResult> scan({int maxPages = 5});
}

sealed class DocumentScanResult {
  const DocumentScanResult();
}

final class DocumentScanned extends DocumentScanResult {
  const DocumentScanned(this.pages);

  final List<String> pages;
}

/// The user closed the scanner without a page.
final class DocumentScanCancelled extends DocumentScanResult {
  const DocumentScanCancelled();
}

/// The scanner could not run — no Play services, or it failed to start.
final class DocumentScanFailed extends DocumentScanResult {
  const DocumentScanFailed();
}
