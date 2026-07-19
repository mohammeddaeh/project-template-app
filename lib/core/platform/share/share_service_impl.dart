import 'dart:io';

import 'package:app_template/core/platform/share/share_service.dart';
import 'package:share_plus/share_plus.dart';

/// [ShareService] implementation backed by `share_plus`.
///
/// Registered manually in `di/injection_module.dart`.
class ShareServiceImpl implements ShareService {
  const ShareServiceImpl();

  @override
  Future<void> text(String text, {String? subject}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject));

  @override
  Future<void> url(String url, {String? subject}) =>
      SharePlus.instance.share(ShareParams(uri: Uri.parse(url), subject: subject));

  @override
  Future<void> file(File file, {String? text, String? subject}) =>
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: text,
          subject: subject,
        ),
      );

  @override
  Future<void> files(List<File> files, {String? text, String? subject}) =>
      SharePlus.instance.share(
        ShareParams(
          files: files.map((f) => XFile(f.path)).toList(),
          text: text,
          subject: subject,
        ),
      );
}
