import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_template/core/platform/files/file_service.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// [FileService] implementation using `file_picker`, `dio`, and `open_filex`.
///
/// Dio is constructor-injected (plain instance, no auth interceptors) — the
/// interface stays clean. Registered conditionally via
/// `di/platform_services_registry.dart` when [AppFeatures.fileOperations] is enabled.
class FileServiceImpl implements FileService {
  const FileServiceImpl(this._dio);

  /// A plain Dio instance (no auth interceptors) used for public file downloads.
  final Dio _dio;

  @override
  Future<File?> pick({List<String> allowedExtensions = const []}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
        allowedExtensions: allowedExtensions.isEmpty ? null : allowedExtensions,
        allowMultiple: false,
      );
      final path = result?.files.single.path;
      return path != null ? File(path) : null;
    } catch (e) {
      LogService.error('FileService.pick failed: $e', tag: 'FILE');
      return null;
    }
  }

  @override
  Future<File?> download(String url, String fileName) async {
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/$fileName';

      await _dio.download(url, savePath);
      return File(savePath);
    } catch (e) {
      LogService.error('FileService.download failed: $e url=$url', tag: 'FILE');
      return null;
    }
  }

  @override
  Future<void> open(File file) async {
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      LogService.warning(
        'FileService.open — ${result.type}: ${result.message}',
        tag: 'FILE',
      );
    }
  }

  @override
  Future<bool> saveToDownloads(File file) async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) return false;

      final fileName = file.path.split(Platform.pathSeparator).last;
      await file.copy('${downloadsDir.path}/$fileName');
      return true;
    } catch (e) {
      LogService.error('FileService.saveToDownloads failed: $e', tag: 'FILE');
      return false;
    }
  }
}
