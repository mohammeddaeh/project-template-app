import 'dart:convert';

/// **حكمُ الخادم على جزءٍ واحد من الرفعة** — و`null` بـ[message] تعني «قُبل».
class SyncPartVerdict {
  const SyncPartVerdict({required this.part, this.message});

  factory SyncPartVerdict.fromJson(Map<String, dynamic> json) =>
      SyncPartVerdict(
        part: json['part'] as String? ?? '',
        message: json['message'] as String?,
      );

  /// اسمُ الجزء كما يعرفه الكيان — مفتاحُ قسمٍ لا نصٌّ مترجَم.
  ///
  /// وترجمتُه شأنُ الشريحة: `SyncJobExplainer` هو من يحوّله إلى ما يُقرأ.
  final String part;

  /// ما قاله الخادمُ عنه — و`null` تعني أنه **قُبل وحده**.
  final String? message;

  bool get accepted => message == null;

  Map<String, dynamic> toJson() => {
    'part': part,
    if (message != null) 'message': message,
  };
}

/// **حقلٌ بعينه رفضه الخادم** — من مغلّف `issues` بردّ التحقّق.
///
/// ## و[field] مسارُ عقدٍ لا نصٌّ مترجَم — عمداً
///
/// `heritage.documentImage.name` · `investment.tenants.0.idFrontImage.name`.
/// وترجمتُه شأنُ العرض لا شأنُ التخزين، لثلاثة أسباب:
///
/// 1. **يُخزَّن مرّةً ويُقرأ مراراً** — ولغةُ التطبيق تتبدّل بينهما.
/// 2. **المسار مفتاحٌ ثابت**، والنصُّ نثرٌ يعيد الباك صياغتَه.
/// 3. وترجمتُه هنا تعني أن `modules/sync` يعرف حقولَ المقاسم — وهو لا يعرفها
///    ولا يجوز أن يعرفها.
///
/// ⚠️ **و[message] نصُّ الخادم كما وصل — وهو إنكليزيٌّ اليوم** ولو كان
/// `Accept-language: ar`: الباك يترجم `error` العامّة ويترك `issues`. فيُعرض
/// **تحت** العنوان المترجَم من [field]، لا مكانَه — ولا يُطابَق نصُّه أبداً
/// (R01 · نفسُ درس `account_status`).
class SyncFailureIssue {
  const SyncFailureIssue({required this.field, this.message});

  factory SyncFailureIssue.fromJson(Map<String, dynamic> json) =>
      SyncFailureIssue(
        field: json['field'] as String? ?? '',
        message: json['message'] as String?,
      );

  /// مسارُ الحقل بجسد الطلب — بنقاط، وبفهرسٍ رقميّ للقوائم.
  final String field;

  /// ما قاله الخادمُ عنه، كما وصل.
  final String? message;

  Map<String, dynamic> toJson() => {
    'field': field,
    if (message != null) 'message': message,
  };
}

/// **لماذا لم تصعد هذه الرفعة — مفصَّلةً بقدر ما يسمح به الخادم.**
///
/// ## ولماذا لا يكفي نصٌّ واحد
///
/// `sync_queue.last_error` عمودٌ نصّيّ، وكان يحمل رسالةَ الخادم عاريةً:
/// **«خطأ داخلي في الخادم»** وحدها، عن نداءٍ يحمل خمسة أقسام. فالموظّف يقرأ أن
/// شيئاً أخفق ولا يعرف أيَّه — ولا سبيل له إلى معرفته، ولا لمن يصلح.
///
/// وهذا يُخزَّن **بنفس العمود** مُرمَّزاً JSON ([encode])، فلا هجرةَ قاعدة ولا
/// عمودَ جديد. و[decode] تردّ `null` لأيِّ نصٍّ ليس بهذا الشكل — أي أن الأخطاء
/// القديمة والأخطاء التي تكتبها كياناتٌ أخرى تبقى تُعرض كما هي.
///
/// ## والثلاثةُ التي يحملها
///
/// | الحقل | يجيب |
/// |---|---|
/// | [step] | **أين** وقع — إرسالُ الأقسام؟ التسليم؟ الولادة؟ |
/// | [message] | ماذا قال الخادم |
/// | [parts] | **أيُّ جزءٍ بعينه** — حين يُعرف، راجع §العزل |
/// | [issues] | **أيُّ حقلٍ بعينه** رفضه التحقّق — راجع [SyncFailureIssue] |
///
/// ## §العزل — وهو الجواب الوحيد الممكن مع 500
///
/// خطأٌ داخليّ ليس حكمَ تحقّق: الخادمُ انهار، ولا يعرف هو نفسُه أيَّ جزءٍ أسقطه.
/// فلا يُشتقّ الجواب من الردّ — **يُشتقّ بالتجريب**: يُعاد الإرسال جزءاً جزءاً،
/// ويُقال أيُّها يُقبل وحده وأيُّها يُرفض.
///
/// وقد تُقبل الأجزاء كلُّها فرادى ويُرفض مجموعُها (حجمٌ مثلاً). وذلك جوابٌ
/// مفيدٌ كذلك، ويُقال كما هو بدل أن يُخمَّن — راجع [allPartsAccepted].
class SyncFailureReport {
  const SyncFailureReport({
    required this.step,
    this.message,
    this.parts = const [],
    this.issues = const [],
  });

  static const _marker = 'syncFailureReport';

  /// يقرأ التقرير من نصِّ `last_error` — و`null` لأيِّ نصٍّ ليس تقريراً.
  ///
  /// **ولا يرمي أبداً**: العمودُ يحمل نصّاً كتبه أيُّ منفّذ، ورميةٌ هنا تُسقط
  /// ورقةً فُتحت لتشرح عطلاً.
  static SyncFailureReport? decode(String? raw) {
    if (raw == null || raw.isEmpty || !raw.startsWith('{')) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map || json['kind'] != _marker) return null;
      return SyncFailureReport(
        step: json['step'] as String? ?? '',
        message: json['message'] as String?,
        parts: [
          for (final part in json['parts'] as List? ?? const [])
            if (part is Map)
              SyncPartVerdict.fromJson(Map<String, dynamic>.from(part)),
        ],
        issues: [
          for (final issue in json['issues'] as List? ?? const [])
            if (issue is Map)
              SyncFailureIssue.fromJson(Map<String, dynamic>.from(issue)),
        ],
      );
    } catch (_) {
      return null;
    }
  }

  /// اسمُ الخطوة كما يعرفها الكيان — مفتاحٌ لا نصٌّ مترجَم، كـ[SyncPartVerdict.part].
  final String step;

  /// رسالةُ الخادم على النداء الذي أخفق.
  final String? message;

  /// أحكامُ الأجزاء — فارغةٌ حين لم يقع عزل (ولا يقع لكل إخفاق، راجع §العزل).
  final List<SyncPartVerdict> parts;

  /// **الحقولُ التي رفضها التحقّق** — فارغةٌ لكل ردٍّ بلا مغلّف `issues`.
  ///
  /// وهي أدقُّ ما يعطيه الخادمُ حين يعطيه: 500 لا `issues` له، و422 يسمّي
  /// الحقلَ بمساره. راجع [SyncFailureIssue].
  final List<SyncFailureIssue> issues;

  /// **قُبلت الأجزاء كلُّها فرادى** — أي أن العطل بمجموعها لا بواحدٍ منها.
  bool get allPartsAccepted =>
      parts.isNotEmpty && parts.every((part) => part.accepted);

  String encode() => jsonEncode({
    'kind': _marker,
    'step': step,
    if (message != null) 'message': message,
    if (parts.isNotEmpty) 'parts': [for (final part in parts) part.toJson()],
    if (issues.isNotEmpty)
      'issues': [for (final issue in issues) issue.toJson()],
  });
}
