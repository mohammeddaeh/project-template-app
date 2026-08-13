import 'package:equatable/equatable.dart';

/// What the server says it can import and export — and the **entire** input to
/// this module's user interface.
///
/// Nothing here is per-feature. The export screen renders its column picker,
/// its format choice and its filters from a [TransferResource] it fetched at
/// runtime, so a backend that starts exporting invoices tomorrow gets a working
/// invoices export screen today, with no Dart written, built or shipped.
///
/// Mirrors `WireTransferResource` in
/// `backend_template/src/core/data-transfer/descriptor.ts`. The key names are a
/// contract — see `test/fixtures/wire/transfer_resources.json`.
class TransferResource extends Equatable {
  const TransferResource({
    required this.name,
    required this.labelAr,
    required this.labelEn,
    required this.exportFormats,
    required this.importFormats,
    required this.maxExportRows,
    required this.supportsImport,
    required this.columns,
    this.filters = const [],
  });

  /// Wire identifier — goes into the URL path. Never shown to a user.
  final String name;

  final String labelAr;
  final String labelEn;

  final List<TransferFormat> exportFormats;
  final List<TransferFormat> importFormats;

  /// Above this the server answers 413 rather than streaming. Shown to the user
  /// *before* they try, so a refusal is never their first news of the limit.
  final int maxExportRows;

  /// The server states this separately from an empty [importFormats] — read it,
  /// do not infer. Two ways to express one fact is one way for the two sides to
  /// disagree.
  final bool supportsImport;

  final List<TransferColumn> columns;

  /// Filter controls the export screen renders, and the query keys it sends.
  ///
  /// **Declared by the server, not guessed here.** The export screen used to
  /// ship a hardcoded `?q=` box; the first real application named its filter
  /// `search`, so that control sent a parameter the schema ignored and filtered
  /// nothing — a field that looks like it works, does nothing, and reports no
  /// error. Empty means no filter section at all.
  final List<TransferFilter> filters;

  /// Columns the importer will accept. The rest (`id`, `created_at`) are
  /// exportable only and are silently ignored on the way back in.
  List<TransferColumn> get importableColumns =>
      columns.where((c) => c.importable).toList();

  /// Columns the server fills in — shown on the import screen so a user who
  /// counts three fields and expected seven knows why.
  List<TransferColumn> get systemColumns =>
      columns.where((c) => !c.importable).toList();

  String label({required bool isArabic}) => isArabic ? labelAr : labelEn;

  @override
  List<Object?> get props => [name, labelAr, labelEn, exportFormats,
        importFormats, maxExportRows, supportsImport, columns, filters];
}

/// One filter control on the export screen.
class TransferFilter extends Equatable {
  const TransferFilter({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.type,
    this.placeholderAr,
    this.placeholderEn,
    this.options = const [],
  });

  /// Query-string key, sent verbatim: `?search=…`.
  final String key;
  final String labelAr;
  final String labelEn;
  final TransferFilterType type;
  final String? placeholderAr;
  final String? placeholderEn;
  final List<TransferFilterOption> options;

  String label({required bool isArabic}) => isArabic ? labelAr : labelEn;
  String? placeholder({required bool isArabic}) =>
      isArabic ? placeholderAr : placeholderEn;

  @override
  List<Object?> get props =>
      [key, labelAr, labelEn, type, placeholderAr, placeholderEn, options];
}

class TransferFilterOption extends Equatable {
  const TransferFilterOption({
    required this.value,
    required this.labelAr,
    required this.labelEn,
  });

  final String value;
  final String labelAr;
  final String labelEn;

  String label({required bool isArabic}) => isArabic ? labelAr : labelEn;

  @override
  List<Object?> get props => [value, labelAr, labelEn];
}

/// A filter type this build knows how to draw.
///
/// [unknown] filters are **dropped**, not rendered as text: a `select` shown as
/// a free-text box would let the user type a value the server rejects, which is
/// worse than the filter being absent until the app is updated.
enum TransferFilterType {
  text,
  select,
  boolean,
  unknown;

  static TransferFilterType fromWire(String? value) => switch (value) {
        'text' => TransferFilterType.text,
        'select' => TransferFilterType.select,
        'boolean' => TransferFilterType.boolean,
        _ => TransferFilterType.unknown,
      };
}

class TransferColumn extends Equatable {
  const TransferColumn({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.type,
    required this.required,
    required this.importable,
    this.example,
    this.hintAr,
    this.hintEn,
  });

  /// The header written in the file, and the `column` an import error names.
  /// **Not** localized — a file exported in an Arabic session has to be
  /// importable in an English one.
  final String key;

  final String labelAr;
  final String labelEn;
  final TransferColumnType type;

  /// Import-side only: an empty cell here is a row error.
  final bool required;
  final bool importable;

  /// A sample **value** — what the template file's example row contains.
  /// Teaches the format (`0912345678` says more than a sentence about phones).
  final String? example;

  /// One line on what the column **means**. Shown beside the name in the app.
  ///
  /// Separate from [example] because the two answer different questions, and
  /// the screen was answering the wrong one: a sample branch name under "Branch
  /// name" tells the reader what branches are called, not what to put there.
  final String? hintAr;
  final String? hintEn;

  String label({required bool isArabic}) => isArabic ? labelAr : labelEn;
  String? hint({required bool isArabic}) => isArabic ? hintAr : hintEn;

  @override
  List<Object?> get props =>
      [key, labelAr, labelEn, type, required, importable, example, hintAr, hintEn];
}

/// Closed set, matching the server's `ColumnType`.
///
/// [unknown] exists so a server that adds a type this build has never heard of
/// degrades to "show it as text" instead of throwing while parsing the
/// descriptor — which would take the whole screen down over one column.
enum TransferColumnType { string, number, boolean, date, datetime, unknown }

enum TransferFormat {
  csv('csv', 'CSV'),
  xlsx('xlsx', 'Excel');

  const TransferFormat(this.wire, this.label);

  /// The value sent as `?format=`.
  final String wire;
  final String label;

  static TransferFormat? fromWire(String value) {
    for (final format in TransferFormat.values) {
      if (format.wire == value) return format;
    }
    // A format this build does not implement is dropped rather than guessed at.
    return null;
  }
}
