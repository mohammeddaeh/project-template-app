import 'package:equatable/equatable.dart';

/// The result of phase one — **nothing has been written yet**.
///
/// Carries the user's own data back ([rows]) alongside the problems ([errors]),
/// because those two together are what lets the app draw the file as a grid
/// with the failing cells tinted. A report of problems alone sends the user off
/// to find row 12 in Excel; a report of problems *on the data* is a correction
/// they make in place.
///
/// Mirrors `ImportValidateReport` in
/// `backend_template/src/core/data-transfer/services/import.service.ts`.
class ImportReport extends Equatable {
  const ImportReport({
    required this.token,
    required this.expiresIn,
    required this.totalRows,
    required this.validRows,
    required this.errors,
    required this.truncatedErrors,
    required this.columns,
    required this.rows,
    required this.truncatedRows,
  });

  /// Spent on phase two. **`null` means nothing is committable** — the screen
  /// shows the errors and offers no confirm button at all, rather than a button
  /// that would report "inserted: 0" as success.
  final String? token;

  /// Seconds. After this the token is gone and the file must be re-sent.
  final int expiresIn;

  final int totalRows;
  final int validRows;
  final List<ImportRowError> errors;

  /// `true` when the server capped the list at 200. The UI must then say "the
  /// first 200 problems", never "200 problems" — the user acts on that number.
  final bool truncatedErrors;

  /// Column keys present in the file, in the resource's declared order — the
  /// grid's headers. Look each up in the descriptor for a localized label.
  final List<String> columns;

  /// Every row of the file as raw text, valid and invalid alike — the grid's body.
  final List<Map<String, String>> rows;

  /// `true` when the file was too large to echo back and [rows] is empty. The
  /// grid is hidden and the error list shown alone — a grid silently missing
  /// rows would have the user editing a file they cannot fully see.
  final bool truncatedRows;

  bool get canCommit => token != null && validRows > 0;
  int get invalidRows => totalRows - validRows;

  /// `true` when there is data to draw. `false` past the row cap.
  bool get hasGrid => rows.isNotEmpty && !truncatedRows;

  /// Errors indexed by the cell they belong to — `(row, column)`.
  ///
  /// Built once here rather than searched per cell: a 2 000×8 grid asks 16 000
  /// times which error applies, and a linear scan of 200 errors each time is
  /// 3.2 million comparisons on every rebuild — enough to drop frames while
  /// scrolling.
  Map<int, Map<String, ImportRowError>> get errorsByCell {
    final byCell = <int, Map<String, ImportRowError>>{};
    for (final error in errors) {
      // A whole-row problem has no column; it is keyed under the empty string
      // so the row header can show it without competing with any cell.
      (byCell[error.row] ??= {})[error.column ?? ''] = error;
    }
    return byCell;
  }

  @override
  List<Object?> get props => [
        token,
        expiresIn,
        totalRows,
        validRows,
        errors,
        truncatedErrors,
        columns,
        rows,
        truncatedRows,
      ];
}

/// How much a problem matters — and therefore what colour the cell is.
enum ImportSeverity {
  /// The row cannot be imported until the user changes something. Red.
  error,

  /// The row is being left out by policy, not by mistake — a duplicate the
  /// resource is configured to skip. Amber.
  ///
  /// Kept distinct because painting these red makes a correct import look
  /// broken, and a user who cannot tell "you must fix this" from "this will be
  /// ignored, which is fine" will stop reading either.
  warning;

  static ImportSeverity fromWire(String? value) =>
      value == 'warning' ? ImportSeverity.warning : ImportSeverity.error;
}

class ImportRowError extends Equatable {
  const ImportRowError({
    required this.row,
    required this.column,
    required this.code,
    required this.message,
    required this.severity,
    this.value,
    this.duplicateOfRow,
  });

  /// **1-based over data rows** — row 1 is the first row *under* the header.
  ///
  /// Use [spreadsheetLine] when pointing the user at their file; the raw value
  /// is off by one from what Excel shows in the row gutter.
  final int row;

  /// The column `key`, or `null` for a whole-row problem.
  final String? column;

  /// Machine-readable: `required`, `invalid_number`, `duplicate_in_file`, …
  /// Branch on this, never on [message] — see [ImportErrorCodes].
  final String code;

  /// Already resolved to the request language by the server. Shown verbatim
  /// when this build has no localized text for [code].
  final String message;

  final ImportSeverity severity;

  /// The offending cell as it appeared in the file. Absent for row-level rules.
  final String? value;

  /// For `duplicate_in_file`: the earlier row this one collides with.
  /// The grid offers "jump to row N" from it.
  final int? duplicateOfRow;

  /// What Excel calls this line: data row 1 sits on line 2, under the header.
  int get spreadsheetLine => row + 1;

  @override
  List<Object?> get props =>
      [row, column, code, message, severity, value, duplicateOfRow];
}

/// The codes the engine emits, so the UI can explain a problem in the user's
/// language instead of echoing the server's English.
///
/// A code this build does not recognise falls back to [ImportRowError.message],
/// which is always populated — so a server that gains a new rule degrades to
/// "shows the server's wording" rather than to a blank cell tooltip.
abstract final class ImportErrorCodes {
  static const required = 'required';
  static const invalidNumber = 'invalid_number';
  static const invalidBoolean = 'invalid_boolean';
  static const invalidDate = 'invalid_date';
  static const invalidDateFormat = 'invalid_date_format';
  static const duplicateInFile = 'duplicate_in_file';
  static const duplicateInDatabase = 'duplicate_in_database';
}

/// The result of phase two. Mirrors `ImportCommitReport` server-side.
class ImportResult extends Equatable {
  const ImportResult({
    required this.inserted,
    required this.updated,
    required this.skipped,
    required this.failed,
  });

  final int inserted;
  final int updated;
  final int skipped;
  final int failed;

  int get written => inserted + updated;

  @override
  List<Object?> get props => [inserted, updated, skipped, failed];
}
