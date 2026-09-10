import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/infra/files/server_file_cache.dart';
import 'package:app_template/core/platform/files/file_service.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/widgets/media/captured_photo.dart';
import 'package:app_template/ui/widgets/media/captured_photo_viewer.dart';

/// **ضغطةٌ على مرفَق ⇒ ماذا يقع** — قرارٌ واحد لكلّ صورةٍ وملفٍّ بالتطبيق.
///
/// | المرفَق | ما يقع |
/// |---|---|
/// | صورةٌ لها بايتات (قرصٌ أو base64) | [CapturedPhotoViewer] — تكبيرٌ وبياناتُها أسفلها |
/// | صورةٌ يملكها الخادم | نفسُ الحوار، **والبايتاتُ تنزل داخله** — راجع `CapturedPhotoImage.download` |
/// | مستندٌ له بايتات (PDF · DWG · …) | يُفتح بتطبيق النظام — [FileService.open] |
/// | مستندٌ يملكه الخادم | **يُنزَّل ثم يُفتح** — [ServerFileCache]، ومرّةً واحدة |
/// | بلا بايتاتٍ على الجهاز | **رسالةٌ تقول لماذا** — لا حوارٌ فارغ ولا صمت |
///
/// ## ولماذا تُنسخ الملفّاتُ قبل فتحها
///
/// مخزنُ المرفقات **معنوَنٌ بالمحتوى**: كلُّ ملفٍّ يسكن `files/3e/3e058b…754e`
/// باسمِ بصمته و**بلا امتداد** — وهو الصواب هناك، فالبصمة تمنع تكرار البايتات.
/// لكنّ أندرويد يستنتج نوعَ الملفّ من الامتداد وحده، فتسليمُ هذا المسار إلى
/// `OpenFilex` يردّ «لا تطبيق يفتحه» عن ملفٍّ سليم. فيُنسخ إلى المؤقّت باسمه
/// الأصلي — والموظّف يرى «عقد الإيجار.pdf» لا بصمةً من ٦٤ حرفاً.
///
/// **ولا يُمسّ الأصل**: النسخة المؤقّتة يمحوها النظام، والمخزن هو الذي يُرفع
/// ويُحسب حجمُه ويُطابَق ببصمته.
abstract final class AttachmentPreview {
  static const _tag = 'ATTACHMENT-PREVIEW';

  /// هل لهذا المرفَق ما يُعرض أصلاً؟ — **يسبق رسمَ الزرّ لا ضغطَه**.
  ///
  /// زرُّ معاينةٍ لا يفتح شيئاً أسوأ من غيابه: يدعو إلى ضغطةٍ ويردّ برسالة.
  /// ✅ **و[CapturedPhoto.remotePath] صار جواباً بنعم (2026-08-31)**: كان ملفُّ
  /// الخادم يُرسم بلا زرّ لأنه «لا يُفتح» — ولا نقطةَ تنزيل كانت بالعقد. صارت
  /// (`GET /api/v1/files`)، فما يملكه الخادمُ يُفتح كما يُفتح ما بالقرص، وفرقُهما
  /// رحلةٌ واحدة تقع مرّةً.
  static bool canPreview(CapturedPhoto photo) =>
      photo.hasBytes ||
      photo.hasRemote ||
      photo.hasRemotePath ||
      (photo.hasLocalFile && File(photo.localPath!).existsSync());

  /// يفتح ما يُفتح، ويقول ما لا يُفتح.
  static Future<void> open(
    BuildContext context, {
    required CapturedPhoto photo,
    VoidCallback? onDelete,
  }) async {
    if (photo.isImage && canPreview(photo)) {
      await CapturedPhotoViewer.show(context, photo: photo, onDelete: onDelete);
      return;
    }

    final result = await _materialize(photo);
    if (!context.mounted) return;

    final file = result.file;
    if (file == null) {
      // **والرسائلُ تفترق لأن الفعلَ يفترق**: مَن لا اتصالَ له ينتظر، ومَن ذهب
      // ملفُّه من الخادم لا تُجدي معه إعادة، ومَن ذهب ملفُّه من القرص يُعيد
      // إرفاقَه. ورسالةٌ واحدة للثلاث تُرسل الموظّف يجرّب ما لا يُجدي.
      switch (result.outcome) {
        case ServerFileOutcome.offline:
          context.feedback.warning(
            LocaleKeys.attachmentOfflineUnavailable.tr(),
          );
        case ServerFileOutcome.notFound:
          context.feedback.warning(LocaleKeys.attachmentNotOnServer.tr());
        case ServerFileOutcome.failed:
          context.feedback.error(LocaleKeys.attachmentDownloadFailed.tr());
        case ServerFileOutcome.ok || null:
          photo.isUploaded
              ? context.feedback.info(LocaleKeys.attachmentServerOnly.tr())
              : context.feedback.warning(
                  LocaleKeys.attachmentMissingLocally.tr(),
                );
      }
      return;
    }

    try {
      await getIt<FileService>().open(file);
    } catch (error, stackTrace) {
      LogService.error(
        'Could not hand "${photo.label}" to a system viewer.',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        context.feedback.error(LocaleKeys.attachmentOpenFailed.tr());
      }
    }
  }

  /// ملفٌّ على القرص باسمٍ ذي امتداد — ومعه **سببُ غيابه** إن غاب.
  ///
  /// و[ServerFileOutcome] يُملأ حين يُسأل الخادمُ وحده: `null` تعني أن السؤال
  /// لم يُطرح أصلاً (لا مسارَ للملفّ عنده)، وهي حالٌ أخرى ورسالةٌ أخرى.
  static Future<({File? file, ServerFileOutcome? outcome})> _materialize(
    CapturedPhoto photo,
  ) async {
    try {
      final bytes = photo.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        final target = await _temporaryFile(photo);
        return (
          file: await target.writeAsBytes(bytes, flush: true),
          outcome: null,
        );
      }

      final path = photo.localPath;
      if (path != null && path.isNotEmpty && File(path).existsSync()) {
        final source = File(path);
        // امتدادٌ صحيحٌ سلفاً ⇒ لا نسخة. وملفّاتُ المخزن وحدها هي التي تُنسخ.
        if (p.extension(path).isNotEmpty) return (file: source, outcome: null);
        return (
          file: await source.copy((await _temporaryFile(photo)).path),
          outcome: null,
        );
      }

      // **ولا نسخةَ محلّية**: يُسأل الخادم. والمخزنُ يجيب من القرص إن كان قد
      // نزل قبلاً، فلا تتكرّر الرحلةُ بكل فتحة.
      if (photo.hasRemotePath) {
        final fetched = await getIt<ServerFileCache>().fetch(photo.remotePath);
        // ملفُّ المخزن يحمل امتدادَ مساره عند الخادم، فيُسلَّم كما هو —
        // أندرويد يستنتج النوعَ من الامتداد وحده.
        return (file: fetched.file, outcome: fetched.outcome);
      }

      return (file: null, outcome: null);
    } catch (error) {
      LogService.warning(
        'Could not prepare "${photo.label}" for viewing: $error',
        tag: _tag,
      );
      return (file: null, outcome: null);
    }
  }

  /// وجهةُ النسخة: `…/attachment_preview/<اسمُ الملفّ الأصلي>`.
  ///
  /// ومجلَّدٌ خاصّ بها لا جذرُ المؤقّت: أسماءُ المستندات تتكرّر («عقد.pdf»)،
  /// ومسحُها جميعاً يوماً يصير حذفَ مجلَّد.
  static Future<File> _temporaryFile(CapturedPhoto photo) async {
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, 'attachment_preview'),
    );
    if (!dir.existsSync()) await dir.create(recursive: true);
    return File(p.join(dir.path, _fileName(photo)));
  }

  static String _fileName(CapturedPhoto photo) {
    final label = photo.label?.trim() ?? '';
    if (label.isNotEmpty && p.extension(label).isNotEmpty) {
      // اسمٌ يحمل فاصلَ مسارٍ يخرج من المجلَّد المقصود — يُؤخذ آخرُه وحده.
      return label.split(RegExp(r'[\/]')).last;
    }
    final fromPath = p.basename(photo.localPath ?? '');
    if (p.extension(fromPath).isNotEmpty) return fromPath;
    final stem = label.isNotEmpty
        ? label
        : (fromPath.isNotEmpty ? fromPath : 'attachment');
    return '$stem${_extensionFor(photo)}';
  }

  /// امتدادٌ من نوع المحتوى — و`.bin` حين لا يُعرف: ملفٌّ يُسلَّم بلا امتداد
  /// يردُّه النظام «لا تطبيق يفتحه»، وهي رسالةٌ لا تقول للموظّف شيئاً.
  static String _extensionFor(CapturedPhoto photo) =>
      switch (photo.mimeType?.toLowerCase().trim()) {
        'application/pdf' => '.pdf',
        'image/jpeg' || 'image/jpg' => '.jpg',
        'image/png' => '.png',
        'image/webp' => '.webp',
        'image/heic' => '.heic',
        _ => '.bin',
      };
}
