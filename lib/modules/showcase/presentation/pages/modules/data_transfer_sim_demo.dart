import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/data_transfer/domain/import_report.dart';
import 'package:app_template/modules/data_transfer/domain/transfer_resource.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/import_error_table.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/import_grid.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/transfer_failure_view.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/transfer_format_sheet.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/sim_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `modules/data_transfer/` played on the device: export with a progress bar
/// to a ready file, and the two-phase import — the file checked first in the
/// module's own [ImportGrid] and [ImportErrorTable], a cell fixed in place,
/// then committed to a summary.
class DataTransferSimDemo extends StatefulWidget {
  const DataTransferSimDemo({super.key});

  @override
  State<DataTransferSimDemo> createState() => _DataTransferSimDemoState();
}

enum _ImportStep { idle, review, committing, done }

enum _ReviewTab { grid, problems }

class _DataTransferSimDemoState extends State<DataTransferSimDemo> {
  /// The formats the module implements (`TransferFormat`): wire name → label.
  static const _formats = {'csv': 'CSV', 'xlsx': 'Excel'};

  /// The row the sample file gets wrong (1-based, as the server counts).
  static const _badRow = 3;

  String _format = 'csv';
  double? _progress;
  bool _ready = false;
  _ImportStep _import = _ImportStep.idle;
  _ReviewTab _tab = _ReviewTab.grid;
  List<Map<String, String>> _rows = const [];

  /// What `GET /data-transfer/resources` describes for the resource — the
  /// server sends its labels in both languages; the tour takes its own keys.
  TransferResource _resource() {
    TransferColumn column(String key, String labelKey, TransferColumnType t) =>
        TransferColumn(
          key: key,
          labelAr: labelKey.tr(),
          labelEn: labelKey.tr(),
          type: t,
          required: true,
          importable: true,
        );
    return TransferResource(
      name: 'notes',
      labelAr: LocaleKeys.showcaseAccessResource.tr(),
      labelEn: LocaleKeys.showcaseAccessResource.tr(),
      exportFormats: TransferFormat.values,
      importFormats: TransferFormat.values,
      maxExportRows: 1000,
      supportsImport: true,
      columns: [
        column(
          'title',
          LocaleKeys.showcaseDtColTitle,
          TransferColumnType.string,
        ),
        column(
          'amount',
          LocaleKeys.showcaseDtColAmount,
          TransferColumnType.number,
        ),
      ],
    );
  }

  /// The validation step's answer, recomputed from the rows on screen — a
  /// non-number in `amount` is the one rule the sample enforces.
  ImportReport _report() {
    final errors = [
      for (var i = 0; i < _rows.length; i++)
        if (num.tryParse(_rows[i]['amount'] ?? '') == null)
          ImportRowError(
            row: i + 1,
            column: 'amount',
            code: ImportErrorCodes.invalidNumber,
            message: LocaleKeys.showcaseDtNotNumber.tr(),
            severity: ImportSeverity.error,
            value: _rows[i]['amount'],
          ),
    ];
    return ImportReport(
      token: 'sample',
      expiresIn: 600,
      totalRows: _rows.length,
      validRows: _rows.length - errors.length,
      errors: errors,
      truncatedErrors: false,
      columns: const ['title', 'amount'],
      rows: _rows,
      truncatedRows: false,
    );
  }

  Future<void> _pickFile() async {
    final format = await TransferFormatSheet.show(
      context,
      formats: TransferFormat.values,
      titleKey: LocaleKeys.chooseFormat,
    );
    if (format == null || !mounted) return;
    setState(() {
      _rows = [
        for (var i = 1; i <= 5; i++)
          {
            'title': LocaleKeys.showcaseItem.tr(args: ['$i']),
            'amount': i == _badRow ? 'abc' : '${i * 120}',
          },
      ];
      _tab = _ReviewTab.grid;
      _import = _ImportStep.review;
    });
  }

  Future<void> _export() async {
    setState(() {
      _ready = false;
      _progress = 0;
    });
    for (var i = 1; i <= 10; i++) {
      // Stands in for the bytes of GET /data-transfer/{resource}/export.
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      setState(() => _progress = i / 10);
    }
    setState(() {
      _progress = null;
      _ready = true;
    });
  }

  Future<void> _commit() async {
    setState(() => _import = _ImportStep.committing);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _import = _ImportStep.done);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final motion = AppMotion.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SimNotice(),
        DemoBlock(
          code:
              "DataTransferSheet.show(context, resource: 'notes') → "
              'TransferExportScreen → TransferFileSheet.show(context, file:, '
              'titleKey:) — share · save · open in CsvPreviewView(file:)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.exportFormat.tr(),
                style: context.textTheme.titleSmall,
              ),
              8.heightBox,
              ChipRow<String>(
                items: _formats.keys.toList(),
                labelResolver: (f) => _formats[f]!,
                selectedValue: _format,
                onSelected: (f) => setState(() {
                  _format = f ?? _format;
                  _ready = false;
                }),
              ),
              16.heightBox,
              AnimatedSwitcher(
                duration: motion.base,
                child: _progress != null
                    ? AppProgress.linear(
                        key: const ValueKey('progress'),
                        value: _progress,
                        label: LocaleKeys.showcaseDtExporting.tr(),
                      )
                    : _ready
                    ? AppListTile(
                        key: const ValueKey('ready'),
                        titleText: LocaleKeys.showcaseDtFileReady.tr(),
                        subtitleText: 'notes.$_format',
                        leadingIcon: Icons.insert_drive_file_outlined,
                        trailing: const StatusChip(
                          labelText: '✓',
                          tone: StatusTone.success,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('none')),
              ),
              12.heightBox,
              AppButton(
                text: LocaleKeys.exportRun.tr(),
                leadingIcon: Icons.download_outlined,
                isLoading: _progress != null,
                onTap: _export,
              ),
            ],
          ),
        ),
        DemoBlock(
          code:
              'TransferImportScreen → TransferFormatSheet.show(…) → '
              'ImportGrid(report:, resource:, onEditCell:, onDeleteRow:) · '
              'ImportErrorTable(report:)',
          child: AnimatedSwitcher(
            duration: motion.base,
            child: KeyedSubtree(
              key: ValueKey(_import),
              child: switch (_import) {
                _ImportStep.idle => AppButton(
                  text: LocaleKeys.importPickFile.tr(),
                  variant: AppButtonVariant.tonal,
                  leadingIcon: Icons.upload_file_outlined,
                  onTap: _pickFile,
                ),
                _ImportStep.review ||
                _ImportStep.committing => _buildReview(context),
                _ImportStep.done => _buildSummary(context),
              },
            ),
          ),
        ),
        DemoBlock(
          code:
              "TransferFailureView(code: 'import_unsupported') · "
              'TransferFailureView(message:, onRetry:)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TransferFailureView(code: 'import_unsupported'),
              const DividerWidget(),
              TransferFailureView(
                message: LocaleKeys.showcaseDtFailed.tr(),
                onRetry: () => context.feedback.toast(
                  LocaleKeys.showcaseFailuresRetried.tr(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final textTheme = context.textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.colors.textMuted,
    );
    final report = _report();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(LocaleKeys.importReviewTitle.tr(), style: textTheme.titleSmall),
        8.heightBox,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(
              labelText: LocaleKeys.importRowsValid.tr(
                args: ['${report.validRows}'],
              ),
              tone: StatusTone.success,
            ),
            if (report.invalidRows > 0)
              StatusChip(
                labelText: LocaleKeys.importRowsInvalid.tr(
                  args: ['${report.invalidRows}'],
                ),
                tone: StatusTone.error,
              ),
          ],
        ),
        12.heightBox,
        ChipRow<_ReviewTab>(
          items: _ReviewTab.values,
          labelResolver: (t) => switch (t) {
            _ReviewTab.grid => LocaleKeys.importGridTab.tr(),
            _ReviewTab.problems => LocaleKeys.importListTab.tr(),
          },
          selectedValue: _tab,
          onSelected: (t) => setState(() => _tab = t ?? _tab),
          scrollable: false,
        ),
        8.heightBox,
        Text(LocaleKeys.showcaseDtFixHint.tr(), style: muted),
        8.heightBox,
        // Both scroll by themselves — in the app they fill the screen.
        SizedBox(
          height: context.screen.size(320),
          child: switch (_tab) {
            _ReviewTab.grid => ImportGrid(
              report: report,
              resource: _resource(),
              onEditCell: (row, column, value) => setState(() {
                _rows = [
                  for (var i = 0; i < _rows.length; i++)
                    i == row - 1 ? {..._rows[i], column: value} : _rows[i],
                ];
              }),
              onDeleteRow: (row) => setState(() {
                _rows = [..._rows]..removeAt(row - 1);
              }),
            ),
            _ReviewTab.problems => ImportErrorTable(report: report),
          },
        ),
        8.heightBox,
        Text(LocaleKeys.importNothingWritten.tr(), style: muted),
        12.heightBox,
        AppButton(
          text: LocaleKeys.importConfirm.tr(args: ['${report.validRows}']),
          isEnabled: report.canCommit,
          isLoading: _import == _ImportStep.committing,
          onTap: _commit,
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        LocaleKeys.importDoneTitle.tr(),
        style: context.textTheme.titleSmall,
      ),
      12.heightBox,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StatusChip(
            labelText: LocaleKeys.importInserted.tr(args: ['3']),
            tone: StatusTone.success,
          ),
          StatusChip(
            labelText: LocaleKeys.importUpdated.tr(args: ['1']),
            tone: StatusTone.info,
          ),
          StatusChip(
            labelText: LocaleKeys.importSkipped.tr(args: ['1']),
            tone: StatusTone.warning,
          ),
        ],
      ),
      12.heightBox,
      AppButton(
        text: LocaleKeys.showcaseReplay.tr(),
        variant: AppButtonVariant.text,
        onTap: () => setState(() => _import = _ImportStep.idle),
      ),
    ],
  );
}
