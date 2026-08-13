import 'package:app_template/modules/data_transfer/domain/transfer_resource.dart';

/// Parses `GET /api/v1/data-transfer/resources`.
///
/// **Every key below is a contract with `backend_template`.** A rename on
/// either side produces `null`, which is a valid `dynamic`, which `dart
/// analyze` and `tsc` both accept — and the user is told "something went
/// wrong" on a `200 OK`. `test/fixtures/wire/transfer_resources.json` is the
/// document both halves are checked against; change it in the same commit as
/// any key here.
class TransferResourceModel {
  const TransferResourceModel._();

  static TransferResource fromJson(Map<String, dynamic> json) {
    final label = json['label'] as Map<String, dynamic>? ?? const {};

    return TransferResource(
      name: json['name'] as String? ?? '',
      labelAr: label['ar'] as String? ?? '',
      labelEn: label['en'] as String? ?? '',
      exportFormats: _formats(json['export_formats']),
      importFormats: _formats(json['import_formats']),
      maxExportRows: json['max_export_rows'] as int? ?? 0,
      supportsImport: json['supports_import'] as bool? ?? false,
      columns: (json['columns'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_column)
          .toList(),
      filters: (json['filters'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_filter)
          // A filter type this build cannot draw is dropped rather than
          // guessed at: a `select` rendered as a free-text box invites the
          // user to type a value the server will reject.
          .where((f) => f.type != TransferFilterType.unknown)
          .toList(),
    );
  }

  static TransferFilter _filter(Map<String, dynamic> json) {
    final label = json['label'] as Map<String, dynamic>? ?? const {};
    final placeholder = json['placeholder'] as Map<String, dynamic>?;
    return TransferFilter(
      key: json['key'] as String? ?? '',
      labelAr: label['ar'] as String? ?? '',
      labelEn: label['en'] as String? ?? '',
      type: TransferFilterType.fromWire(json['type'] as String?),
      placeholderAr: placeholder?['ar'] as String?,
      placeholderEn: placeholder?['en'] as String?,
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((o) {
            final optionLabel = o['label'] as Map<String, dynamic>? ?? const {};
            return TransferFilterOption(
              value: o['value'] as String? ?? '',
              labelAr: optionLabel['ar'] as String? ?? '',
              labelEn: optionLabel['en'] as String? ?? '',
            );
          })
          .toList(),
    );
  }

  static TransferColumn _column(Map<String, dynamic> json) {
    final label = json['label'] as Map<String, dynamic>? ?? const {};
    final hint = json['hint'] as Map<String, dynamic>?;
    return TransferColumn(
      key: json['key'] as String? ?? '',
      labelAr: label['ar'] as String? ?? '',
      labelEn: label['en'] as String? ?? '',
      type: _type(json['type'] as String?),
      // Defaults chosen so a malformed descriptor fails safe: a column whose
      // `required` flag went missing is treated as optional (the server still
      // enforces the truth), and one whose `importable` flag went missing is
      // treated as **not** importable rather than offered in a template the
      // importer would then reject.
      required: json['required'] as bool? ?? false,
      importable: json['importable'] as bool? ?? false,
      example: json['example'] as String?,
      hintAr: hint?['ar'] as String?,
      hintEn: hint?['en'] as String?,
    );
  }

  static TransferColumnType _type(String? wire) => switch (wire) {
        'string' => TransferColumnType.string,
        'number' => TransferColumnType.number,
        'boolean' => TransferColumnType.boolean,
        'date' => TransferColumnType.date,
        'datetime' => TransferColumnType.datetime,
        // A type added server-side after this build shipped renders as text
        // rather than taking the whole descriptor down with it.
        _ => TransferColumnType.unknown,
      };

  static List<TransferFormat> _formats(dynamic raw) =>
      (raw as List<dynamic>? ?? const [])
          .whereType<String>()
          .map(TransferFormat.fromWire)
          .whereType<TransferFormat>()
          .toList();
}
