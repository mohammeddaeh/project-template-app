import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/modules/data_transfer/data/csv_preview_parser.dart';

/// The preview parser is a port of the server's `csv.reader.ts`, and these
/// mirror that file's own cases.
///
/// The pairing matters: if the two disagree about quoting, a file this app
/// wrote previews differently from how the server reads it — and the preview
/// stops being evidence of anything. Every case below has a counterpart in
/// `backend_template/src/core/data-transfer/__tests__/csv.test.ts`.
void main() {
  group('CsvPreviewParser', () {
    test('strips the BOM our own exports begin with', () {
      // Without this the first header renders as "﻿id" and the user sees a
      // column name that does not match anything.
      final preview = CsvPreviewParser.parse('﻿id,name\r\n1,Alpha');
      expect(preview.header, ['id', 'name']);
    });

    test('reads quoted commas, quotes and newlines', () {
      final preview = CsvPreviewParser.parse(
        'a,b\r\n"x,y","he said ""hi""\nnext"\r\n',
      );
      expect(preview.rows.single, ['x,y', 'he said "hi"\nnext']);
    });

    test('accepts CRLF, LF and a lone CR in the same file', () {
      final preview = CsvPreviewParser.parse('a,b\r\n1,2\n3,4\r5,6');
      expect(preview.rows, [
        ['1', '2'],
        ['3', '4'],
        ['5', '6'],
      ]);
    });

    test('keeps the last row when the file has no trailing newline', () {
      expect(CsvPreviewParser.parse('a,b\r\n1,2').rows, hasLength(1));
    });

    test('drops blank rows rather than showing empty table lines', () {
      expect(CsvPreviewParser.parse('a,b\r\n1,2\r\n\r\n,\r\n').rows, hasLength(1));
    });

    test('treats a quote inside an unquoted field as literal', () {
      // Excel writes `ab"cd` unquoted. Treating that quote as an opener would
      // swallow the rest of the file into one cell.
      expect(CsvPreviewParser.parse('a\r\nab"cd').rows.single, ['ab"cd']);
    });

    test('reads Arabic content back unchanged', () {
      final preview = CsvPreviewParser.parse(
        '﻿name,address\r\nالفرع الرئيسي,"شارع الكورنيش، اللاذقية"\r\n',
      );
      expect(preview.header, ['name', 'address']);
      expect(preview.rows.single, ['الفرع الرئيسي', 'شارع الكورنيش، اللاذقية']);
    });

    test('stops at the row cap and says it did', () {
      // A 50 000-row export must not build a table nobody scrolls out of a file
      // that took real time to parse — and the count shown must not be read as
      // the file's total.
      final body = List.generate(500, (i) => 'row$i,x').join('\r\n');
      final preview = CsvPreviewParser.parse('a,b\r\n$body', maxRows: 10);

      expect(preview.truncated, isTrue);
      expect(preview.rows.length, lessThanOrEqualTo(11));
    });

    test('does not claim truncation for a file that fits', () {
      final preview = CsvPreviewParser.parse('a,b\r\n1,2\r\n3,4', maxRows: 10);
      expect(preview.truncated, isFalse);
      expect(preview.rows, hasLength(2));
    });

    test('an empty file previews as empty rather than throwing', () {
      expect(CsvPreviewParser.parse('').isEmpty, isTrue);
      expect(CsvPreviewParser.parse('﻿').isEmpty, isTrue);
    });

    test('a header-only template previews with no data rows', () {
      // Exactly what a template with no example row looks like.
      final preview = CsvPreviewParser.parse('﻿name,address,contact_info\r\n');
      expect(preview.header, ['name', 'address', 'contact_info']);
      expect(preview.rows, isEmpty);
      expect(preview.isEmpty, isFalse);
    });
  });
}
