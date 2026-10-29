// ignore_for_file: avoid_print
/// يجلب نسخةً أحدث من القالب إلى مشروعٍ مبنيٍّ عليه — **بلا أن يمحو ما غيّره المشروع**.
///
/// يُشغَّل **داخل المشروع**. لكل ملفٍّ يملكه القالب (`templateOwned`) يقارن ثلاث
/// نسخ: القالب حين بدأ المشروع (`templateVersion`)، والقالب الآن، والمشروع:
///
/// | الحالة | ما يحدث مع `--apply` |
/// |---|---|
/// | القالب غيّره والمشروع لم يلمسه | **يُحدَّث** (أو يُضاف · أو يُحذف) |
/// | المشروع غيّره والقالب لم يغيّره | لا شيء — تعديلُ المشروع يبقى |
/// | **كلاهما غيّره** · أو ملفٌّ بـ`projectEdited` | **تعارض**: نسخة القالب تُكتب بـ`.template_update/<المسار>`، والملف لا يُلمس |
/// | المشروع حذفه | لا شيء — يُذكر وحسب |
///
/// وبعد `--apply` يُكتب الـcommit الجديد بـ`.template_manifest.json`، فالتحديث
/// التالي يبدأ منه. **وبلا `--apply` يعرض ولا يكتب شيئاً.**
///
/// تشغيل من جذر المشروع — وشجرة git نظيفة، ليكون التحديث commitاً واحداً يُراجَع:
///   dart run scripts/template_update.dart                       # عرضٌ فقط
///   dart run scripts/template_update.dart --apply
///   dart run scripts/template_update.dart --template ../app_template --to v1.1.0
///
/// ثم: `dart run scripts/gen_code.dart` · `dart analyze` · `flutter test`، وراجع
/// كل ملفٍّ بـ`.template_update/` بدمجه يدوياً ثم احذف المجلد.
library;

import 'dart:io';

import 'src/template_repo.dart';

const _conflictDir = '.template_update';

void main(List<String> args) {
  String? option(String name) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final apply = args.contains('--apply');
  print(
    '\n⬆️   template_update — ${apply ? 'تطبيق' : 'عرضٌ فقط (--apply للتطبيق)'}\n',
  );

  if (apply && !_cleanTree()) {
    print(
      '❌  شجرة git فيها تغييرات — احفظها أولاً، ليكون التحديث commitاً منفصلاً.',
    );
    exit(2);
  }

  final manifest = ProjectManifest.read();
  final repo = TemplateRepo.open(path: option('--template'));
  final base = repo.resolve(option('--base') ?? manifest.templateVersion);
  final target =
      repo.resolve(option('--to') ?? 'origin/master') ?? repo.resolve('HEAD');
  if (base == null || target == null) {
    print('❌  تعذّر تحديد commit البداية أو الهدف — مرّر --base و--to صراحةً.');
    exit(2);
  }
  if (base == target) {
    print('✅  المشروع على آخر نسخة من القالب (${base.substring(0, 7)}).\n');
    return;
  }
  print(
    '   من ${base.substring(0, 7)} (${repo.releaseAt(base)}) '
    'إلى ${target.substring(0, 7)} (${repo.releaseAt(target)})\n',
  );

  final paths = {
    ...repo.ownedFilesAt(base),
    ...repo.ownedFilesAt(target),
  }.toList()..sort();
  final actions = <String, List<String>>{};
  void note(String kind, String path) => (actions[kind] ??= []).add(path);

  for (final path in paths) {
    final before = repo.fileAt(base, path)?.replaceAll('\r\n', '\n');
    final after = repo.fileAt(target, path)?.replaceAll('\r\n', '\n');
    if (before == after) continue;

    final file = File(path);
    final ours = file.existsSync()
        ? normalizeFromProject(file.readAsStringSync(), manifest.package)
        : null;

    if (ours == after) continue;
    if (ours == null && before != null) {
      note('حذفه المشروع', path);
      continue;
    }
    final untouched = ours == before && !projectEdited.contains(path);
    if (!untouched) {
      note('تعارض', path);
      if (apply && after != null) {
        final copy = File('$_conflictDir/$path')..createSync(recursive: true);
        copy.writeAsStringSync(toProject(after, manifest.package));
      }
      continue;
    }
    if (after == null) {
      note('يُحذف', path);
      if (apply) file.deleteSync();
    } else {
      note(before == null ? 'يُضاف' : 'يُحدَّث', path);
      if (apply) {
        file
          ..createSync(recursive: true)
          ..writeAsStringSync(toProject(after, manifest.package));
      }
    }
  }

  if (actions.isEmpty) {
    print('✅  لا ملفّ من ملفات القالب تغيّر بما يمسّ المشروع.\n');
  }
  for (final kind in ['يُحدَّث', 'يُضاف', 'يُحذف', 'تعارض', 'حذفه المشروع']) {
    final group = actions[kind];
    if (group == null) continue;
    print('── $kind (${group.length}) ──');
    for (final p in group) {
      print('   $p');
    }
    print('');
  }

  if (!apply) {
    print('   عرضٌ فقط — لم يُكتب شيء. أعد التشغيل بـ--apply.\n');
    return;
  }
  manifest.writeTemplateVersion(target, repo.releaseAt(target));
  print('   ✓ .template_manifest.json ← ${target.substring(0, 7)}');
  if (actions.containsKey('تعارض')) {
    print(
      '   ⚠️  ${actions['تعارض']!.length} تعارضاً: نسخة القالب بـ$_conflictDir/ — ادمجها يدوياً ثم احذف المجلد.',
    );
  }
  print(
    '   التالي: dart run scripts/gen_code.dart · dart analyze · flutter test\n',
  );
}

bool _cleanTree() {
  final r = Process.runSync('git', ['status', '--porcelain']);
  return r.exitCode == 0 && (r.stdout as String).trim().isEmpty;
}
