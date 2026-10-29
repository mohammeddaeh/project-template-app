// ignore_for_file: avoid_print
/// يُنزل قواعد `<style>` بملف SVG إلى سماتٍ مباشرة على عناصره — لأي SVG.
///
/// `flutter_svg` **لا يطبّق `<style>`**. وملفّات التصدير (Illustrator خاصّةً)
/// تلوّن بالأصناف (`.b{fill:#f7bd31}`)، فيُرسم الشكل كلّه أسود بلا أي خطأ،
/// والمتصفّح يعرضه ملوّناً. الهندسة لا تُلمس: كل عنصرٍ بـ`class="x"` يكسب
/// الخصائص التي يعلنها صنفه (`fill` · `stroke-width` · `clip-path` …) سماتٍ
/// بنفس الاسم، ويُحذف `class` وكتلة `<style>`.
///
/// تشغيل من جذر المشروع:
///   dart run scripts/svg_inline_styles.dart assets/images/logo.svg [...]
///
/// والحارس: `test/svg_no_style_test.dart` — لا `<style>` ولا `class=` بأي SVG
/// تحت `assets/`.
library;

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('usage: dart run scripts/svg_inline_styles.dart <file.svg>...');
    exit(64);
  }
  for (final path in args) {
    final file = File(path);
    final before = file.readAsStringSync();
    final after = inlineSvgStyles(before);
    if (after == before) {
      print('  =  $path (no <style>)');
      continue;
    }
    file.writeAsStringSync(after);
    print('  ✓  $path');
  }
}

final _style = RegExp(r'<style[^>]*>(.*?)</style>', dotAll: true);
final _rule = RegExp(r'([^{}]+)\{([^}]*)\}');
final _decl = RegExp(r'([\w-]+)\s*:\s*([^;]+)');
final _tag = RegExp(r'<(\w+)((?:\s+[\w:-]+="[^"]*")*?)(\s*/?)>');
final _class = RegExp(r'\s*class="([^"]*)"');

/// [svg] with every class rule of its `<style>` blocks written onto the
/// elements that use it, and the blocks removed. Unchanged when there is none.
String inlineSvgStyles(String svg) {
  final blocks = _style.allMatches(svg).toList();
  if (blocks.isEmpty) return svg;

  final rules = <String, Map<String, String>>{};
  for (final block in blocks) {
    for (final rule in _rule.allMatches(block.group(1)!)) {
      final decls = {
        for (final d in _decl.allMatches(rule.group(2)!))
          d.group(1)!: d.group(2)!.trim(),
      };
      for (final selector in rule.group(1)!.split(',')) {
        final name = selector.trim().replaceFirst(RegExp(r'^\.'), '');
        if (name.isNotEmpty) (rules[name] ??= {}).addAll(decls);
      }
    }
  }

  final out = svg.replaceAllMapped(_tag, (m) {
    final attrs = m.group(2)!;
    final cls = _class.firstMatch(attrs);
    if (cls == null) return m.group(0)!;
    final extra = <String, String>{};
    for (final name in cls.group(1)!.split(RegExp(r'\s+'))) {
      extra.addAll(rules[name] ?? const {});
    }
    final buffer = StringBuffer(attrs.replaceFirst(_class, ''));
    extra.forEach((k, v) => buffer.write(' $k="${v.replaceAll('"', "'")}"'));
    return '<${m.group(1)}$buffer${m.group(3)}>';
  });
  return out.replaceAll(_style, '');
}
