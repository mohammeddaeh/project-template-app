import 'dart:async';

/// **كم أُرسل من الملفّ الجاري الآن** — في الذاكرة، لا بقاعدة البيانات.
///
/// ## لماذا ليس عموداً بجدول المرفقات
///
/// التقدّم يتغيّر عشرات المرّات بالثانية لكل ملفّ. كتابتُه صفّاً بـSQLite مع كل
/// نبضة تعني آلاف عمليات الكتابة برفعةٍ واحدة، **على جهازٍ يرفع بالفعل** —
/// فتتنافس الكتابةُ مع الرفع على نفس الموارد لأجل رقمٍ لا يعيش أكثر من ثانية.
///
/// وهو أيضاً **لا يستحقّ البقاء**: تطبيقٌ أُغلق وسط رفعة يبدأ الملفّ من أوّله
/// (لا استئنافَ رفعٍ اليوم — الاستئناف للتنزيل وحده)، فقيمةٌ محفوظة من الجلسة
/// السابقة تصف تقدّماً لم يعد قائماً.
///
/// ## وما الذي يبقى صادقاً بدونه
///
/// `SyncCenterLocalDataSource` يحسب تقدّم المقسم من **حالات** مرفقاته: مؤكَّدان
/// من ستّة = ٣٣٪. وهو صادقٌ وحده، ويتحرّك ستّ خطوات. وهذا الصنف يملأ ما بين
/// الخطوات — ويظهر أثره كاملاً بمقسمٍ مرفقُه **واحدٌ كبير**: بدونه يجلس الشريط
/// على الصفر حتى يقفز إلى واحد.
class AttachmentUploadProgress {
  AttachmentUploadProgress();

  final _controller = StreamController<void>.broadcast();
  final Map<String, double> _fractions = {};

  /// نبضةٌ بلا حمولة عند كل تغيّر — المستمع يقرأ [fractionOf] بشروطه.
  Stream<void> get stream => _controller.stream;

  /// `0.0`–`1.0` لملفٍّ يُرسل الآن، و`null` لما لم يبدأ أو انتهى.
  double? fractionOf(String attachmentId) => _fractions[attachmentId];

  /// يُسجّل تقدّم إرسالٍ جارٍ. [total] قد يكون `-1` حين لا يعلنه الخادم —
  /// فيُهمَل بدل أن يُقسَم عليه.
  void report({
    required String attachmentId,
    required int sent,
    required int total,
  }) {
    if (total <= 0) return;
    final fraction = (sent / total).clamp(0.0, 1.0);
    if (_fractions[attachmentId] == fraction) return;
    _fractions[attachmentId] = fraction;
    if (!_controller.isClosed) _controller.add(null);
  }

  /// يُنسى الملفّ — عند نجاحه أو إخفاقه.
  ///
  /// **إلزاميّ**: قيمةٌ متروكة عند ٠٫٧ لملفٍّ أُكِّد تجعل الشاشة تخلط «انتهى»
  /// بـ«توقّف عند سبعين بالمئة»، والخريطةُ تنمو برفعةٍ طويلة بلا حدّ.
  void clear(String attachmentId) {
    if (_fractions.remove(attachmentId) == null) return;
    if (!_controller.isClosed) _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}
