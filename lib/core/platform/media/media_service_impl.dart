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
