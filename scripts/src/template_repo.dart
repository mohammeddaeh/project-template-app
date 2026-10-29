/// ما يتشاركه `template_drift.dart` و`template_update.dart`: أيُّ الملفات يملكها
/// القالب، وكيف تُقرأ نسخةُ القالب منها عند commit بعينه، وكيف تُقارَن بنسخة
/// المشروع رغم أن المشروع بدّل اسم الحزمة.
library;

import 'dart:convert';
import 'dart:io';

/// مستودع القالب الافتراضي — نفسه بـ`new_project.ps1`.
const defaultTemplateUrl =
    'https://github.com/mohammeddaeh/project-template-app.git';

/// اسم الحزمة داخل القالب — `setup_project.dart` يبدّله بكل ملف نصّي.
const templatePackage = 'app_template';

/// **ما يملكه القالب** بمشروعٍ مبنيٍّ عليه: يُحدَّث منه، وتعديله بالمشروع
/// ملاحظةٌ تعود إليه. مسارٌ ينتهي بـ`/` مجلدٌ كامل، وإلا فملفٌّ بعينه.
///
/// **وما ليس هنا ملكُ المشروع**: `lib/features/` (يبدأ من `auth/` ثم يصير
/// للمشروع) · `lib/main.dart` · `lib/app.dart` · `lib/routes/` · `pubspec.yaml` ·
/// `assets/` · `android/` · `ios/` · `docs/` · `test/` غيرُ اختبارات القالب.
const templateOwned = <String>[
  'lib/core/',
  'lib/ui/',
  'lib/modules/',
  'scripts/',
  'readme/',
  '.claude/skills/',
  'CLAUDE.md',
  'lib/CLAUDE.md',
  'lib/features/CLAUDE.md',
  'analysis_options.yaml',
  '.github/workflows/ci.yml',
  'loadtest/',
  'TEMPLATE_VERSION',
];

/// ملفاتٌ داخل مسارٍ مملوك لا تُقارَن: مولَّدةٌ من مدخلات المشروع، فاختلافها
/// متوقَّع لا ملاحظة.
bool isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.gr.dart') ||
    path.endsWith('.config.dart') ||
    path == 'lib/core/platform/features/app_features.dart';

/// ملفاتٌ يملكها القالب **ويُنتظر** أن يعدّلها كل مشروع: مسارات خادمه، وتسجيلات
/// DI، وألوانه وخطوطه، وإقلاع موديولاته. تعديلُها ليس ملاحظةً للقالب، وتحديثُها
/// من القالب يُراجَع دائماً ولا يُستبدل.
const projectEdited = <String>{
  'lib/core/infra/network/rest/api_urls.dart',
  'lib/core/di/injection_module.dart',
  'lib/core/infra/config/app_fonts.dart',
  'lib/ui/theme/app_palette.dart',
  'lib/ui/theme/app_colors.dart',
  'lib/modules/modules_bootstrap.dart',
};

bool isTemplateOwned(String path) =>
    !isGenerated(path) &&
    templateOwned.any((o) => o.endsWith('/') ? path.startsWith(o) : path == o);

/// بيان المشروع الذي كتبه `setup_project.dart`.
class ProjectManifest {
  ProjectManifest._(this.package, this.templateVersion, this.raw);

  final String package;
  final String templateVersion;
  final Map<String, dynamic> raw;

  static ProjectManifest read() {
    final file = File('.template_manifest.json');
    if (!file.existsSync()) {
      throw StateError(
        '.template_manifest.json غير موجود — شغّل من جذر مشروعٍ أنشأه setup_project.dart',
      );
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final package = json['package'] as String? ?? templatePackage;
    final version = json['templateVersion'] as String? ?? 'unknown';
    return ProjectManifest._(package, version, json);
  }

  void writeTemplateVersion(String commit, String release) {
    raw['templateVersion'] = commit;
    raw['templateRelease'] = release;
    File(
      '.template_manifest.json',
    ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(raw)}\n');
  }
}

/// نسخةٌ من مستودع القالب بتاريخه — محلّية إن أُعطي مسارها، وإلا تُستنسخ.
class TemplateRepo {
  TemplateRepo._(this.dir);

  final String dir;

  /// [path] مستنسخٌ محلّيّ للقالب (أسرع، وبلا شبكة)، وإلا يُستنسخ [url] إلى
  /// مجلدٍ مؤقّت بلا محتوى الملفات (`--filter=blob:none`) — التاريخ وحده.
  static TemplateRepo open({String? path, String url = defaultTemplateUrl}) {
    if (path != null) {
      if (!Directory('$path/.git').existsSync()) {
        throw StateError('$path ليس مستودع git');
      }
      return TemplateRepo._(path);
    }
    final tmp = Directory.systemTemp.createTempSync('template_').path;
    final r = Process.runSync('git', [
      'clone',
      '--quiet',
      '--filter=blob:none',
      '--no-checkout',
      url,
      tmp,
    ]);
    if (r.exitCode != 0) {
      throw StateError('git clone $url فشل:\n${r.stderr}');
    }
    return TemplateRepo._(tmp);
  }

  ProcessResult _git(List<String> args) =>
      Process.runSync('git', ['-C', dir, ...args], stdoutEncoding: utf8);

  /// الـcommit الكامل لـ[ref]، أو `null` إن لم يوجد بالتاريخ.
  String? resolve(String ref) {
    final r = _git(['rev-parse', '--verify', '--quiet', '$ref^{commit}']);
    return r.exitCode == 0 ? (r.stdout as String).trim() : null;
  }

  /// كل الملفات المملوكة بالقالب عند [ref].
  List<String> ownedFilesAt(String ref) {
    final r = _git(['ls-tree', '-r', '--name-only', ref]);
    if (r.exitCode != 0) throw StateError('git ls-tree $ref فشل');
    return LineSplitter.split(
      r.stdout as String,
    ).where(isTemplateOwned).toList();
  }

  /// محتوى [path] عند [ref]، أو `null` إن لم يوجد هناك.
  String? fileAt(String ref, String path) {
    final r = _git(['show', '$ref:$path']);
    return r.exitCode == 0 ? r.stdout as String : null;
  }

  String releaseAt(String ref) =>
      fileAt(ref, 'TEMPLATE_VERSION')?.trim() ?? 'unknown';
}

/// يجعل نسخة المشروع ونسخة القالب قابلتين للمقارنة: نهايات أسطر LF، واسم
/// الحزمة الذي بدّله `setup_project.dart` يعود `app_template`.
String normalizeFromProject(String text, String package) {
  var out = text.replaceAll('\r\n', '\n');
  if (package != templatePackage) {
    out = out.replaceAll('package:$package/', 'package:$templatePackage/');
  }
  return out;
}

/// العكس: نسخة القالب كما يجب أن تُكتب بالمشروع.
String toProject(String templateText, String package) =>
    package == templatePackage
    ? templateText
    : templateText.replaceAll('package:$templatePackage/', 'package:$package/');

/// الملفات المملوكة الموجودة بالمشروع على القرص.
List<String> projectOwnedFiles() {
  final out = <String>[];
  for (final owned in templateOwned) {
    if (!owned.endsWith('/')) {
      if (File(owned).existsSync()) out.add(owned);
      continue;
    }
    final dir = Directory(owned);
    if (!dir.existsSync()) continue;
    for (final e in dir.listSync(recursive: true)) {
      if (e is! File) continue;
      final path = e.path.replaceAll(r'\', '/');
      final rel = path.startsWith('./') ? path.substring(2) : path;
      if (isTemplateOwned(rel)) out.add(rel);
    }
  }
  return out..sort();
}
