import 'dart:convert';
import 'dart:typed_data';

/// **بايتاتُ ملفٍّ تسافر داخل النصّ** — `data:` URI أو base64 عارياً.
///
/// عقدٌ يرفع الملفّات base64 داخل جسد الطلب (`{name, data}`) وقد لا يملك
/// نقطةَ تنزيل، فكلُّ ملفٍّ يصل الجهازَ نصّاً قد يكون **بايتاتِه لا مسارَه**.
/// وهذا الموضع هو الذي يفرّق بينهما — بموضعٍ واحد، لا بشرطٍ يُنسخ عند كل عارض.
///
/// | ما يصل | ما يُعاد |
/// |---|---|
/// | `data:image/png;base64,iVBORw0…` | البايتات، و[mimeOf] يقرأ النوع من الترويسة |
/// | `iVBORw0KGgo…` (base64 عارٍ، ≥ ٦٤ حرفاً) | البايتات |
/// | `storage\files\1787…png` | `null` — مسارٌ لا بايتات |
/// | `{"name":"عقد.pdf","size":753612}` | `null` — بطاقةٌ بلا بيانات |
///
/// **والحدُّ الأدنى (٦٤ حرفاً) شرطُ تمييزٍ لا تحسين**: `base64.decode` يقبل
/// كلماتٍ قصيرةً كثيرة بالمصادفة (اسمُ نوعٍ قصير نصٌّ صالح)، فبلا الحدّ كان
/// اسمُ ملفٍّ قصير يُقرأ صورةً مشوّهة بدل أن يُقرأ اسماً.
abstract final class InlineFileData {
  /// أقصرُ نصٍّ يُصدَّق أنه بايتاتُ ملفّ. أصغرُ PNG صالحة تتجاوز هذا بكثير.
  static const int _minBase64Chars = 64;

  static final RegExp _dataUri = RegExp(
    r'^data:([^;,]*)(;[^,]*)?;base64,',
    caseSensitive: false,
  );

  /// هل يحمل [raw] بايتاتٍ مضمَّنة؟ — فحصٌ بلا فكِّ ترميز، للقرارات وحدها.
  static bool looksInline(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return false;
    if (_dataUri.hasMatch(value)) return true;
    if (value.length < _minBase64Chars) return false;
    if (value.startsWith('{') || value.contains('/') || value.contains(r'\')) {
      return false;
    }
    return RegExp(r'^[A-Za-z0-9+/=\s]+$').hasMatch(value);
  }

  /// البايتات، أو `null` إن لم يكن النصّ بايتاتٍ أصلاً.
  ///
  /// **ولا يرمي أبداً**: نصٌّ يشبه base64 ولا يُفكّ يُعاد `null` — عارضُ صورةٍ
  /// لا يجوز أن يُسقط شاشةً بسبب حقلٍ وصل بشكلٍ لم يُتوقَّع.
  static Uint8List? decode(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    final match = _dataUri.firstMatch(value);
    final payload = match == null
        ? (looksInline(value) ? value : '')
        : value.substring(match.end);
    if (payload.isEmpty) return null;

    try {
      return base64.decode(base64.normalize(payload.replaceAll(_space, '')));
    } catch (_) {
      return null;
    }
  }

  /// نوعُ المحتوى من ترويسة `data:` وحدها — و`null` لكلّ ما عداها.
  static String? mimeOf(String? raw) {
    final match = _dataUri.firstMatch(raw?.trim() ?? '');
    final mime = match?.group(1)?.trim() ?? '';
    return mime.isEmpty ? null : mime;
  }

  static final RegExp _space = RegExp(r'\s');
}
