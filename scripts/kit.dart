// ignore_for_file: avoid_print
/// حِزَم الأجهزة — تركيبٌ بأمرٍ واحد وإزالةٌ بأمرٍ واحد.
///
/// | الأمر | ما يفعله |
/// |---|---|
/// | `list` | المتاح بـ`packages/` · المركَّب · أذوناتُ كلٍّ |
/// | `add <name>` | تبعيةُ `path` بـ`pubspec.yaml` · سطرُ تسجيلٍ بـ`kits.g.dart` · أعلامُ الأذونات بـ`AppFeatures` ثم مزامنتُها · `flutter pub get` |
/// | `remove <name>` | عكسُ `add` حرفاً بحرف — **والجولة تترك `git diff` فارغاً** |
/// | `test` | اختباراتُ `kit_contracts` وكلِّ kit مركَّبة (`flutter test` بالجذر لا يراها) |
///
/// ⛔ **ولا يُعدَّل `lib/core/di/kits.g.dart` باليد** — هذا السكربت يكتبه كاملاً.
/// التفصيل: `readme/modules/24_DEVICE_KITS.md`.
///
/// تشغيل من جذر المشروع:
///   dart run scripts/kit.dart list
///   dart run scripts/kit.dart add voice
library;

import 'dart:io';

import 'src/kits.dart';

const _pubspec = 'pubspec.yaml';
const _appFeatures = 'lib/core/platform/features/app_features.dart';

Future<void> main(List<String> args) async {
  final command = args.isEmpty ? 'list' : args.first;
  switch (command) {
    case 'list':
      _list();
    case 'add' when args.length == 2:
      await _add(args[1]);
    case 'remove' when args.length == 2:
      await _remove(args[1]);
    case 'test':
      await _test();
    default:
      _die(
        'الاستخدام: dart run scripts/kit.dart list | add <name> | remove <name> | test',
      );
  }
}

Map<String, KitManifest> _available() {
  final dir = Directory(kitsDir);
  if (!dir.existsSync()) return {};
  final out = <String, KitManifest>{};
  for (final d in dir.listSync().whereType<Directory>()) {
    final manifest = File('${d.path}/kit.json');
    if (!manifest.existsSync()) continue;
    final kit = KitManifest.fromJson(manifest.readAsStringSync());
    out[kit.name] = kit;
  }
  return out;
}

void _list() {
  final available = _available();
  final installed = installedKits(File(_pubspec).readAsStringSync());
  print(
    '\n🧩  حِزَم الأجهزة — ${installed.length} مركَّبة من ${available.length}\n',
  );
  if (available.isEmpty) {
    print('   لا kit بـ$kitsDir/ بعد.\n');
    return;
  }
  for (final kit in available.values) {
    final mark = installed.contains(kit.name) ? '✓' : '·';
    final perms = kit.permissions.isEmpty
        ? ''
        : '  (${kit.permissions.join(' · ')})';
    print('   $mark ${kit.name}$perms');
  }
  print('');
}

Future<void> _add(String name) async {
  final available = _available();
  final kit =
      available[name] ??
      _die('لا kit باسم "$name" — المتاح: ${available.keys.join(' · ')}');

  final pubspec = File(_pubspec).readAsStringSync();
  if (installedKits(pubspec).contains(name)) {
    print('   $name مركَّبة أصلاً.');
    return;
  }
  final kitsSource = _readKitsFile();
  final enabled = enabledFlags(kitsSource);

  var features = File(_appFeatures).readAsStringSync();
  for (final flag in kit.permissions) {
    if (flagValue(features, flag)) continue;
    features = setFlag(features, flag, true);
    (enabled[name] ??= []).add(flag);
  }

  final next = addKitDependency(pubspec, name);
  _write(next, features, available, enabled);
  await _afterChange(permissionsChanged: enabled[name] != null);
  print('   ✓ $name مركَّبة.');
}

Future<void> _remove(String name) async {
  final available = _available();
  final pubspec = File(_pubspec).readAsStringSync();
  if (!installedKits(pubspec).contains(name)) {
    print('   $name غير مركَّبة.');
    return;
  }
  final enabled = enabledFlags(_readKitsFile());
  final remaining = installedKits(pubspec).where((k) => k != name).toList();

  var features = File(_appFeatures).readAsStringSync();
  final released = enabled.remove(name) ?? const <String>[];
  for (final flag in released) {
    // علَمٌ أشعلته هذه وتحتاجه kit باقية ⇐ ينتقل سجلُّه إليها ولا يُطفأ.
    final heir = remaining.firstWhere(
      (k) => available[k]?.permissions.contains(flag) ?? false,
      orElse: () => '',
    );
    if (heir.isEmpty) {
      features = setFlag(features, flag, false);
    } else {
      (enabled[heir] ??= []).add(flag);
    }
  }

  _write(removeKitDependency(pubspec, name), features, available, enabled);
  await _afterChange(permissionsChanged: released.isNotEmpty);
  print('   ✓ $name أُزيلت.');
}

void _write(
  String pubspec,
  String features,
  Map<String, KitManifest> available,
  Map<String, List<String>> enabled,
) {
  final installed = [
    for (final n in installedKits(pubspec))
      available[n] ?? _die('kit "$n" بـpubspec.yaml ولا بيان لها بـ$kitsDir/'),
  ];
  File(_pubspec).writeAsStringSync(pubspec);
  File(_appFeatures).writeAsStringSync(features);
  File(kitsFile).writeAsStringSync(renderKitsFile(installed, enabled));
  if (Directory('android/app').existsSync()) {
    File(kitsProguardFile).writeAsStringSync(renderProguardFile(installed));
  }
}

String _readKitsFile() {
  final f = File(kitsFile);
  return f.existsSync() ? f.readAsStringSync() : '';
}

Future<void> _afterChange({required bool permissionsChanged}) async {
  await _run('flutter', ['pub', 'get']);
  await _run('dart', ['format', kitsFile]);
  if (permissionsChanged) {
    await _run('dart', ['run', 'scripts/sync_platform_permissions.dart']);
  }
}

Future<void> _test() async {
  final installed = installedKits(File(_pubspec).readAsStringSync());
  var failed = false;
  for (final package in [
    'kit_contracts',
    for (final k in installed) 'kit_$k',
  ]) {
    print('── $package');
    final dir = '$kitsDir/$package';
    final pure = !File(
      '$dir/pubspec.yaml',
    ).readAsStringSync().contains('sdk: flutter');
    // A fresh checkout (CI) has resolved the app, not each kit's dev deps.
    await _run(pure ? 'dart' : 'flutter', [
      'pub',
      'get',
    ], workingDirectory: dir);
    final code = await _run(
      pure ? 'dart' : 'flutter',
      ['test'],
      workingDirectory: dir,
      mustPass: false,
    );
    failed |= code != 0;
  }
  if (failed) exit(1);
}

Future<int> _run(
  String exe,
  List<String> args, {
  String? workingDirectory,
  bool mustPass = true,
}) async {
  final p = await Process.start(
    exe,
    args,
    workingDirectory: workingDirectory,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await p.exitCode;
  if (mustPass && code != 0) _die('فشل: $exe ${args.join(' ')}');
  return code;
}

Never _die(String message) {
  print('❌  $message');
  exit(1);
}
