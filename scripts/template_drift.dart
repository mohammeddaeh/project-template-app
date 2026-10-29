// ignore_for_file: avoid_print
/// ما غيّره المشروع بملفات القالب — **ولم يُسجَّل** ملاحظةً تعود إلى القالب.
///
/// يُشغَّل **داخل مشروعٍ مبنيٍّ على القالب**. يقرأ commit القالب الذي بدأ منه
/// المشروع (`templateVersion` بـ`.template_manifest.json`)، ويقارن كل ملفٍّ يملكه
/// القالب (`templateOwned` بـ`scripts/src/template_repo.dart`) بنسخته هناك:
///
/// | الحالة | المعنى |
/// |---|---|
/// | **معدَّل** | المشروع غيّر ملفاً من القالب — تحسينٌ يعود، أو تخصيصٌ يُوثَّق |
/// | **محذوف** | المشروع أزال ملفاً من القالب (موديولٌ مطفأ حُذف عادةً) |
/// | **متوقَّع** | ملفٌّ يُنتظر أن يعدّله كل مشروع (`projectEdited`) — يُعرض ولا يُعدّ |
/// | **مضاف** | ملفٌّ جديد بمسارٍ يملكه القالب (`lib/core/` · `lib/ui/` · `lib/modules/` · `scripts/`) — قدرةٌ عامّة على الأرجح |
///
/// والتغيير **مسجَّل** حين يُذكر مسارُه بـ`docs/TEMPLATE_FEEDBACK.md`. اسم الحزمة
/// الذي بدّله `setup_project.dart` ونهاياتُ الأسطر لا تُعدّ تغييراً.
///
/// تشغيل من جذر المشروع:
///   dart run scripts/template_drift.dart                     # يستنسخ القالب مؤقّتاً
///   dart run scripts/template_drift.dart --template ../app_template   # مستنسخٌ محلّي
///   dart run scripts/template_drift.dart --write             # يضيف مسوّدة لكل غير مسجَّل
///   dart run scripts/template_drift.dart --strict            # خروج 1 إن بقي غير مسجَّل
///   dart run scripts/template_drift.dart --base COMMIT       # حين يغيب templateVersion
library;

import 'dart:io';

import 'src/template_repo.dart';

const _feedbackFile = 'docs/TEMPLATE_FEEDBACK.md';
const _addedRoots = ['lib/core/', 'lib/ui/', 'lib/modules/', 'scripts/'];

void main(List<String> args) {
  String? option(String name) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  print('\n🧭  template_drift — ما تغيّر بملفات القالب\n');

  final manifest = ProjectManifest.read();
  final repo = TemplateRepo.open(path: option('--template'));
  final baseRef = option('--base') ?? manifest.templateVersion;
  final base = repo.resolve(baseRef);
  if (base == null) {
    print(
      '❌  commit القالب «$baseRef» غير موجود بتاريخه. '
      'مرّر --base <commit> بأقرب commit بدأ منه المشروع.',
    );
    exit(2);
  }
  print(
    '   القالب عند ${base.substring(0, 7)} (${repo.releaseAt(base)}) · '
    'الحزمة ${manifest.package}\n',
  );

  final recorded = File(_feedbackFile).existsSync()
      ? File(_feedbackFile).readAsStringSync()
      : '';
  final templateFiles = repo.ownedFilesAt(base).toSet();
  final changes = <_Change>[];

  for (final path in templateFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      changes.add(_Change('محذوف', path, recorded.contains(path)));
      continue;
    }
    final theirs = repo.fileAt(base, path)!.replaceAll('\r\n', '\n');
    final ours = normalizeFromProject(
      file.readAsStringSync(),
      manifest.package,
    );
    if (theirs != ours) {
      if (projectEdited.contains(path)) {
        changes.add(_Change('متوقَّع', path, true, _stat(theirs, ours)));
        continue;
      }
      changes.add(
        _Change('معدَّل', path, recorded.contains(path), _stat(theirs, ours)),
      );
    }
  }
  for (final path in projectOwnedFiles()) {
    if (templateFiles.contains(path)) continue;
    if (!_addedRoots.any(path.startsWith)) continue;
    changes.add(_Change('مضاف', path, recorded.contains(path)));
  }

  if (changes.isEmpty) {
    print('✅  ملفات القالب كما بدأت — لا شيء يعود.\n');
    return;
  }

  for (final kind in ['معدَّل', 'مضاف', 'محذوف', 'متوقَّع']) {
    final group = changes.where((c) => c.kind == kind).toList();
    if (group.isEmpty) continue;
    print('── $kind (${group.length}) ──');
    for (final c in group) {
      print(
        '   ${c.recorded ? '✓' : '◌'}  ${c.path}${c.stat == null ? '' : '  (${c.stat})'}',
      );
    }
    print('');
  }

  final open = changes.where((c) => !c.recorded).toList();
  print(
    '   ${changes.length} تغييراً · ${open.length} غير مسجَّل بـ$_feedbackFile',
  );
  print(
    '   ✓ مسجَّل · ◌ غير مسجَّل — راجع كلاً: تحسينٌ للقالب، أم تخصيصٌ للمشروع؟\n',
  );

  if (args.contains('--write') && open.isNotEmpty) _writeDrafts(open, base);
  if (args.contains('--strict') && open.isNotEmpty) exit(1);
}

class _Change {
  _Change(this.kind, this.path, this.recorded, [this.stat]);
  final String kind;
  final String path;
  final bool recorded;
  final String? stat;
}

/// `+أسطر −أسطر` بين النسختين — عددٌ للمراجعة لا فرقٌ كامل.
String _stat(String before, String after) {
  final a = before.split('\n');
  final b = after.split('\n');
  final counts = <String, int>{};
  for (final line in a) {
    counts[line] = (counts[line] ?? 0) + 1;
  }
  var added = 0;
  for (final line in b) {
    final n = counts[line] ?? 0;
    if (n > 0) {
      counts[line] = n - 1;
    } else {
      added++;
    }
  }
  final removed = counts.values.fold<int>(0, (s, n) => s + n);
  return '+$added −$removed';
}

void _writeDrafts(List<_Change> open, String base) {
  final file = File(_feedbackFile);
  if (!file.existsSync()) {
    file.createSync(recursive: true);
    file.writeAsStringSync('# ملاحظات للقالب\n');
  }
  final buffer = StringBuffer(
    '\n## مسوّدات template_drift (القالب ${base.substring(0, 7)})\n\n',
  );
  buffer.writeln(
    '> كل بندٍ هنا تغييرٌ لم يُسجَّل. أكمل «لماذا» و«المقترح»، أو احذفه إن',
  );
  buffer.writeln('> كان تخصيصاً للمشروع وحده (واذكر ذلك بسطرٍ كي لا يعود).\n');
  for (final c in open) {
    buffer
      ..writeln('### ${c.kind}: `${c.path}` ⏳')
      ..writeln()
      ..writeln('**المشكلة كما ظهرت:** …')
      ..writeln()
      ..writeln(
        '**التغيير المقترح على القالب:** …${c.stat == null ? '' : ' (${c.stat})'}',
      )
      ..writeln();
  }
  file.writeAsStringSync(buffer.toString(), mode: FileMode.append);
  print('   ✎  أُضيفت ${open.length} مسوّدة إلى $_feedbackFile\n');
}
