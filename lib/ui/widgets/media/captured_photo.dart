import 'dart:typed_data';

import 'package:app_template/core/foundation/utils/inline_file_data.dart';

/// صورةٌ ميدانية كما تُعرض — **نموذج عرضٍ محايد، لا كيان شريحة**.
///
/// `ui/` لا تستورد `features/` (قاعدة الطبقات)، فكل شريحة تحوّل كيانها إلى هذا
/// قبل الرسم: `CapturedMedia` بالمقاسم، و`EntryFile` بالسجلات. والثمن سطرُ
/// تحويلٍ واحد، والعائد أن **صورةً ميدانية واحدة بالتطبيق كلّه** لا صورتان
/// تختلفان بما تطبعانه فوقهما.
///
/// ## ما تحمله الصورة الميدانية — أربعة، لا واحد
///
/// الصورة وحدها لا تُثبت شيئاً بملفٍّ وقفيّ: **متى** التُقطت، و**أين**، و**من**
/// التقطها — هي ما يجعلها دليلاً يُراجَع بعد أشهر. ولذلك تُطبع فوق الصورة لا
/// بجدولٍ بجوارها: لقطةُ الشاشة تُرسَل وتُطبع، والبيانات تسافر معها أو تضيع.
///
/// ## ومصادرُ البايتات ثلاثة، بترتيبٍ واحد لا يتبدّل
///
/// | المصدر | متى يُقرأ |
/// |---|---|
/// | [localPath] | ملفٌّ على قرص الجهاز — **الأول دائماً**، ويعمل بلا شبكة |
/// | [bytes] | بايتاتٌ بالذاكرة: base64 وصل بالجسد ولا ملفَّ له ([InlineFileData]) |
/// | [remotePath] | مسارُ تخزينٍ عند الخادم — يُنزَّل بـ`ServerFileCache` ويُخزَّن، فيصير الأولَ بعد أوّل مرّة |
/// | [remoteUrl] | رابطٌ يُنزَّل — آخرُ ما يُجرَّب، ويشترط شبكة |
class CapturedPhoto {
  const CapturedPhoto({
    this.localPath,
    this.remotePath,
    this.remoteUrl,
    this.bytes,
    this.label,
    this.mimeType,
    this.capturedAt,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.capturedBy,
    this.isUploaded = false,
  });

  /// مسار الملف على الجهاز — المصدر الأول دائماً ما دام موجوداً.
  final String? localPath;

  /// **مسارُ الملفّ عند الخادم** — `storage\units\1787…png` كما ينزل بالردّ.
  ///
  /// وليس رابطاً يُفتح: يُبدَّل ببايتاتٍ بنداءِ `GET /api/v1/files?path=…`
  /// (`ServerFileCache`)، ثم يُخزَّن بالجهاز فلا يُنادى ثانيةً. وهو ما يجعل
  /// صورةً رفعها زميلٌ من جهازٍ آخر قابلةً للفتح على هذا الجهاز.
  ///
  /// ⚠️ **ولا ينزل بفتح الشاشة**: المصغَّرة تعرض ما بالمخزن وحده، والتنزيل
  /// بضغطة المستخدم — راجع `NetworkOrigin.userFile`.
  final String? remotePath;

  /// رابط النسخة المرفوعة — يُقرأ حين لا يوجد ملفٌّ محلي (جهازٌ آخر، أو تنظيف
  /// تخزين بعد الرفع). وهو المدخل الذي يجعل «فتح الصورة المرفوعة» ممكناً بلا
  /// تغيير هذه الودجة لاحقاً.
  final String? remoteUrl;

  /// بايتاتُ الصورة بالذاكرة — ما يُفكّ من base64. **ولا تُخزَّن**: تُرسم ثم
  /// تُترك لجامع القمامة، فصورةُ ميدانٍ كاملةً بالذاكرة ثمنُها يُدفع مرّة.
  final Uint8List? bytes;

  /// اسم الملف أو وصفٌ قصير.
  final String? label;

  /// نوعُ المحتوى إن عُرف — يفصل الصورةَ عن المستند حين لا يقول الاسمُ شيئاً.
  final String? mimeType;

  final DateTime? capturedAt;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String? capturedBy;

  /// هل وصلت الخادم؟ يرسمها الشريط بأيقونةٍ واحدة — لا نصّ.
  final bool isUploaded;

  bool get hasLocalFile => localPath?.isNotEmpty ?? false;
  bool get hasBytes => bytes?.isNotEmpty ?? false;
  bool get hasRemote => remoteUrl?.isNotEmpty ?? false;

  /// للخادم نسخةٌ منه، ولها مسارٌ يُنزَّل به — راجع [remotePath].
  bool get hasRemotePath => remotePath?.isNotEmpty ?? false;

  bool get hasSource => hasLocalFile || hasBytes || hasRemote || hasRemotePath;
  bool get hasCoordinates => latitude != null && longitude != null;

  /// **هل يُرسم هذا الملفُّ صورةً؟** — النوعُ أوّلاً، ثم الامتداد.
  ///
  /// وهو ما يفرّق بين معاينةٍ بالتطبيق (صورة) وفتحٍ بتطبيق النظام (PDF · DWG).
  /// و`mimeType` وحده لا يكفي: مسارُ المستندات لا يملؤه بكل مصدر، فيسقط الحكم
  /// على الاسم — وصورةُ الهوية تُلتقط بالكاميرا وتُحفظ مستنداً لأنها تسكن حقلاً
  /// لا خانةَ صورِ موقع.
  bool get isImage {
    final mime = mimeType?.toLowerCase().trim() ?? '';
    if (mime.startsWith('image/')) return true;
    if (mime.isNotEmpty && !mime.startsWith('image/')) return false;
    // ومسارُ الخادم حَكَمٌ ثالث: مرفَقٌ لم ينزل بعدُ لا اسمَ له ولا مسارَ قرص،
    // واسمُه هناك (`…image.png`) هو كلُّ ما يُعرف به.
    return looksLikeImage(label) ||
        looksLikeImage(localPath) ||
        looksLikeImage(remotePath);
  }

  /// خمس منازل ≈ متر واحد — أدقّ من ذلك أرقامٌ تُزحم السطر ولا تُقرأ.
  String get coordinatesLabel => hasCoordinates
      ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
      : '';

  /// امتدادُ صورةٍ معروف بالاسم أو المسار.
  static bool looksLikeImage(String? name) {
    final value = name?.toLowerCase().trim() ?? '';
    if (value.isEmpty) return false;
    return const [
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.heic',
      '.gif',
      '.bmp',
    ].any(value.endsWith);
  }
}
