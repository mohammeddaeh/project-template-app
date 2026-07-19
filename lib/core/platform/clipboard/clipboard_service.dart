/// Clipboard read/write abstraction.
///
/// Wraps Flutter's [Clipboard] so it can be mocked in tests without
/// depending on the platform channel directly.
///
/// Registered in `di/injection_module.dart`.
abstract interface class ClipboardService {
  /// Copies [text] to the system clipboard.
  Future<void> copy(String text);

  /// Returns the current clipboard text, or `null` if empty / unavailable.
  Future<String?> paste();

  /// Returns `true` if the clipboard currently contains plain text.
  Future<bool> hasText();
}
