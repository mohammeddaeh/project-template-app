import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/sim_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `modules/data_transfer/` played on the device: export with a progress bar
/// to a ready file, and the two-phase import — the file checked first with the
/// failing cell marked, then committed to a summary.
class DataTransferSimDemo extends StatefulWidget {
  const DataTransferSimDemo({super.key});

  @override
  State<DataTransferSimDemo> createState() => _DataTransferSimDemoState();
}

enum _ImportStep { idle, review, committing, done }

class _DataTransferSimDemoState extends State<DataTransferSimDemo> {
  /// The formats the module implements (`TransferFormat`): wire name → label.
  static const _formats = {'csv': 'CSV', 'xlsx': 'Excel'};

  /// The row the fake validation rejects (1-based, as the server counts).
  static const _badRow = 3;

  String _format = 'csv';
  double? _progress;
  bool _ready = false;
  _ImportStep _import = _ImportStep.idle;

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
          code: "DataTransferSheet.show(context, resource: 'notes')",
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
          code: 'TransferImportScreen — validate, then commit',
          child: AnimatedSwitcher(
            duration: motion.base,
            child: KeyedSubtree(
              key: ValueKey(_import),
              child: switch (_import) {
                _ImportStep.idle => AppButton(
                  text: LocaleKeys.importPickFile.tr(),
                  variant: AppButtonVariant.tonal,
                  leadingIcon: Icons.upload_file_outlined,
                  onTap: () => setState(() => _import = _ImportStep.review),
                ),
                _ImportStep.review ||
                _ImportStep.committing => _buildReview(context),
                _ImportStep.done => _buildSummary(context),
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    const valid = 5 - 1;

    TableRow row(List<String> cells, {bool header = false, int? line}) =>
        TableRow(
          children: [
            for (var c = 0; c < cells.length; c++)
              Container(
                padding: 8.allPadding,
                color: (line == _badRow && c == 2)
                    ? colors.statusErrorBg
                    : header
                    ? colors.bgNeutral
                    : null,
                child: Text(
                  cells[c],
                  style: header
                      ? textTheme.labelMedium
                      : (line == _badRow && c == 2)
                      ? textTheme.bodySmall?.copyWith(
                          color: colors.statusErrorFg,
                        )
                      : textTheme.bodySmall,
                ),
              ),
          ],
        );

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
              labelText: LocaleKeys.importRowsValid.tr(args: ['$valid']),
              tone: StatusTone.success,
            ),
            StatusChip(
              labelText: LocaleKeys.importRowsInvalid.tr(args: ['1']),
              tone: StatusTone.error,
            ),
          ],
        ),
        12.heightBox,
        // The header is the column *key*, as the file carries it — not a label.
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Table(
            border: TableBorder.all(color: colors.dividerSubtle),
            columnWidths: const {0: IntrinsicColumnWidth()},
            children: [
              row(['#', 'title', 'amount'], header: true),
              for (var i = 1; i <= 5; i++)
                row([
                  '${i + 1}',
                  LocaleKeys.showcaseItem.tr(args: ['$i']),
                  i == _badRow ? 'abc' : '${i * 120}',
                ], line: i),
            ],
          ),
        ),
        8.heightBox,
        Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: colors.statusErrorFg),
            4.widthBox,
            Expanded(
              child: Text(
                '${LocaleKeys.importRowLabel.tr(args: ['${_badRow + 1}'])} · '
                'amount · ${LocaleKeys.showcaseDtNotNumber.tr()}',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.statusErrorFg,
                ),
              ),
            ),
          ],
        ),
        4.heightBox,
        Text(
          LocaleKeys.importNothingWritten.tr(),
          style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
        12.heightBox,
        AppButton(
          text: LocaleKeys.importConfirm.tr(args: ['$valid']),
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
