import 'dart:io';

/// File operations abstraction: pick / download / open / save.
///
/// ## Usage
/// ```dart
/// // Pick a file:
/// final file = await _files.pick(allowedExtensions: ['pdf', 'docx']);
///
/// // Download a file:
/// final saved = await _files.download('https://…/report.pdf', 'report.pdf');
///
/// // Open a file with the default OS viewer:
/// if (saved != null) await _files.open(saved);
/// ```
///
/// Implementation: `file_service_impl.dart` (same folder).
/// Registered conditionally via `di/platform_services_registry.dart`.
abstract interface class FileService {
  /// Opens the OS file picker and returns the selected file, or `null` if
  /// the user cancelled.
  ///
  /// [allowedExtensions] — e.g. `['pdf', 'png', 'docx']`. Empty = any type.
  Future<File?> pick({List<String> allowedExtensions = const []});

  /// Downloads the file at [url] and saves it to the app's temporary
  /// directory with [fileName].
  ///
  /// Returns the saved [File], or `null` on failure.
  Future<File?> download(String url, String fileName);

  /// Opens [file] with the default OS application for its MIME type.
  Future<void> open(File file);

  /// Saves [file] to the device's public Downloads folder.
  ///
  /// Returns `true` on success.
  Future<bool> saveToDownloads(File file);
}
