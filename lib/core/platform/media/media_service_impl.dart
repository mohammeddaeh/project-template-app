import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'media_service.dart';

@LazySingleton(as: MediaService)
class MediaServiceImpl implements MediaService {
  @override
  Future<File?> pickFromGallery() async {
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xFile == null) return null;
    final entity = await PhotoManager.editor.saveImageWithPath(
      xFile.path,
      title: xFile.name,
    );
    return entity.file;
  }

  @override
  Future<File?> pickFromCamera() async {
    final xFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (xFile == null) return null;
    final entity = await PhotoManager.editor.saveImageWithPath(
      xFile.path,
      title: xFile.name,
    );
    return entity.file;
  }

  @override
  Future<File?> capturePrivate({
    int maxWidth = 2048,
    int quality = 85,
  }) async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      // Downscaled and re-encoded **by the picker**, so no image library is
      // added to the dependency list for something the platform already does.
      //
      // A modern phone camera produces 8–12 MB per frame. A round with 200
      // photographs is therefore two gigabytes of upload for evidence that is
      // legible at a fraction of it — and on a field connection, bytes are the
      // budget the whole round runs on.
      //
      // This happens **before** the checksum is taken. Reversed, the fingerprint
      // would describe an original that is never uploaded, and every later
      // verification would compare against a file that does not exist.
      maxWidth: maxWidth.toDouble(),
      imageQuality: quality,
    );
    if (xFile == null) return null;
    // Deliberately **not** `PhotoManager.editor.saveImageWithPath` — that is
    // what puts a photo in the user's gallery, and collected data must not go
    // there. The raw file is returned as the picker produced it; the caller
    // copies it into private storage before doing anything else with it.
    return File(xFile.path);
  }

  @override
  Future<Uint8List?> videoThumbnail(String videoPath) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: dir.path,
        imageFormat: ImageFormat.PNG,
        quality: 75,
      );
      if (file == null) return null;
      return File(file).readAsBytes();
    } catch (e) {
      log('videoThumbnail error: $e', name: 'MediaServiceImpl');
      return null;
    }
  }
}
