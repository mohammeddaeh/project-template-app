import 'package:equatable/equatable.dart';

/// The result of phase one — **nothing has been written yet**.
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
  });

  /// Spent on phase two. **`null` means nothing is committable** — the screen
  /// shows the errors and offers no confirm button at all, rather than a button
  /// that would report "inserted: 0" as success.
  final String? token;

  /// Seconds. After this the token is gone and the file must be re-uploaded.
  final int expiresIn;

  final int totalRows;
  final int validRows;
  final List<ImportRowError> errors;

  /// `true` when the server capped the list at 200. The UI must then say "the
  /// first 200 problems", never "200 problems" — the user acts on that number.
  final bool truncatedErrors;

  bool get canCommit => token != null && validRows > 0;
  int get invalidRows => totalRows - validRows;

  @override
  List<Object?> get props =>
      [token, expiresIn, totalRows, validRows, errors, truncatedErrors];
}

class ImportRowError extends Equatable {
  const ImportRowError({
    required this.row,
    required this.column,
    required this.code,
    required this.message,
    this.value,
  });

  /// **1-based over data rows** — row 1 is the first row *under* the header.
  ///
  /// Use [spreadsheetLine] when pointing the user at their file; the raw value
  /// is off by one from what Excel shows in the row gutter.
  final int row;

  /// The column `key`, or `null` for a whole-row problem.
  final String? column;

  /// Machine-readable: `required`, `invalid_number`, `invalid_date_format`, …
  /// Branch on this, never on [message].
  final String code;

  /// Already resolved to the request language by the server.
  final String message;

  /// The offending cell as it appeared in the file. Absent for row-level rules.
  final String? value;

  /// What Excel calls this line: data row 1 sits on line 2, under the header.
  int get spreadsheetLine => row + 1;

  @override
  List<Object?> get props => [row, column, code, message, value];
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
