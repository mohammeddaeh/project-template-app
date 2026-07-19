import 'dart:io';
import 'dart:typed_data';

/// Abstract contract for media picking and processing.
///
/// Implemented by [MediaServiceImpl] (image_picker + video_thumbnail).
/// Mock this in tests — never mock the picker packages directly.
///
/// Usage:
/// ```dart
/// final _media = getIt<MediaService>();
///
/// final image = await _media.pickFromGallery();
/// final thumb = await _media.videoThumbnail('/path/to/video.mp4');
/// ```
abstract interface class MediaService {
  /// Opens the device gallery and returns the selected image file.
  /// Returns `null` if the user cancels.
  Future<File?> pickFromGallery();

  /// Opens the camera and returns the captured image file.
  /// Returns `null` if the user cancels.
  Future<File?> pickFromCamera();

  /// Generates a PNG thumbnail for the video at [videoPath].
  /// Returns `null` on failure or cancellation.
  Future<Uint8List?> videoThumbnail(String videoPath);
}
