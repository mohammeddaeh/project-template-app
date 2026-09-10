import 'dart:io';

import 'package:dio/dio.dart';

import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/modules/sync/engine/sync_urls.dart';

import '../domain/attachment_record.dart';
import 'attachment_upload_manager.dart';

/// رفعُ مرفقٍ إلى `POST /attachments` — **الجسدُ الوحيد، والشرائح تسمّي نفسها.**
///
/// ## لماذا صنفٌ مشترك، ولماذا **الآن** لا قبل ذلك
///
/// قاعدة القالب أن يُنتظر المستهلك الثاني قبل التعميم (F21/R34). وقد وصل:
/// `entries` كانت وحدها، ثم صارت `parcels` تحتاج نفس الطريق بحرفه. والفرق
/// بينهما **سطرٌ واحد** — `entityName` — بينما الباقي أربعون سطراً من عقد
/// الوايَر: المسار، ورأس التعادل، وفحصُ المغلّف، وفحصُ `data.id`.
///
/// ونسختان من ذلك ليستا تكراراً تجميلياً بل **خطرُ R01 بعينه**: يُغيَّر مفتاحٌ
/// أو يُشدَّد فحصٌ بإحداهما ولا يُلاحظ أن الأخرى بقيت على القديم، فترفع شريحةٌ
/// وتصمت أختُها — و`dart analyze` أخضرُ بالحالتين.
///
/// ## وموضعُه بالموديول لا بالشريحة
///
/// `/attachments` موردٌ **عابرٌ للشرائح** بحكم عقده: الجسد يحمل `entity_name`
/// بنفسه (`attachmentFormData`)، فليس لشريحةٍ بعينها ملكيّةُ المسار. ووضعُه
/// بإحداهما كان يعني أن الثانية تستوردها — و`features → features ❌`.
///
/// والطبقات تسمح: `modules → foundation + infra`، و[Env] و[SyncUrls] كلاهما
/// بـ`core/infra/` — وهو نفس ما يستورده `AttachmentMetadataSync` بجوار هذا
/// الملف للسبب نفسه.
///
/// ```dart
/// @Named('parcelsAttachmentUploadTarget')
/// @LazySingleton(as: AttachmentUploadTarget)
/// class ParcelsAttachmentUploadTarget extends RestAttachmentUploadTarget {
///   ParcelsAttachmentUploadTarget(super.dio);
///   @override
///   String get entityName => 'parcels';
/// }
/// ```
abstract class RestAttachmentUploadTarget implements AttachmentUploadTarget {
  RestAttachmentUploadTarget(this.dio);

  /// الـDio **المُوثَّق**: المرفقات خاصة، ويمرّ عليها رأس الجلسة وتجديد الـ401
  /// وحارس الاتصال كما يمرّ على كل طلبٍ آخر.
  final Dio dio;

  /// يوصله `AttachmentUploadManager` قبل كل ملفّ ويفصله بعده — راجع عقده هناك.
  @override
  void Function(int sent, int total)? onSendProgress;

  @override
  String contentUrlFor(String attachmentId) =>
      '${Env.baseUrl}${SyncUrls.attachmentContent(attachmentId)}';

  @override
  Future<String> upload({
    required AttachmentRecord record,
    required File file,
    required String idempotencyKey,
  }) async {
    final response = await dio.post<dynamic>(
      '${Env.baseUrl}${SyncUrls.attachments}',
      data: await attachmentFormData(record: record, file: file),
      onSendProgress: onSendProgress,
      // ثابتٌ عبر كل محاولة — يبنيه `AttachmentUploadManager` من هوية المرفق.
      // الفشل الذي يحمي منه هو طلبٌ **وصل** وضاع ردّه، وهو من هنا لا يُفرَّق عن
      // طلبٍ لم يصل قط.
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );

    final json = response.data as Map<String, dynamic>?;
    final ok = json?['status'] as bool? ?? false;
    if (!ok) {
      // مغلّفٌ يقول `false` بحالة 200 — يرمي، ولا يُعدّ نجاحاً.
      // و`FailureMapperRegistry` بمدير الرفع يصنّفه عابراً فيُعاد، وهو الصواب:
      // خادمٌ ردّ ردّاً غامضاً غيرُ خادمٍ رفض صراحةً.
      throw StateError(
        'Attachment upload refused in a 200 envelope: '
        '${json?['message'] ?? 'no message'}',
      );
    }

    final id = (json?['data'] as Map<String, dynamic>?)?['id'] as String?;
    if (id == null || id.isEmpty) {
      // **بلا معرّف لا تأكيد.** أن نعدّها مرفوعةً هنا يعني أن يُصرَّح لمدير
      // التخزين بإخلاء صورةٍ لا وجود لها إلا على هذا الجهاز.
      throw StateError(
        'Attachment upload answered without data.id — nothing confirms the '
        'bytes arrived, so the local copy stays owed.',
      );
    }
    return id;
  }
}
