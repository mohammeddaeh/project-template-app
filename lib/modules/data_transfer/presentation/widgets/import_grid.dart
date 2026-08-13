import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/data_transfer/domain/import_report.dart';
import 'package:app_template/modules/data_transfer/domain/transfer_resource.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

/// The user's file, on screen, with the failing cells tinted — and editable.
///
/// This is the whole point of the review phase. A list saying "row 12: invalid
/// phone number" asks the user to leave the app, find row 12 in Excel, work out
/// which of eight columns is meant, fix it, save, and upload again. The same
/// information painted onto the cell is a correction they make with a tap.
///
/// ## Why a hand-built table rather than `DataTable`
///
/// `DataTable` builds every cell eagerly. At the 2 000-row cap that is 16 000
/// widgets constructed before the first frame — seconds of jank, then a scroll
/// that stutters. This uses a `ListView.builder` for rows (lazy) inside a shared
/// horizontal `ScrollController` for columns, so only the visible window exists.
///
/// The two scroll axes are deliberate: a frozen row-number gutter with the data
/// scrolling under it is what makes a wide file navigable on a phone.
class ImportGrid extends StatefulWidget {
  const ImportGrid({
    required this.report,
    required this.resource,
    required this.onEditCell,
    required this.onDeleteRow,
    super.key,
  });

  final ImportReport report;

  /// Supplies the localized column labels. The grid never invents a header —
  /// it looks up each key from the file in the server's descriptor.
  final TransferResource resource;

  /// `(rowNumber, columnKey, newValue)` — 1-based row, matching the report.
  final void Function(int row, String column, String value) onEditCell;

  final void Function(int row) onDeleteRow;

  @override
  State<ImportGrid> createState() => _ImportGridState();
}

class _ImportGridState extends State<ImportGrid> {
  /// Shared by the header and every row, so the frozen header cannot drift out
  /// of alignment with the data under it while scrolling sideways.
  final _horizontal = ScrollController();

  bool _errorsOnly = false;
  String? _sortColumn;
  bool _sortAscending = true;

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  static const _gutterWidth = 56.0;
  static const _columnWidth = 150.0;
  static const _rowHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    final errorsByCell = widget.report.errorsByCell;
    final visible = _visibleRows(errorsByCell);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Toolbar(
          errorsOnly: _errorsOnly,
          errorRowCount: errorsByCell.length,
          shownCount: visible.length,
          totalCount: widget.report.rows.length,
          onToggleErrorsOnly: () => setState(() => _errorsOnly = !_errorsOnly),
        ),
        _Header(
          columns: widget.report.columns,
          resource: widget.resource,
          controller: _horizontal,
          gutterWidth: _gutterWidth,
          columnWidth: _columnWidth,
          sortColumn: _sortColumn,
          sortAscending: _sortAscending,
          onSort: _onSort,
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    LocaleKeys.importNoRowsShown.tr(),
                    style: context.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: visible.length,
                  itemExtent: _rowHeight,
                  itemBuilder: (context, index) {
                    final rowNumber = visible[index];
                    return _Row(
                      rowNumber: rowNumber,
                      cells: widget.report.rows[rowNumber - 1],
                      columns: widget.report.columns,
                      errors: errorsByCell[rowNumber] ?? const {},
                      controller: _horizontal,
                      gutterWidth: _gutterWidth,
                      columnWidth: _columnWidth,
                      onTapCell: (column) => _editCell(rowNumber, column),
                      onDelete: () => widget.onDeleteRow(rowNumber),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// The row numbers to draw, after the filter and the sort.
  ///
  /// Returns **row numbers, not rows**: sorting must not renumber anything. The
  /// numbers are the user's link back to their own file and to every error
  /// message, so a sort that reordered them would make the whole report lie.
  List<int> _visibleRows(Map<int, Map<String, ImportRowError>> errorsByCell) {
    var numbers = List<int>.generate(widget.report.rows.length, (i) => i + 1);

    if (_errorsOnly) {
      // Only real errors, not warnings: "show me what I must fix" should not
      // include rows that are merely going to be skipped.
      numbers = numbers
          .where((n) => (errorsByCell[n] ?? const {}).values.any(
                (e) => e.severity == ImportSeverity.error,
              ))
          .toList();
    }

    final sortColumn = _sortColumn;
    if (sortColumn != null) {
      numbers.sort((a, b) {
        final left = widget.report.rows[a - 1][sortColumn] ?? '';
        final right = widget.report.rows[b - 1][sortColumn] ?? '';
        // Numeric when both sides are numbers, textual otherwise — so a column
        // of quantities does not sort 1, 10, 2.
        final leftNum = num.tryParse(left);
        final rightNum = num.tryParse(right);
        final result = (leftNum != null && rightNum != null)
            ? leftNum.compareTo(rightNum)
            : left.compareTo(right);
        return _sortAscending ? result : -result;
      });
    }

    return numbers;
  }

  void _onSort(String column) => setState(() {
        if (_sortColumn == column) {
          // Third tap clears the sort and returns to file order — which is the
          // order every error message refers to.
          if (!_sortAscending) {
            _sortColumn = null;
            _sortAscending = true;
          } else {
            _sortAscending = false;
          }
        } else {
          _sortColumn = column;
          _sortAscending = true;
        }
      });

  Future<void> _editCell(int rowNumber, String column) async {
    final current = widget.report.rows[rowNumber - 1][column] ?? '';
    final label = widget.resource.columns
        .where((c) => c.key == column)
        .map((c) => c.label(isArabic: context.locale.languageCode == 'ar'))
        .firstOrNull;

    final updated = await showDialog<String>(
      context: context,
      builder: (_) => _CellEditor(
        title: label ?? column,
        initial: current,
        rowLabel: LocaleKeys.importRowLabel.tr(args: ['${rowNumber + 1}']),
        error: widget.report.errorsByCell[rowNumber]?[column],
      ),
    );

    if (updated == null || updated == current) return;
    widget.onEditCell(rowNumber, column, updated);
  }
}

// ── Toolbar ──────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.errorsOnly,
    required this.errorRowCount,
    required this.shownCount,
    required this.totalCount,
    required this.onToggleErrorsOnly,
  });

  final bool errorsOnly;
  final int errorRowCount;
  final int shownCount;
  final int totalCount;
  final VoidCallback onToggleErrorsOnly;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                LocaleKeys.importShowingRows.tr(
                  args: ['$shownCount', '$totalCount'],
                ),
                style: context.textTheme.bodySmall,
              ),
            ),
            if (errorRowCount > 0)
              FilterChip(
                selected: errorsOnly,
                avatar: Icon(
                  Icons.error_outline,
                  size: 16,
                  color: context.colors.error,
                ),
                label: Text(
                  LocaleKeys.importOnlyProblems.tr(args: ['$errorRowCount']),
                ),
                onSelected: (_) => onToggleErrorsOnly(),
              ),
          ],
        ),
      );
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.columns,
    required this.resource,
    required this.controller,
    required this.gutterWidth,
    required this.columnWidth,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
  });

  final List<String> columns;
  final TransferResource resource;
  final ScrollController controller;
  final double gutterWidth;
  final double columnWidth;
  final String? sortColumn;
  final bool sortAscending;
  final void Function(String column) onSort;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.colors.bgNeutral,
        border: Border(
          bottom: BorderSide(color: context.colors.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: gutterWidth,
            child: Center(
              child: Text('#', style: context.textTheme.bodySmall),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              // The header must not scroll on its own — it follows the rows,
              // which own the gesture. Two independently scrollable axes here
              // let the header drift out of line with its own columns.
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  for (final key in columns)
                    SizedBox(
                      width: columnWidth,
                      child: InkWell(
                        onTap: () => onSort(key),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _label(key, isArabic),
                                  style: context.textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (sortColumn == key)
                                Icon(
                                  sortAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 14,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Balances the delete button in each row so columns stay aligned.
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// The localized label, falling back to the wire key.
  ///
  /// A file may legitimately carry a column the descriptor no longer describes
  /// — an older export, re-imported. Showing the raw key is honest; showing
  /// nothing would leave an unlabelled column the user cannot reason about.
  String _label(String key, bool isArabic) => resource.columns
      .where((c) => c.key == key)
      .map((c) => c.label(isArabic: isArabic))
      .firstOrNull ??
      key;
}

// ── Row ──────────────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  const _Row({
    required this.rowNumber,
    required this.cells,
    required this.columns,
    required this.errors,
    required this.controller,
    required this.gutterWidth,
    required this.columnWidth,
    required this.onTapCell,
    required this.onDelete,
  });

  final int rowNumber;
  final Map<String, String> cells;
  final List<String> columns;
  final Map<String, ImportRowError> errors;
  final ScrollController controller;
  final double gutterWidth;
  final double columnWidth;
  final void Function(String column) onTapCell;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // A row-level problem (a cross-field rule) is keyed under '' — it belongs
    // to the row number, not to any one cell.
    final rowError = errors[''];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.dividerSubtle)),
        color: rowError != null
            ? context.colors.error.withValues(alpha: 0.05)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: gutterWidth,
            child: Tooltip(
              message: rowError?.message ?? '',
              child: Center(
                child: Text(
                  // The spreadsheet line, not the data row — this is the number
                  // the user sees in Excel's gutter.
                  '${rowNumber + 1}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: rowError != null ? context.colors.error : null,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final key in columns)
                    _Cell(
                      width: columnWidth,
                      value: cells[key] ?? '',
                      error: errors[key],
                      onTap: () => onTapCell(key),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: LocaleKeys.importDeleteRow.tr(),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.width,
    required this.value,
    required this.error,
    required this.onTap,
  });

  final double width;
  final String value;
  final ImportRowError? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final severity = error?.severity;
    // Two distinct colours, not one: red means "you must change this", amber
    // means "this will be skipped, which may be fine". Collapsing them makes a
    // correct import look broken and trains people to ignore both.
    final tint = switch (severity) {
      ImportSeverity.error => context.colors.error,
      ImportSeverity.warning => context.colors.statusWarningFg,
      null => null,
    };

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: tint == null
              ? null
              : BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  border: Border.all(color: tint, width: 1),
                ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: value.isEmpty ? context.colors.textMuted : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (error != null)
                Tooltip(
                  message: error!.message,
                  child: Icon(Icons.info_outline, size: 14, color: tint),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cell editor ──────────────────────────────────────────────────────────────

class _CellEditor extends StatefulWidget {
  const _CellEditor({
    required this.title,
    required this.initial,
    required this.rowLabel,
    this.error,
  });

  final String title;
  final String initial;
  final String rowLabel;
  final ImportRowError? error;

  @override
  State<_CellEditor> createState() => _CellEditorState();
}

class _CellEditorState extends State<_CellEditor> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.rowLabel, style: context.textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: null,
              // `onSubmitted` as well as the button: on a phone the keyboard's
              // done key is the natural way to finish a one-cell correction.
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
            if (widget.error != null) ...[
              const SizedBox(height: 12),
              // The reason this cell is red, in front of the user while they
              // fix it — not on the screen they just left.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: context.colors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.error!.message,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: Text(LocaleKeys.save.tr()),
          ),
        ],
      );
}
