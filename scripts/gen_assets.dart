// ignore_for_file: avoid_print
/// Scans assets/ and generates lib/resources/assets.gen.dart
///
/// يدعم المجلدات المتداخلة بأي عمق:
///   assets/images/vectors/logo.svg  →  Assets.images.vectors.logoSvg
///   assets/vectors/logo.svg         →  Assets.vectors.logoSvg
///
/// تسمية الـ getters:
///   SVG (بلا تعارض)   → camelCase(stem) + 'Svg'      مثال: logo.svg → logoSvg
///   PNG (بلا تعارض)   → camelCase(stem)               مثال: banner.png → banner
///   تعارض             → camelCase(stem) + لاحقة الامتداد  مثال: logo.{svg,png} → logoSvg / logoPng
///
/// تشغيل:
///   dart run scripts/gen_assets.dart          — مسح + توليد
///   dart run scripts/gen_assets.dart --check  — فحص pubspec فقط
library;

import 'dart:io';

// ── Config ────────────────────────────────────────────────────────────────────

const _excludedFolders  = {'fonts', 'translations', 'app_icons'};
const _vectorExtensions = {'.svg'};
const _rasterExtensions = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.avif'};
const _dataExtensions   = {'.json'}; // Lottie animations & other JSON assets
final  _allExtensions   = {..._vectorExtensions, ..._rasterExtensions, ..._dataExtensions};

const _outFile    = 'lib/resources/assets.gen.dart';
const _barrelFile = 'lib/resources/assets.dart';
const _assetsRoot = 'assets';

// ── Tree node ─────────────────────────────────────────────────────────────────

class _FolderNode {
  final String name;       // اسم المجلد فقط: 'vectors'
  final String assetPath;  // المسار الكامل: 'assets/images/vectors'
  final List<_Asset>      files;
  final List<_FolderNode> subfolders;

  _FolderNode({
    required this.name,
    required this.assetPath,
    required this.files,
    required this.subfolders,
  });

  bool get hasContent => files.isNotEmpty || subfolders.isNotEmpty;
}

// ── Entry point ───────────────────────────────────────────────────────────────

void main(List<String> args) {
  final checkOnly = args.contains('--check');

  print('\n🎨  gen_assets — scanning $_assetsRoot/\n');

  final dir = Directory(_assetsRoot);
  if (!dir.existsSync()) _die('$_assetsRoot/ not found — run from project root.');

  final topFolders = _collectTopLevel(dir);
  if (topFolders.isEmpty) { print('⚠️  No image assets found.'); return; }

  print('');
  if (!checkOnly) {
    _generate(topFolders);
    _updateBarrel();
    _deleteObsoleteFiles();
  }

  _syncPubspec(topFolders, dryRun: checkOnly);

  if (!checkOnly) {
    print('\n📋  Usage:');
    _printUsage(topFolders, 'Assets');
    print('');
  }
}

// ── Collect ───────────────────────────────────────────────────────────────────

List<_FolderNode> _collectTopLevel(Directory root) {
  final result  = <_FolderNode>[];
  final entries = root.listSync()..sort((a, b) => a.path.compareTo(b.path));

  for (final entity in entries) {
    if (entity is! Directory) continue;
    final name = _basename(entity.path);
    if (_excludedFolders.contains(name)) {
      print('⏭   Skip: $name/');
      continue;
    }
    final node = _buildNode(entity, name, '$_assetsRoot/$name');
    if (!node.hasContent) continue;
    result.add(node);
    _printTree(node, '');
  }
  return result;
}

_FolderNode _buildNode(Directory dir, String name, String assetPath) {
  final directFiles = <_Asset>[];
  final children    = <_FolderNode>[];

  final entries = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
  for (final entity in entries) {
    if (entity is File && _allExtensions.contains(_ext(entity.path))) {
      directFiles.add(_Asset(entity));
    } else if (entity is Directory) {
      final subName = _basename(entity.path);
      final child   = _buildNode(entity, subName, '$assetPath/$subName');
      if (child.hasContent) children.add(child);
    }
  }

  _resolveGetterNames(directFiles);
  return _FolderNode(
    name: name, assetPath: assetPath, files: directFiles, subfolders: children,
  );
}

void _printTree(_FolderNode node, String indent) {
  final info = [
    if (node.files.isNotEmpty)       '${node.files.length} ملف',
    if (node.subfolders.isNotEmpty)  '${node.subfolders.length} مجلد فرعي',
  ].join('، ');
  print('$indent📁  ${node.name}/  ($info)');
  for (final f in node.files) {
    print('$indent     ✦  ${f.getterName}  →  ${f.assetPath}');
  }
  for (final sub in node.subfolders) {
    _printTree(sub, '$indent   ');
  }
}

// ── Getter name resolution ────────────────────────────────────────────────────

void _resolveGetterNames(List<_Asset> assets) {
  // Group by stem to detect collisions
  final byStem = <String, List<_Asset>>{};
  for (final a in assets) {
    byStem.putIfAbsent(a.stem, () => []).add(a);
  }
  for (final group in byStem.entries) {
    final collision = group.value.length > 1;
    for (final asset in group.value) {
      final isVector = _vectorExtensions.contains('.${asset.ext}');
      asset.getterName = collision
          ? '${_camel(asset.stem)}${_extSuffix(asset.ext)}'
          : isVector
              ? '${_camel(asset.stem)}Svg'
              : _camel(asset.stem);
    }
  }
}

// ── Code generation ───────────────────────────────────────────────────────────

void _generate(List<_FolderNode> topFolders) {
  final buf = StringBuffer()
    ..writeln('// GENERATED CODE — DO NOT MODIFY BY HAND')
    ..writeln('// Run: dart run scripts/gen_assets.dart')
    ..writeln('// ignore_for_file: constant_identifier_names')
    ..writeln()
    ..writeln('abstract final class Assets {');

  for (final node in topFolders) {
    buf.writeln('  static const ${_camel(node.name)} = _Assets${_pascal(node.name)}();');
  }
  buf.writeln('}');

  for (final node in topFolders) {
    _writeClass(buf, node, '_Assets');
  }
  buf.writeln();

  File(_outFile).writeAsStringSync(buf.toString());
  print('✅  $_outFile');
}

/// classPrefix مثال: '_Assets' أو '_AssetsImages'
void _writeClass(StringBuffer buf, _FolderNode node, String classPrefix) {
  final className = '$classPrefix${_pascal(node.name)}';

  buf
    ..writeln()
    ..writeln('final class $className {')
    ..writeln('  const $className();');

  // getter لكل مجلد فرعي — يُقرأ عبر instance بشكل طبيعي
  for (final sub in node.subfolders) {
    final subClass     = '$className${_pascal(sub.name)}';
    final accessorName = _camel(sub.name);
    buf.writeln('  $subClass get $accessorName => const $subClass();');
  }

  // getter لكل ملف مباشر
  for (final asset in node.files) {
    buf
      ..writeln()
      ..writeln("  /// `${asset.assetPath}`")
      ..writeln("  String get ${asset.getterName} => '${asset.assetPath}';");
  }

  buf.writeln('}');

  // توليد كلاسات المجلدات الفرعية
  for (final sub in node.subfolders) {
    _writeClass(buf, sub, className);
  }
}

void _updateBarrel() {
  File(_barrelFile).writeAsStringSync("export 'assets.gen.dart';\n");
  print('✅  $_barrelFile  →  re-exports assets.gen.dart');
}

void _deleteObsoleteFiles() {
  for (final path in [
    'lib/resources/vectors.dart',
    'lib/resources/icons.dart',
    'lib/resources/images.dart',
  ]) {
    final f = File(path);
    if (f.existsSync()) { f.deleteSync(); print('🗑   Deleted $path'); }
  }
}

// ── Pubspec sync ──────────────────────────────────────────────────────────────

void _syncPubspec(List<_FolderNode> topFolders, {required bool dryRun}) {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) { _warn('pubspec.yaml not found'); return; }

  var content = pubspec.readAsStringSync();
  var changed = false;

  // جمع كل المسارات الورقية (التي تحتوي ملفات مباشرة)
  final needed = <String>[];
  for (final node in topFolders) {
    _collectLeafPaths(node, needed);
  }

  for (final assetPath in needed) {
    if (content.contains('$assetPath/')) continue;
    if (dryRun) { print('⚠️  Missing in pubspec: - $assetPath/'); continue; }

    // دعم كلا النوعين LF و CRLF
    var idx = content.indexOf('\r\n  assets:\r\n');
    final crlf = idx != -1;
    if (idx == -1) idx = content.indexOf('\n  assets:\n');
    if (idx == -1) { _warn('Cannot find flutter → assets: in pubspec.yaml'); break; }

    final marker   = crlf ? '\r\n  assets:\r\n' : '\n  assets:\n';
    final eol      = crlf ? '\r\n' : '\n';
    final insertAt = idx + marker.length;
    content = '${content.substring(0, insertAt)}    - $assetPath/$eol'
              '${content.substring(insertAt)}';
    print('➕  pubspec.yaml ← $assetPath/');
    changed = true;
  }

  if (changed) pubspec.writeAsStringSync(content);
}

void _collectLeafPaths(_FolderNode node, List<String> paths) {
  if (node.files.isNotEmpty) paths.add(node.assetPath);
  for (final sub in node.subfolders) {
    _collectLeafPaths(sub, paths);
  }
}

// ── Print usage ───────────────────────────────────────────────────────────────

void _printUsage(List<_FolderNode> nodes, String prefix) {
  for (final node in nodes) {
    _printNodeUsage(node, '$prefix.${_camel(node.name)}');
  }
}

void _printNodeUsage(_FolderNode node, String prefix) {
  for (final a in node.files) {
    print('   $prefix.${a.getterName}');
  }
  for (final sub in node.subfolders) {
    _printNodeUsage(sub, '$prefix.${_camel(sub.name)}');
  }
}

// ── Asset model ───────────────────────────────────────────────────────────────

class _Asset {
  final String assetPath;
  final String stem;
  final String ext;
  String getterName = '';

  _Asset(File file)
      : assetPath = _toAssetPath(file.path),
        stem      = _stem(file.path),
        ext       = _ext(file.path).replaceFirst('.', '');

  static String _toAssetPath(String p) {
    final n = p.replaceAll('\\', '/');
    final i = n.indexOf('$_assetsRoot/');
    return i == -1 ? n : n.substring(i);
  }
}

// ── String helpers ────────────────────────────────────────────────────────────

String _pascal(String s) => s
    .split('_')
    .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
    .join();

String _camel(String s) {
  final p = _pascal(s);
  return p.isEmpty ? '' : p[0].toLowerCase() + p.substring(1);
}

String _extSuffix(String ext) =>
    ext.isEmpty ? '' : ext[0].toUpperCase() + ext.substring(1);

String _basename(String p) => p.replaceAll('\\', '/').split('/').last;

String _stem(String p) {
  final name = _basename(p);
  final i    = name.lastIndexOf('.');
  return i == -1 ? name : name.substring(0, i);
}

String _ext(String p) {
  final name = _basename(p);
  final i    = name.lastIndexOf('.');
  return i == -1 ? '' : name.substring(i).toLowerCase();
}

void _die(String msg)  { print('❌  $msg'); exit(1); }
void _warn(String msg) => print('⚠️  $msg');
