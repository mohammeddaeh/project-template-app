/// دمجُ مفاتيح الترجمة من القالب إلى المشروع — لـ`template_update.dart`.
///
/// ملفّا `assets/translations/*.json` ملكُ المشروع، لكنّ كود القالب يستعمل
/// مفاتيحه. فالمفتاح يُقارَن بثلاث نسخ كالملف: القالب عند إصدار المشروع ·
/// القالب الجديد · المشروع.
library;

import 'dart:convert';

/// ما يخرج من [mergeTranslations]: الملف الجديد، وما تغيّر فيه، وما لم يُكتب.
class TranslationMerge {
  TranslationMerge(this.merged, this.added, this.updated, this.conflicts);

  final Map<String, dynamic> merged;
  final List<String> added;
  final List<String> updated;

  /// مفاتيح غيّر المشروعُ والقالبُ قيمتها كلاهما — قيمة المشروع تبقى.
  final Map<String, dynamic> conflicts;

  bool get changed => added.isNotEmpty || updated.isNotEmpty;
}

/// | المفتاح | النتيجة |
/// |---|---|
/// | بالقالب الجديد لا بالمشروع | يُضاف بقيمة القالب، بعد جاره بالقالب |
/// | قيمةُ المشروع كما كانت بالقالب، والقالب غيّرها | يُحدَّث |
/// | المشروع غيّرها والقالب غيّرها | تعارض — لا يُكتب |
/// | حذفه القالب | يبقى — قد يستعمله كود المشروع |
TranslationMerge mergeTranslations({
  required Map<String, dynamic>? base,
  required Map<String, dynamic> target,
  required Map<String, dynamic> project,
}) {
  String enc(Object? v) => jsonEncode(v);
  final added = <String>[];
  final updated = <String>[];
  final conflicts = <String, dynamic>{};
  final values = Map<String, dynamic>.of(project);
  // المفتاح الجديد يُدرج بعد أقرب مفتاحٍ يسبقه بالقالب ويوجد بالمشروع، فيبقى
  // ترتيبُ المشروع ويقع الجديد بجوار أهله.
  final insertAfter = <String?, List<String>>{};
  String? previous;

  for (final key in target.keys) {
    final theirs = target[key];
    if (!project.containsKey(key)) {
      added.add(key);
      values[key] = theirs;
      (insertAfter[previous] ??= []).add(key);
      continue;
    }
    previous = key;
    final ours = project[key];
    final was = base?[key];
    if (enc(ours) == enc(theirs) || enc(was) == enc(theirs)) continue;
    if (base != null && base.containsKey(key) && enc(ours) == enc(was)) {
      updated.add(key);
      values[key] = theirs;
    } else {
      conflicts[key] = theirs;
    }
  }

  final merged = <String, dynamic>{};
  for (final key in insertAfter[null] ?? const <String>[]) {
    merged[key] = values[key];
  }
  for (final key in project.keys) {
    merged[key] = values[key];
    for (final k in insertAfter[key] ?? const <String>[]) {
      merged[k] = values[k];
    }
  }
  return TranslationMerge(merged, added, updated, conflicts);
}

/// بصيغة ملفات القالب نفسها: مسافتان، وسطرٌ أخير.
String encodeTranslations(Map<String, dynamic> map) =>
    '${const JsonEncoder.withIndent('  ').convert(map)}\n';
