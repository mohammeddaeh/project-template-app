import 'dart:io';

/// System share sheet abstraction (text / URL / file).
///
/// ## Usage
/// ```dart
/// await _share.text('Check this out!', subject: 'Great content');
/// await _share.url('https://example.com');
/// await _share.file(myFile, text: 'Here is the document');
/// ```
///
/// Registered in `di/injection_module.dart`.
abstract interface class ShareService {
  /// Opens the share sheet with plain [text].
  ///
  /// [subject] is used on platforms that support an email subject (e.g. iOS).
  Future<void> text(String text, {String? subject});

  /// Opens the share sheet with a [url] string.
  Future<void> url(String url, {String? subject});

  /// Opens the share sheet with a [file] attachment and optional [text].
  Future<void> file(File file, {String? text, String? subject});

  /// Opens the share sheet with multiple [files].
  Future<void> files(List<File> files, {String? text, String? subject});
}
