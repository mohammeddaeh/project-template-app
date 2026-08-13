import 'dart:convert';
import 'dart:io';

/// Reads a downloaded CSV back into a table, so the user can **see the file
/// before deciding what to do with it**.
///
/// A deliberate, line-for-line port of the server's `csv.reader.ts` — same
/// state machine, same rules. Not a rewrite: the two must agree about quoting,
/// or a file this app writes previews differently from how the server reads it,
/// and the preview stops being evidence of anything.
///
/// ## Why parse at all rather than show the raw text
///
/// A CSV opened as text is a wall of commas and quotes; the whole question a
/// user has at this moment — "are these my columns, in the right order, with
/// the right values?" — is answered by a table and not by that. Quoted fields
/// containing commas and newlines are precisely where raw text misleads.
///
/// XLSX is **not** parsed here. It is a zip container, and pulling in a
/// spreadsheet library to render a preview the OS can already show properly
/// would be a large dependency for a worse result — those files offer "open
/// with" instead.
abstract final class CsvPreviewParser {
  /// Decodes and parses [file], returning `[header, ...rows]`.
  ///
  /// Reads at most [maxRows] data rows: a preview exists to be glanced at, and
  /// a 50 000-row export would otherwise build a table nobody scrolls out of a
  /// file that took real time to parse.
  static Future<CsvPreview> fromFile(File file, {int maxRows = 200}) async {
    final bytes = await file.readAsBytes();
    // `allowMalformed` so a file with one bad byte previews with one bad glyph
    // instead of throwing — the user is looking at it to judge it, and a crash
    // tells them nothing about what is wrong.
    final text = const Utf8Decoder(allowMalformed: true).convert(bytes);
    return parse(text, maxRows: maxRows);
  }

  static CsvPreview parse(String input, {int maxRows = 200}) {
    // Strip the BOM our own exports begin with; leaving it makes the first
    // header render as "﻿id".
    final text = input.isNotEmpty && input.codeUnitAt(0) == 0xFEFF
        ? input.substring(1)
        : input;

    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    var truncated = false;
    var i = 0;

    void endField() {
      row.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      // Blank lines — a trailing newline, or what Excel leaves after a deleted
      // range — are not rows anybody meant to include.
      if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
    }

    while (i < text.length) {
      final ch = text[i];

      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i += 2;
            continue;
          }
          inQuotes = false;
          i += 1;
          continue;
        }
        field.write(ch);
        i += 1;
        continue;
      }

      if (ch == '"' && field.isEmpty) {
        // Only opens a quoted field at the start of one. A quote appearing
        // mid-field (`ab"cd`) is literal — Excel writes it that way, and
        // treating it as an opener would swallow the rest of the file.
        inQuotes = true;
        i += 1;
        continue;
      }

      if (ch == ',') {
        endField();
        i += 1;
        continue;
      }

      if (ch == '\r' || ch == '\n') {
        endRow();
        i += (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') ? 2 : 1;
        // +1 for the header, which is not a data row.
        if (rows.length > maxRows) {
          truncated = true;
          break;
        }
        continue;
      }

      field.write(ch);
      i += 1;
    }

    // A file that does not end with a newline still has a last row.
    if (!truncated && (field.isNotEmpty || row.isNotEmpty)) endRow();

    if (rows.isEmpty) {
      return const CsvPreview(header: [], rows: [], truncated: false);
    }

    return CsvPreview(
      header: rows.first,
      rows: rows.skip(1).toList(),
      truncated: truncated,
    );
  }
}

class CsvPreview {
  const CsvPreview({
    required this.header,
    required this.rows,
    required this.truncated,
  });

  final List<String> header;
  final List<List<String>> rows;

  /// `true` when the parser stopped at the row limit. The preview says so, so
  /// "12 rows" is never read off a table that was cut short.
  final bool truncated;

  bool get isEmpty => header.isEmpty;
}
