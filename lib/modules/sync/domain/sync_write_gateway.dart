import 'sync_status.dart';

class SyncWriteCommand {
  const SyncWriteCommand({
    required this.entityName,
    required this.localId,
    required this.serverId,
    required this.dataJson,
    required this.updatedAt,
    required this.version,
    required this.isDeleted,
    required this.jobType,
    required this.jobPayloadJson,
    required this.contractVersion,
    this.enqueue = true,
    this.holdLocal = false,
    this.jobIdempotencyKey,
    this.maxRetries = 5,
  });

  final String entityName;
  final String localId;
  final String? serverId;
  final String dataJson;
  final int updatedAt;
  final int version;
  final bool isDeleted;
  final SyncJobType jobType;
  final String jobPayloadJson;
  final int contractVersion;
  final bool enqueue;

  /// **كتابةٌ محلّية لم يحن رفعُها تبقى `pending*` لا `synced`.**
  ///
  /// البوّابة تختم ما لا يُصفّ `synced` — وهو صحيحٌ لسببه الأصلي: صفٌّ يكتبه
  /// **السحبُ** من الخادم استقرّ هناك فعلاً. أمّا صفٌّ كتبه المستخدم ولم يدخل
  /// الطابور بعدُ فـ`synced` عنه **كذبة**، وثمنُها ثلاثة:
  ///
  /// | من يقرأ العمود | ما يفعله بالكذبة |
  /// |---|---|
  /// | مُدمِجُ السحب | يكتب فوق شغل المستخدم بردِّ السحب — الحارسُ يستثني `pending*` وحدها |
  /// | شاشاتُ الشريحة | تقول «مُزامَن» عن صفٍّ لم يغادر الجهاز |
  /// | حذفُ الأبناء الغائبين | يمحو الصفَّ مع أبيه على أنه لا شغلَ فيه |
  ///
  /// و[holdLocal] تفصل السببين: **لا تُصفّ** لأن الوقت لم يحن، و**لا تكذب**
  /// لأن الشغل ما زال هنا. وتُقرأ حين `enqueue: false` وحدها.
  final bool holdLocal;
  final String? jobIdempotencyKey;
  final int maxRetries;
}

abstract class SyncWriteGateway {
  Future<void> write(SyncWriteCommand command);
}
