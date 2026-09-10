// ignore_for_file: avoid_print
/// يسحب تصاميم الفيغما عبر REST API إلى ذاكرة محلية غير مُلتزَمة (`.figma/`)
///
/// لكل إطار يُنتج ثلاثة ملفات:
///   `<slug>.png`   ← المشهد مرسوماً (2x) — ليُرى التصميم لا لتُقرأ إحداثياته
///   `<slug>.md`    ← خلاصة مقروءة: الشجرة + hex + المقاسات + النصوص + auto-layout
///   `<slug>.json`  ← الشجرة مُقلَّمة (machine) — للمقارنة الدقيقة عند الحاجة
///
/// تشغيل:
///   dart run scripts/pull_figma.dart --file `<URL|KEY>`  — يحفظ مفتاح الملف مرّة واحدة
///   dart run scripts/pull_figma.dart --list             — كل الصفحات وإطاراتها بمعرّفاتها
///   dart run scripts/pull_figma.dart --styles           — الأنماط المنشورة (ألوان + نصوص)
///   dart run scripts/pull_figma.dart --node 1:57        — إطار بمعرّفه
///   dart run scripts/pull_figma.dart --name "Login"     — إطار باسمه (بحث جزئي)
///   dart run scripts/pull_figma.dart --all              — كل الإطارات العليا بكل الصفحات
///
/// التوكن يُقرأ بهذا الترتيب:
///   1. متغيّر البيئة FIGMA_TOKEN
///   2. ملف .figma/token   ← الموصى به، وهو مُتجاهَل من git
///
/// ⚠️ لا تمرّر التوكن كوسيط سطر أوامر — يبقى بسجلّ الصدفة (shell history).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ── Config ────────────────────────────────────────────────────────────────────

const _apiHost = 'api.figma.com';
const _root = '.figma';
const _cacheDir = '$_root/cache';
const _tokenFile = '$_root/token';
const _configFile = '$_root/config.json';

/// مقياس تصدير الصورة. 2 يكفي لقراءة النصوص الدقيقة بلا تضخيم الملف.
const _imageScale = 2;

/// تهدئة بين طلبات `--all` — الفيغما يخنق الاندفاع.
const _throttle = Duration(milliseconds: 400);

late final String _token;
late final String _fileKey;

// ── Entry point ───────────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _usage();
    return;
  }

  print('\n🎨  pull_figma\n');

  // `--file` قد يُمرَّر وحده لحفظ المفتاح، أو مع أمر آخر.
  final fileArg = _valueOf(args, '--file');
  if (fileArg != null) {
    final key = _extractFileKey(fileArg);
    _saveConfig(key);
    print('✅  مفتاح الملف محفوظ بـ$_configFile  →  $key');
    if (args.length == 2) return; // `--file X` وحده
  }

  _token = _resolveToken();
  _fileKey = fileArg != null ? _extractFileKey(fileArg) : _resolveFileKey();

  Directory(_cacheDir).createSync(recursive: true);

  if (args.contains('--list')) return _cmdList();
  if (args.contains('--styles')) return _cmdStyles();
  if (args.contains('--all')) return _cmdAll();

  final nodeId = _valueOf(args, '--node');
  if (nodeId != null) return _cmdNode(nodeId, null);

  final name = _valueOf(args, '--name');
  if (name != null) return _cmdByName(name);

  _usage();
}

void _usage() => print('''
🎨  pull_figma — يسحب تصاميم الفيغما إلى $_cacheDir/

  dart run scripts/pull_figma.dart --file <URL|KEY>   حفظ مفتاح الملف (مرّة واحدة)
  dart run scripts/pull_figma.dart --list             سرد الصفحات والإطارات
  dart run scripts/pull_figma.dart --styles           الأنماط المنشورة
  dart run scripts/pull_figma.dart --node 1:57        سحب إطار بمعرّفه
  dart run scripts/pull_figma.dart --name "Login"     سحب إطار باسمه
  dart run scripts/pull_figma.dart --all              سحب كل الإطارات العليا

التوكن: متغيّر البيئة FIGMA_TOKEN أو ملف $_tokenFile
''');

// ── Commands ──────────────────────────────────────────────────────────────────

/// شجرة بعمق 2: المستند → الصفحات (CANVAS) → الإطارات العليا.
Future<void> _cmdList() async {
  final data = await _api('/v1/files/$_fileKey?depth=2');
  final doc = data['document'] as Map<String, dynamic>;
  print('📄  ${data['name']}   (آخر تعديل ${data['lastModified']})\n');

  var frames = 0;
  for (final page in (doc['children'] as List? ?? [])) {
    final p = page as Map<String, dynamic>;
    final children = (p['children'] as List? ?? []);
    print('📁  ${p['name']}   (${children.length})');
    for (final child in children) {
      final c = child as Map<String, dynamic>;
      final box = c['absoluteBoundingBox'] as Map<String, dynamic>?;
      final size = box == null
          ? ''
          : '  ${_n(box['width'])}×${_n(box['height'])}';
      print('     ${_pad(c['id'] as String, 10)}  ${c['name']}$size');
      frames++;
    }
    print('');
  }
  print('الإجمالي: $frames إطاراً.');
  print('التالي:  dart run scripts/pull_figma.dart --node <ID>');
}

/// الأنماط المنشورة. `/styles` يردّ الأسماء والمعرّفات فقط — القيم تُجلب
/// بطلب `/nodes` ثانٍ على تلك المعرّفات نفسها.
Future<void> _cmdStyles() async {
  final meta = await _api('/v1/files/$_fileKey/styles');
  final styles = ((meta['meta'] as Map?)?['styles'] as List? ?? [])
      .cast<Map<String, dynamic>>();

  if (styles.isEmpty) {
    print('⚠️  لا أنماط منشورة بهذا الملف.');
    print('    الألوان ستُستخرج من الإطارات نفسها — أقلّ دقّة، وتعمل.');
    return;
  }

  final ids = styles.map((s) => s['node_id'] as String).toList();
  final nodes = <String, Map<String, dynamic>>{};
  // الـURL محدود الطول — نُقسّم على دفعات.
  for (var i = 0; i < ids.length; i += 40) {
    final batch = ids.sublist(i, (i + 40).clamp(0, ids.length));
    final res = await _api(
      '/v1/files/$_fileKey/nodes?ids=${batch.map(Uri.encodeComponent).join(',')}',
    );
    (res['nodes'] as Map<String, dynamic>).forEach((k, v) {
      final doc = (v as Map<String, dynamic>?)?['document'];
      if (doc != null) nodes[k] = doc as Map<String, dynamic>;
    });
    if (i + 40 < ids.length) await Future<void>.delayed(_throttle);
  }

  final buf = StringBuffer()
    ..writeln('# أنماط الفيغما المنشورة')
    ..writeln()
    ..writeln('> مولَّد بـ`dart run scripts/pull_figma.dart --styles`.')
    ..writeln('> **مصدر قياس لا كود** — كل لون هنا يمرّ عبر `AppPalette` ثم')
    ..writeln('> `AppColors` قبل أن يصل صفحة (F04).')
    ..writeln();

  final fills = styles.where((s) => s['style_type'] == 'FILL').toList();
  final texts = styles.where((s) => s['style_type'] == 'TEXT').toList();
  final effects = styles.where((s) => s['style_type'] == 'EFFECT').toList();

  if (fills.isNotEmpty) {
    buf
      ..writeln('## الألوان (${fills.length})')
      ..writeln()
      ..writeln('| الاسم بالفيغما | Hex | الدرجة | الإضاءة |')
      ..writeln('|---|---|---|---|');
    for (final s in fills) {
      final node = nodes[s['node_id']];
      final hex = _firstFillHex(node) ?? '—';
      final hsl = hex.startsWith('#') ? _hsl(hex) : ('—', '—');
      buf.writeln('| ${s['name']} | `$hex` | ${hsl.$1} | ${hsl.$2} |');
    }
    buf.writeln();
  }

  if (texts.isNotEmpty) {
    buf
      ..writeln('## أنماط النصّ (${texts.length})')
      ..writeln()
      ..writeln('| الاسم | الخط | المقاس | الوزن | ارتفاع السطر |')
      ..writeln('|---|---|---|---|---|');
    for (final s in texts) {
      final st = nodes[s['node_id']]?['style'] as Map<String, dynamic>?;
      buf.writeln(
        '| ${s['name']} | ${st?['fontFamily'] ?? '—'} '
        '| ${_n(st?['fontSize'])} | ${st?['fontWeight'] ?? '—'} '
        '| ${_n(st?['lineHeightPx'])} |',
      );
    }
    buf.writeln();
  }

  if (effects.isNotEmpty) {
    buf.writeln('## التأثيرات (${effects.length})');
    buf.writeln();
    for (final s in effects) {
      buf.writeln('- ${s['name']}  —  ${_effects(nodes[s['node_id']]) ?? '—'}');
    }
    buf.writeln();
  }

  final out = '$_cacheDir/_styles.md';
  File(out).writeAsStringSync(buf.toString());
  print('✅  $out   (${fills.length} لوناً · ${texts.length} نمط نصّ)');
}

Future<void> _cmdByName(String needle) async {
  final data = await _api('/v1/files/$_fileKey?depth=2');
  final doc = data['document'] as Map<String, dynamic>;
  final matches = <Map<String, dynamic>>[];

  for (final page in (doc['children'] as List? ?? [])) {
    for (final child in ((page as Map)['children'] as List? ?? [])) {
      final c = child as Map<String, dynamic>;
      if ((c['name'] as String).toLowerCase().contains(needle.toLowerCase())) {
        matches.add(c);
      }
    }
  }

  if (matches.isEmpty) {
    _die('لا إطار اسمه يحوي «$needle». جرّب --list.');
  }
  if (matches.length > 1) {
    print('⚠️  ${matches.length} إطاراً يطابق «$needle» — أسحبها كلها:\n');
  }
  for (final m in matches) {
    await _cmdNode(m['id'] as String, m['name'] as String);
    if (m != matches.last) await Future<void>.delayed(_throttle);
  }
}

Future<void> _cmdAll() async {
  final data = await _api('/v1/files/$_fileKey?depth=2');
  final doc = data['document'] as Map<String, dynamic>;
  final all = <Map<String, dynamic>>[];
  for (final page in (doc['children'] as List? ?? [])) {
    for (final child in ((page as Map)['children'] as List? ?? [])) {
      all.add(child as Map<String, dynamic>);
    }
  }
  print('📦  ${all.length} إطاراً — يُسحب واحداً واحداً بتهدئة.\n');
  for (var i = 0; i < all.length; i++) {
    print('[${i + 1}/${all.length}]');
    await _cmdNode(all[i]['id'] as String, all[i]['name'] as String);
    if (i < all.length - 1) await Future<void>.delayed(_throttle);
  }
}

Future<void> _cmdNode(String nodeId, String? knownName) async {
  final res = await _api(
    '/v1/files/$_fileKey/nodes?ids=${Uri.encodeComponent(nodeId)}',
  );
  final entry = (res['nodes'] as Map<String, dynamic>)[nodeId];
  if (entry == null) _die('لا عقدة بالمعرّف $nodeId — جرّب --list.');

  final node = (entry as Map<String, dynamic>)['document'] as Map<String, dynamic>;
  final name = knownName ?? node['name'] as String;
  final slug = _slug(name, nodeId);

  // 1) الشجرة مُقلَّمة
  final pruned = _prune(node, null);
  File('$_cacheDir/$slug.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(pruned));

  // 2) الخلاصة المقروءة
  final md = StringBuffer()
    ..writeln('# $name')
    ..writeln()
    ..writeln('- **العقدة:** `$nodeId`')
    ..writeln('- **الملف:** `$_fileKey`')
    ..writeln('- **الصورة:** `$slug.png`')
    ..writeln()
    ..writeln('```')
    ..write(_outline(node, null, ''))
    ..writeln('```')
    ..writeln()
    ..writeln('## الألوان المستعملة بهذا الإطار')
    ..writeln()
    ..writeln('| Hex | الدرجة | الإضاءة | مرّات |')
    ..writeln('|---|---|---|---|');
  final counts = <String, int>{};
  _collectColors(node, counts);
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sorted) {
    final hsl = _hsl(e.key);
    md.writeln('| `${e.key}` | ${hsl.$1} | ${hsl.$2} | ${e.value} |');
  }
  File('$_cacheDir/$slug.md').writeAsStringSync(md.toString());

  // 3) الصورة
  final img = await _api(
    '/v1/images/$_fileKey?ids=${Uri.encodeComponent(nodeId)}'
    '&format=png&scale=$_imageScale',
  );
  final url = (img['images'] as Map<String, dynamic>)[nodeId] as String?;
  if (url != null) {
    await _download(url, '$_cacheDir/$slug.png');
  } else {
    _warn('تعذّر تصدير صورة $nodeId — الشجرة والخلاصة محفوظتان.');
  }

  print('✅  $name');
  print('     $_cacheDir/$slug.png');
  print('     $_cacheDir/$slug.md');
  print('     $_cacheDir/$slug.json');
}

// ── Tree pruning ──────────────────────────────────────────────────────────────

/// شجرة الفيغما الخام تصل ميغابايتات للإطار الواحد — أغلبها مصفوفات هندسية
/// وحالات مكوّنات لا تُقرأ. هذه تحتفظ بما يُترجَم إلى Flutter وحده.
Map<String, dynamic> _prune(Map<String, dynamic> n, Map<String, dynamic>? parent) {
  final box = n['absoluteBoundingBox'] as Map<String, dynamic>?;
  final pBox = parent?['absoluteBoundingBox'] as Map<String, dynamic>?;

  final out = <String, dynamic>{
    'id': n['id'],
    'name': n['name'],
    'type': n['type'],
  };

  if (box != null) {
    out['w'] = _num(box['width']);
    out['h'] = _num(box['height']);
    // إزاحة نسبية للأب — المطلقة عديمة المعنى بـFlutter (F09).
    if (pBox != null) {
      out['dx'] = _num((box['x'] as num) - (pBox['x'] as num));
      out['dy'] = _num((box['y'] as num) - (pBox['y'] as num));
    }
  }

  final fill = _firstFillHex(n);
  if (fill != null) out['fill'] = fill;

  final grad = _gradient(n);
  if (grad != null) out['gradient'] = grad;

  final stroke = _firstHex((n['strokes'] as List?)?.cast<Map<String, dynamic>>());
  if (stroke != null) {
    out['border'] = stroke;
    if (n['strokeWeight'] != null) out['borderWidth'] = _num(n['strokeWeight']);
  }

  if (n['cornerRadius'] != null) out['radius'] = _num(n['cornerRadius']);
  if (n['rectangleCornerRadii'] != null) {
    out['radii'] = (n['rectangleCornerRadii'] as List).map(_num).toList();
  }
  if (n['opacity'] != null && (n['opacity'] as num) < 1) {
    out['opacity'] = _num(n['opacity']);
  }

  // Auto-layout ← يترجَم مباشرةً إلى Row/Column + spacing + Padding
  if (n['layoutMode'] != null && n['layoutMode'] != 'NONE') {
    out['layout'] = n['layoutMode']; // HORIZONTAL | VERTICAL
    if (n['itemSpacing'] != null) out['gap'] = _num(n['itemSpacing']);
    final pad = [
      _num(n['paddingTop'] ?? 0),
      _num(n['paddingRight'] ?? 0),
      _num(n['paddingBottom'] ?? 0),
      _num(n['paddingLeft'] ?? 0),
    ];
    if (pad.any((v) => v != 0)) out['padding'] = pad; // T R B L
    if (n['primaryAxisAlignItems'] != null) out['mainAxis'] = n['primaryAxisAlignItems'];
    if (n['counterAxisAlignItems'] != null) out['crossAxis'] = n['counterAxisAlignItems'];
  }

  if (n['type'] == 'TEXT') {
    out['text'] = n['characters'];
    final s = n['style'] as Map<String, dynamic>?;
    if (s != null) {
      out['font'] = {
        'family': s['fontFamily'],
        'size': _num(s['fontSize']),
        'weight': s['fontWeight'],
        if (s['lineHeightPx'] != null) 'lineHeight': _num(s['lineHeightPx']),
        if (s['letterSpacing'] != null && (s['letterSpacing'] as num) != 0)
          'letterSpacing': _num(s['letterSpacing']),
        if (s['textAlignHorizontal'] != null) 'align': s['textAlignHorizontal'],
      };
    }
  }

  final fx = _effects(n);
  if (fx != null) out['effects'] = fx;

  final children = (n['children'] as List?)?.cast<Map<String, dynamic>>();
  if (children != null && children.isNotEmpty) {
    out['children'] = children.map((c) => _prune(c, n)).toList();
  }
  return out;
}

// ── Readable outline ──────────────────────────────────────────────────────────

String _outline(Map<String, dynamic> n, Map<String, dynamic>? parent, String indent) {
  final p = _prune(n, parent);
  final bits = <String>[];

  if (p['w'] != null) bits.add('${p['w']}×${p['h']}');
  if (p['dx'] != null) bits.add('@(${p['dx']},${p['dy']})');
  if (p['layout'] != null) {
    final dir = p['layout'] == 'HORIZONTAL' ? 'Row' : 'Column';
    bits.add('$dir${p['gap'] != null ? ' gap ${p['gap']}' : ''}');
  }
  if (p['padding'] != null) bits.add('pad ${(p['padding'] as List).join('/')}');
  if (p['fill'] != null) bits.add('fill ${p['fill']}');
  if (p['gradient'] != null) bits.add('grad ${p['gradient']}');
  if (p['border'] != null) {
    bits.add('border ${p['border']}${p['borderWidth'] != null ? ' ${p['borderWidth']}' : ''}');
  }
  if (p['radius'] != null) bits.add('r${p['radius']}');
  if (p['radii'] != null) bits.add('r${(p['radii'] as List).join('/')}');
  if (p['opacity'] != null) bits.add('opacity ${p['opacity']}');
  if (p['effects'] != null) bits.add(p['effects'] as String);

  final font = p['font'] as Map<String, dynamic>?;
  if (font != null) {
    bits.add('${font['size']}/${font['weight']} ${font['family']}');
    if (font['align'] != null && font['align'] != 'LEFT') bits.add('${font['align']}');
  }

  final label = p['text'] != null
      ? '"${(p['text'] as String).replaceAll('\n', '⏎').trim()}"'
      : p['name'];

  final buf = StringBuffer()
    ..writeln('$indent${_pad(p['type'] as String, 9)} $label   ${bits.join('  ')}');

  for (final child in ((n['children'] as List?) ?? [])) {
    buf.write(_outline(child as Map<String, dynamic>, n, '$indent  '));
  }
  return buf.toString();
}

void _collectColors(Map<String, dynamic> n, Map<String, int> out) {
  for (final key in ['fills', 'strokes']) {
    for (final paint in ((n[key] as List?) ?? [])) {
      final hex = _paintHex(paint as Map<String, dynamic>);
      if (hex != null) out[hex] = (out[hex] ?? 0) + 1;
    }
  }
  for (final child in ((n['children'] as List?) ?? [])) {
    _collectColors(child as Map<String, dynamic>, out);
  }
}

// ── Paint helpers ─────────────────────────────────────────────────────────────

String? _firstFillHex(Map<String, dynamic>? n) =>
    _firstHex((n?['fills'] as List?)?.cast<Map<String, dynamic>>());

String? _firstHex(List<Map<String, dynamic>>? paints) {
  for (final p in (paints ?? const <Map<String, dynamic>>[])) {
    final hex = _paintHex(p);
    if (hex != null) return hex;
  }
  return null;
}

String? _paintHex(Map<String, dynamic> paint) {
  if (paint['visible'] == false) return null;
  if (paint['type'] != 'SOLID') return null;
  final c = paint['color'] as Map<String, dynamic>?;
  if (c == null) return null;

  String ch(Object? v) =>
      (((v as num?) ?? 0) * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  final hex = '#${ch(c['r'])}${ch(c['g'])}${ch(c['b'])}'.toUpperCase();

  final alpha = ((paint['opacity'] as num?) ?? 1) * ((c['a'] as num?) ?? 1);
  return alpha < 0.999 ? '$hex@${(alpha * 100).round()}%' : hex;
}

String? _gradient(Map<String, dynamic> n) {
  for (final paint in ((n['fills'] as List?) ?? [])) {
    final p = paint as Map<String, dynamic>;
    if (p['visible'] == false) continue;
    final type = p['type'] as String?;
    if (type == null || !type.startsWith('GRADIENT')) continue;
    final stops = ((p['gradientStops'] as List?) ?? []).map((s) {
      final st = s as Map<String, dynamic>;
      return _paintHex({'type': 'SOLID', 'color': st['color']}) ?? '?';
    }).join(' → ');
    return '${type.replaceFirst('GRADIENT_', '').toLowerCase()} $stops';
  }
  return null;
}

String? _effects(Map<String, dynamic>? n) {
  final list = (n?['effects'] as List?) ?? [];
  final parts = <String>[];
  for (final e in list) {
    final fx = e as Map<String, dynamic>;
    if (fx['visible'] == false) continue;
    final off = fx['offset'] as Map<String, dynamic>?;
    final color = fx['color'] == null
        ? ''
        : ' ${_paintHex({'type': 'SOLID', 'color': fx['color']})}';
    switch (fx['type']) {
      case 'DROP_SHADOW':
      case 'INNER_SHADOW':
        final dx = _num(off?['x'] ?? 0);
        final dy = _num(off?['y'] ?? 0);
        final blur = _num(fx['radius']);
        final spread = _num(fx['spread'] ?? 0);
        // A shadow with no offset and no blur is not a shadow — it is a
        // **ring**. Figma exports a 1px outline that way, and rendering it as
        // "shadow(0,0 blur 0)" makes it read as nothing at all: the logo's
        // gold ring and every input's hairline border were both present in the
        // first digest and both were missed when the page was built from it.
        if (dx == 0 && dy == 0 && blur == 0) {
          parts.add('ring ${spread == 0 ? 1 : spread}$color');
        } else {
          final spreadPart = spread == 0 ? '' : ' spread $spread';
          parts.add('shadow($dx,$dy blur $blur$spreadPart$color)');
        }
      case 'LAYER_BLUR':
      case 'BACKGROUND_BLUR':
        parts.add('blur ${_num(fx['radius'])}');
    }
  }
  return parts.isEmpty ? null : parts.join(' ');
}

// ── Color math ────────────────────────────────────────────────────────────────

/// (الدرجة، الإضاءة) — الدرجة تكشف تنافر لوحةٍ باردة مع هويةٍ دافئة بنظرة.
(String, String) _hsl(String hex) {
  final h = hex.replaceAll('#', '').split('@').first;
  if (h.length < 6) return ('—', '—');
  final r = int.parse(h.substring(0, 2), radix: 16) / 255;
  final g = int.parse(h.substring(2, 4), radix: 16) / 255;
  final b = int.parse(h.substring(4, 6), radix: 16) / 255;

  final max = [r, g, b].reduce((a, x) => a > x ? a : x);
  final min = [r, g, b].reduce((a, x) => a < x ? a : x);
  final d = max - min;
  final l = (max + min) / 2;

  var hue = 0.0;
  if (d != 0) {
    if (max == r) {
      hue = 60 * (((g - b) / d) % 6);
    } else if (max == g) {
      hue = 60 * ((b - r) / d + 2);
    } else {
      hue = 60 * ((r - g) / d + 4);
    }
  }
  final hueLabel = d < 0.004 ? 'محايد' : '${hue.round()}°';
  return (hueLabel, '${(l * 100).toStringAsFixed(1)}%');
}

// ── HTTP ──────────────────────────────────────────────────────────────────────

Future<Map<String, dynamic>> _api(String path) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final req = await client.getUrl(Uri.https(_apiHost, path.split('?').first,
        _queryOf(path)));
    req.headers.set('X-Figma-Token', _token);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();

    switch (res.statusCode) {
      case 200:
        return jsonDecode(body) as Map<String, dynamic>;
      case 403:
        // `/styles` يقع تحت صلاحية أخرى غير التي يحتاجها محتوى الملف. تمييز
        // الحالتين هنا يمنع مطاردة توكنٍ سليم: كل شيء آخر يعمل، وهذا وحده يُرفض.
        _die(path.contains('/styles')
            ? 'الأنماط المنشورة مرفوضة (403).\n'
                '    `/styles` يحتاج صلاحية «Library content: read» —\n'
                '    وهي غير «File content: read» التي يحتاجها سحب الإطارات.\n'
                '    أضفها للتوكن، أو تجاهل الأمر: جدول الألوان بذيل كل\n'
                '    `<slug>.md` يعطي اللوحة نفسها مستخرَجةً من الإطارات.'
            : 'التوكن مرفوض (403).\n'
                '    تأكّد أنه صالح وأن صلاحيته تشمل «File content: read».');
      case 404:
        _die('الملف غير موجود (404) — راجع مفتاح الملف بـ$_configFile.');
      case 429:
        _die('تجاوزتَ حدّ الطلبات (429). انتظر دقيقة ثم أعد المحاولة.');
      default:
        _die('الفيغما ردّ ${res.statusCode}:\n    $body');
    }
  } on SocketException catch (e) {
    _die('تعذّر الوصول إلى $_apiHost — ${e.message}');
  } finally {
    client.close();
  }
}

Map<String, String>? _queryOf(String path) {
  final i = path.indexOf('?');
  if (i == -1) return null;
  return Uri.splitQueryString(path.substring(i + 1));
}

Future<void> _download(String url, String out) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final res = await (await client.getUrl(Uri.parse(url))).close();
    if (res.statusCode != 200) {
      _warn('تنزيل الصورة ردّ ${res.statusCode} — تُخطَّى.');
      return;
    }
    final bytes = await res.fold<List<int>>(<int>[], (b, d) => b..addAll(d));
    File(out).writeAsBytesSync(bytes);
  } finally {
    client.close();
  }
}

// ── Token & file key ──────────────────────────────────────────────────────────

String _resolveToken() {
  final env = Platform.environment['FIGMA_TOKEN'];
  if (env != null && env.trim().isNotEmpty) return env.trim();

  final f = File(_tokenFile);
  if (f.existsSync()) {
    final t = f.readAsStringSync().trim();
    if (t.isNotEmpty) return t;
  }

  _die('''لا توكن.

    أنشئ واحداً من: figma.com → أيقونتك → Settings → Security
                   → Personal access tokens → Generate new token
    الصلاحية المطلوبة: File content = Read-only  (لا شيء غيرها)

    ثم احفظه — إحدى طريقتين:
      1. اكتبه بملف  $_tokenFile        ← الموصى به (مُتجاهَل من git)
      2. أو صدّره:   \$env:FIGMA_TOKEN = "figd_..."

    ⚠️ لا تمرّره كوسيط سطر أوامر ولا تلصقه بمحادثة.''');
}

String _resolveFileKey() {
  final f = File(_configFile);
  if (f.existsSync()) {
    final cfg = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final key = cfg['fileKey'] as String?;
    if (key != null && key.isNotEmpty) return key;
  }
  _die('لا مفتاح ملف.\n'
      '    شغّل مرّة واحدة:\n'
      '      dart run scripts/pull_figma.dart --file "<الصق رابط الفيغما>"');
}

void _saveConfig(String key) {
  Directory(_root).createSync(recursive: true);
  File(_configFile).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'fileKey': key})}\n',
  );
}

/// يقبل الرابط كاملاً أو المفتاح وحده.
///   https://www.figma.com/design/AbC123xyz/My-App?node-id=1-57  →  AbC123xyz
String _extractFileKey(String input) {
  final s = input.trim();
  if (!s.contains('/')) return s;
  final m = RegExp(r'figma\.com/(?:file|design|proto)/([A-Za-z0-9]+)').firstMatch(s);
  if (m != null) return m.group(1)!;
  _die('تعذّر استخراج مفتاح الملف من:\n    $s');
}

// ── Small helpers ─────────────────────────────────────────────────────────────

String? _valueOf(List<String> args, String flag) {
  final i = args.indexOf(flag);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}

/// الأرقام تصل كسوراً عشرية طويلة — تُقرّب، والصحيح يفقد `.0`.
num _num(Object? v) {
  final d = ((v as num?) ?? 0).toDouble();
  final r = (d * 100).round() / 100;
  return r == r.roundToDouble() ? r.round() : r;
}

String _n(Object? v) => _num(v).toString();

String _pad(String s, int width) =>
    s.length >= width ? s : s + ' ' * (width - s.length);

/// أسماء الإطارات عربية غالباً، وأسماء الملفات يجب أن تبقى ASCII.
///
/// **ومعرّف العقدة يُلحَق دائماً** — لا للجمال بل للصحّة: ملفات الفيغما المستوردة
/// (html.to.design وأمثالها) تُنتج عشرات الإطارات بالاسم نفسه حرفياً
/// (`Background+Shadow` × ٧ بهذا المشروع)، فبلا المعرّف يدهس كل سحبٍ سابقه
/// **بصمت** — ويبقى بالذاكرة إطارٌ واحد يُظنّ أنه سبعة.
String _slug(String name, String id) {
  var s = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  // أسماء html.to.design رابطٌ كامل بعلامة مائية — تُقصّ.
  if (s.length > 40) s = s.substring(0, 40).replaceAll(RegExp(r'_+$'), '');
  final suffix = id.replaceAll(':', '_');
  return s.isEmpty ? 'node_$suffix' : '${s}_$suffix';
}

Never _die(String msg) {
  print('\n❌  $msg\n');
  exit(1);
}

void _warn(String msg) => print('⚠️  $msg');
