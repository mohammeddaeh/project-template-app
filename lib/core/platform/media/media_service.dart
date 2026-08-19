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

  /// Opens the camera, **saves the photo to the device gallery**, and returns
  /// it.
  ///
  /// ## ⚠️ The gallery save is real, and it is easy to miss
  ///
  /// The implementation routes through `PhotoManager.editor.saveImageWithPath`,
  /// which writes into the platform photo library. The photo therefore appears
  /// in the user's Gallery, is visible to every other app with media
  /// permission, and is backed up to their cloud photo service.
  ///
  /// That is a reasonable default for a profile picture and **the wrong one for
  /// collected data**: a photograph taken as evidence at a site is not the
  /// user's personal photo, and it should not survive the app's own uninstall
  /// in their camera roll.
  ///
  /// Use [capturePrivate] for anything the app collects.
  Future<File?> pickFromCamera();

  /// Opens the camera and returns the captured file **without touching the
  /// gallery**.
  ///
  /// The file lands in a temporary location, so the caller must copy it into
  /// durable private storage immediately — `AttachmentFileStore.ingestLocalFile`
  /// does exactly that. The OS empties the temporary directory whenever space
  /// runs short, which happens during precisely the long, photo-heavy sessions
  /// where the image cannot be taken again.
  ///
  /// Downscaled to [maxWidth] and re-encoded at [quality] on the way out: a
  /// phone camera produces 8–12 MB a frame, and two hundred of those is two
  /// gigabytes of upload for evidence that reads perfectly at a fraction of it.
  ///
  /// The compression is deliberately **here** rather than at upload time, so
  /// the checksum is taken over the bytes that will actually be sent.
  Future<File?> capturePrivate({int maxWidth, int quality});

  /// Generates a PNG thumbnail for the video at [videoPath].
  /// Returns `null` on failure or cancellation.
  Future<Uint8List?> videoThumbnail(String videoPath);
}
