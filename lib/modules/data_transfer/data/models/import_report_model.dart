import 'package:app_template/modules/data_transfer/domain/import_report.dart';

/// Parses both import phases. Keys mirror
/// `backend_template/src/core/data-transfer/services/import.service.ts` and are
/// asserted against `test/fixtures/wire/import_report.json`.
class ImportReportModel {
  const ImportReportModel._();

  static ImportReport fromJson(Map<String, dynamic> json) => ImportReport(
        // `null` is meaningful here, not missing data: the server withholds a
        // token when no row is valid. Defaulting it to `''` would put a
        // confirm button on a screen with nothing to confirm.
        token: json['token'] as String?,
        expiresIn: json['expires_in'] as int? ?? 0,
        totalRows: json['total_rows'] as int? ?? 0,
        validRows: json['valid_rows'] as int? ?? 0,
        errors: (json['errors'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(_error)
            .toList(),
        truncatedErrors: json['truncated_errors'] as bool? ?? false,
      );

  static ImportRowError _error(Map<String, dynamic> json) => ImportRowError(
        row: json['row'] as int? ?? 0,
        column: json['column'] as String?,
        code: json['code'] as String? ?? 'unknown',
        message: json['message'] as String? ?? '',
        value: json['value'] as String?,
      );

  static ImportResult resultFromJson(Map<String, dynamic> json) => ImportResult(
        inserted: json['inserted'] as int? ?? 0,
        updated: json['updated'] as int? ?? 0,
        skipped: json['skipped'] as int? ?? 0,
        failed: json['failed'] as int? ?? 0,
      );
}
