import 'package:flutter_test/flutter_test.dart';

import '../scripts/src/translation_merge.dart';

/// How `template_update.dart` carries the template's translation keys into a
/// project's own files without losing what the project wrote.
void main() {
  TranslationMerge merge(
    Map<String, dynamic> project, {
    Map<String, dynamic>? base = const {'a': 'A', 'b': 'B', 'c': 'C'},
    required Map<String, dynamic> target,
  }) => mergeTranslations(base: base, target: target, project: project);

  test('a key only the new template has is added next to its neighbour', () {
    final r = merge(
      {'a': 'A', 'b': 'B', 'c': 'C', 'mine': 'M'},
      target: {'a': 'A', 'new': 'N', 'b': 'B', 'c': 'C'},
    );
    expect(r.added, ['new']);
    expect(r.merged.keys, ['a', 'new', 'b', 'c', 'mine']);
  });

  test('a value the project left alone follows the template', () {
    final r = merge(
      {'a': 'A', 'b': 'B', 'c': 'C'},
      target: {'a': 'A2', 'b': 'B', 'c': 'C'},
    );
    expect(r.updated, ['a']);
    expect(r.merged['a'], 'A2');
    expect(r.conflicts, isEmpty);
  });

  test('a value both changed stays the project\'s and is reported', () {
    final r = merge(
      {'a': 'Ours', 'b': 'B', 'c': 'C'},
      target: {'a': 'Theirs', 'b': 'B', 'c': 'C'},
    );
    expect(r.merged['a'], 'Ours');
    expect(r.conflicts, {'a': 'Theirs'});
    expect(r.changed, isFalse);
  });

  test('a value only the project changed is kept quietly', () {
    final r = merge(
      {'a': 'Ours', 'b': 'B', 'c': 'C'},
      target: {'a': 'A', 'b': 'B', 'c': 'C'},
    );
    expect(r.merged['a'], 'Ours');
    expect(r.changed, isFalse);
    expect(r.conflicts, isEmpty);
  });

  test('a key the template dropped stays — project code may still use it', () {
    final r = merge(
      {'a': 'A', 'b': 'B', 'c': 'C'},
      target: {'a': 'A', 'b': 'B'},
    );
    expect(r.merged.keys, ['a', 'b', 'c']);
    expect(r.changed, isFalse);
  });

  test('nested values compare by content', () {
    final r = merge(
      {
        'a': {'one': '1'},
      },
      base: {
        'a': {'one': '1'},
      },
      target: {
        'a': {'one': '1', 'other': '2'},
      },
    );
    expect(r.updated, ['a']);
  });

  test('the file is written in the template\'s own format', () {
    expect(encodeTranslations({'a': 'ا'}), '{\n  "a": "ا"\n}\n');
  });
}
