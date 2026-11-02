/// الـendpoints بالمشروع القديم — **المسارُ ومعه الـmethod حين يظهر**.
///
/// مسارٌ بلا method نصفُ عقد: `GET /orders` و`POST /orders` نقطتان، بجسدين
/// وردّين مختلفين، وتُكتبان بـRetrofit سطرين. فيُلتقط ما يظهر منه بالكود:
///
/// | الشكل | مثال |
/// |---|---|
/// | نداءٌ باسم الـmethod | `http.get('/orders')` · `axios.post(`${api}/orders`)` · `dio.get(base + '/orders')` |
/// | تعليقة Retrofit | `@GET("orders/{id}")` (Kotlin/Java/Dart) |
/// | `fetch` | `fetch('/orders', { method: 'POST' })` — بلا `method` ⇐ `GET` |
/// | نصٌّ يبدأ بـ`/api/` أو `http(s)://` | method مجهول ⇐ `?` |
///
/// والمسار يُطبَّع: البادئةُ المتغيّرة (`${environment.apiUrl}` · `base +`) تسقط،
/// و`${id}` يصير `{id}`، والاستعلام بعد `?` يسقط.
library;

const _methods = 'get|post|put|patch|delete';

final _call = RegExp(
  '\\.($_methods)\\s*(?:<[^>()]*>)?\\(\\s*([\'"`])([^\'"`]*?)\\2',
  caseSensitive: false,
);
final _concatCall = RegExp(
  '\\.($_methods)\\s*(?:<[^>()]*>)?\\(\\s*[\\w.]+\\s*\\+\\s*([\'"`])([^\'"`]+)\\2',
  caseSensitive: false,
);
final _annotation = RegExp(
  '@(GET|POST|PUT|PATCH|DELETE)\\(\\s*(?:value\\s*=\\s*)?[\'"]([^\'"]+)[\'"]',
);
final _fetch = RegExp(
  '\\bfetch\\(\\s*([\'"`])([^\'"`]+)\\1\\s*(?:,\\s*\\{[^}]*?method\\s*:\\s*[\'"](\\w+)[\'"])?',
);
final _literal = RegExp(
  r'''['"`]((?:https?://[^'"`\s]+)|(?:/api/[^'"`\s]*))['"`]''',
);

/// `GET /orders` · `? https://host/api/x` — مرتّبةً بالمسار، والمجهولُ يسقط
/// حين يُعرف method المسار نفسه بموضعٍ آخر.
List<String> extractEndpoints(Iterable<String> texts) {
  final found = <(String, String)>{};
  void add(String method, String raw, {bool annotated = false}) {
    final path = _normalize(raw, annotated: annotated);
    if (path == null) return;
    found.add((method.toUpperCase(), path));
  }

  for (final text in texts) {
    for (final m in _call.allMatches(text)) {
      add(m[1]!, m[3]!);
    }
    for (final m in _concatCall.allMatches(text)) {
      add(m[1]!, m[3]!);
    }
    for (final m in _annotation.allMatches(text)) {
      add(m[1]!, m[2]!, annotated: true);
    }
    for (final m in _fetch.allMatches(text)) {
      add(m[3] ?? 'GET', m[2]!);
    }
    for (final m in _literal.allMatches(text)) {
      add('?', m[1]!);
    }
  }

  final known = {
    for (final (method, path) in found)
      if (method != '?') path,
  };
  final result =
      [
        for (final (method, path) in found)
          if (method != '?' || !known.contains(path)) (method, path),
      ]..sort((a, b) {
        final byPath = a.$2.compareTo(b.$2);
        return byPath != 0 ? byPath : a.$1.compareTo(b.$1);
      });
  return [for (final (method, path) in result) '$method $path'];
}

/// `null` لما ليس مساراً (`map.get('key')` · رابط ملفٍّ ثابت).
String? _normalize(String raw, {required bool annotated}) {
  var path = raw.trim();
  // البادئة المتغيّرة: `${environment.apiUrl}/orders` ⇐ `/orders`.
  path = path.replaceFirst(RegExp(r'^\$\{[^}]*\}'), '');
  path = path.replaceAllMapped(
    RegExp(r'\$\{(?:[\w.]*\.)?(\w+)\}'),
    (m) => '{${m[1]}}',
  );
  path = path.split('?').first;
  if (path.isEmpty) return null;
  final isUrl = path.startsWith('http://') || path.startsWith('https://');
  // كلمةٌ وحدها بلا `/` تُقبل من تعليقة Retrofit (`@GET("orders")`) وحدها —
  // ومن نداء `.get('token')` هي مفتاحُ تخزين لا مسار.
  if (!isUrl && !path.contains('/') && !annotated) return null;
  if (path.contains(' ')) return null;
  if (RegExp(
    r'\.(png|jpe?g|svg|gif|webp|css|js|json|html|ttf|woff2?)$',
  ).hasMatch(path)) {
    return null;
  }
  if (!isUrl && !path.startsWith('/')) path = '/$path';
  return path;
}
