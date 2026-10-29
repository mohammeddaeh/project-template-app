// ignore_for_file: avoid_print
/// روابط التوثيق المعطوبة — كل رابط Markdown نسبيّ بملف `.md` يجب أن يصل ملفاً
/// أو مجلداً موجوداً.
///
/// رابطٌ معطوب لا يُفشل شيئاً آخر: `dart analyze` لا يقرأ Markdown، والاختبارات
/// لا تفتح الوثائق. فيبقى حتى يضغطه قارئٌ يحتاجه — وهو عادةً من يتعلّم القالب.
///
/// ويُفحص كذلك رابطُ GitHub الكامل إلى `_template/` (القاعدة بـ`CLAUDE.md`)
/// حين يكون المجلد موجوداً محلياً — أي بمستودع القالب وحده. بمشروعٍ مبنيّ لا
/// `_template/` فيه، فيُتجاوز.
///
/// لا يُفحص: روابط الويب الأخرى (تحتاج شبكة) · المراسي `#…` · ما داخل كتل الكود.
///
/// تشغيل من جذر المشروع:
///   dart run scripts/check_docs.dart
///
/// خروج `1` عند أي رابط معطوب — فاحصٌ حاجب بالـCI.
library;

import 'dart:io';

const _skipDirs = {
  'build',
  '.dart_tool',
  '.git',
  'node_modules',
  '.idea',
  'ios/Pods',
};
const _templateBlob =
    'https://github.com/mohammeddaeh/project-template-app/blob/master/';
const _templateTree =
    'https://github.com/mohammeddaeh/project-template-app/tree/master/';

final _link = RegExp(r'\]\(([^)\s]+)\)');
final _fence = RegExp(r'^\s*(```|~~~)');

void main() {
  print('\n🔗  check_docs — روابط التوثيق\n');
  final hasTemplateDir = Directory('_template').existsSync();

  var files = 0;
  final broken = <String>[];
  for (final file in _markdownFiles(Directory.current)) {
    files++;
    final path = _relative(file.path);
    var inFence = false;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      if (_fence.hasMatch(lines[i])) {
        inFence = !inFence;
        continue;
      }
      if (inFence) continue;
      for (final match in _link.allMatches(lines[i])) {
        final target = _resolve(
          match.group(1)!,
          file.parent.path,
          hasTemplateDir,
        );
        if (target == null) continue;
        if (!File(target).existsSync() && !Directory(target).existsSync()) {
          broken.add('   $path:${i + 1}  →  ${match.group(1)}');
        }
      }
    }
  }

  broken.forEach(print);
  print('\n   فُحص $files ملفاً.');
  if (broken.isEmpty) {
    print('✅  لا رابط معطوب.\n');
    return;
  }
  print('❌  ${broken.length} رابطاً معطوباً.\n');
  exit(1);
}

/// المسار المحلي الذي يجب أن يوجد — أو `null` لرابطٍ لا يُفحص.
String? _resolve(String raw, String fromDir, bool hasTemplateDir) {
  var target = raw.split('#').first;
  if (target.isEmpty) return null;
  for (final prefix in [_templateBlob, _templateTree]) {
    if (target.startsWith(prefix)) {
      final local = target.substring(prefix.length);
      if (!local.startsWith('_template/') || !hasTemplateDir) return null;
      return Uri.decodeComponent(local);
    }
  }
  if (target.contains('://') || target.startsWith('mailto:')) return null;
  target = Uri.decodeComponent(target);
  return '$fromDir${Platform.pathSeparator}$target';
}

Iterable<File> _markdownFiles(Directory dir) sync* {
  for (final entity in dir.listSync()) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (entity is Directory) {
      if (_skipDirs.contains(name) ||
          _skipDirs.contains(_relative(entity.path))) {
        continue;
      }
      yield* _markdownFiles(entity);
    } else if (entity is File && name.endsWith('.md')) {
      yield entity;
    }
  }
}

String _relative(String path) {
  final root = Directory.current.path;
  final rel = path.startsWith(root) ? path.substring(root.length + 1) : path;
  return rel.replaceAll(r'\', '/');
}
