import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:app_template/modules/data_transfer/data/csv_preview_parser.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// The downloaded CSV, as a table.
///
/// Answers the one question a user has between downloading and deciding what to
/// do with the file — *are these my columns, in the right order, with the right
/// values?* — which a wall of commas and quotes does not.
///
/// It reads the **file on disk**, not the data the app used to request it. That
/// distinction is the whole point: this shows what the server actually sent,
/// so a wrong column set or a mojibake header is visible here rather than
/// discovered in Excel an hour later.
class CsvPreviewView extends StatefulWidget {
  const CsvPreviewView({required this.file, super.key});

  final File file;

  @override
  State<CsvPreviewView> createState() => _CsvPreviewViewState();
}

class _CsvPreviewViewState extends State<CsvPreviewView> {
  late final Future<CsvPreview> _preview = CsvPreviewParser.fromFile(widget.file);

  /// Shared by the header and the body so the two cannot drift apart while
  /// scrolling a wide file sideways.
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  static const _gutter = 48.0;
  static const _columnWidth = 140.0;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return FutureBuilder<CsvPreview>(
      future: _preview,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: AppLoader());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: 24.allPadding,
              child: ErrorStateWidget(messageKey: LocaleKeys.filePreviewFailed),
            ),
          );
        }

        final preview = snapshot.data!;
        if (preview.isEmpty) {
          return EmptyStateWidget(
            titleKey: LocaleKeys.filePreviewEmpty,
            icon: Icons.description_outlined,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: 16.horizontalPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.basename(widget.file.path),
                    style: context.textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // The count is of what is *shown*, and says so when the
                    // parser stopped early — a number read off a truncated
                    // table would otherwise be taken for the file's total.
                    preview.truncated
                        ? LocaleKeys.filePreviewTruncated
                            .tr(args: ['${preview.rows.length}'])
                        : LocaleKeys.filePreviewRows
                            .tr(args: ['${preview.rows.length}']),
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _HeaderRow(
              header: preview.header,
              controller: _horizontal,
              gutter: _gutter,
              columnWidth: _columnWidth,
            ),
            Expanded(
              child: preview.rows.isEmpty
                  ? Center(
                      child: Text(
                        // A template legitimately has headers and no data.
                        LocaleKeys.filePreviewHeaderOnly.tr(),
                        style: context.textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      itemCount: preview.rows.length,
                      itemExtent: 40,
                      itemBuilder: (context, index) => _DataRow(
                        number: index + 1,
                        cells: preview.rows[index],
                        columnCount: preview.header.length,
                        controller: _horizontal,
                        gutter: _gutter,
                        columnWidth: _columnWidth,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.header,
    required this.controller,
    required this.gutter,
    required this.columnWidth,
  });

  final List<String> header;
  final ScrollController controller;
  final double gutter;
  final double columnWidth;

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        decoration: BoxDecoration(
          color: context.colors.bgNeutral,
          border: Border(bottom: BorderSide(color: context.colors.borderSubtle)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: gutter,
              child: Center(child: Text('#', style: context.textTheme.bodySmall)),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                // The body owns the gesture; the header follows it. Two
                // independently scrollable axes drift out of alignment.
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    for (final cell in header)
                      SizedBox(
                        width: columnWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              cell,
                              style: context.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.number,
    required this.cells,
    required this.columnCount,
    required this.controller,
    required this.gutter,
    required this.columnWidth,
  });

  final int number;
  final List<String> cells;
  final int columnCount;
  final ScrollController controller;
  final double gutter;
  final double columnWidth;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.colors.dividerSubtle)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: gutter,
              child: Center(
                child: Text('$number', style: context.textTheme.bodySmall),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Indexed against the HEADER's width, not this row's: a
                    // short row must leave blank cells rather than shift the
                    // columns after it left by one.
                    for (var i = 0; i < columnCount; i++)
                      SizedBox(
                        width: columnWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              i < cells.length && cells[i].isNotEmpty
                                  ? cells[i]
                                  : '—',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: i < cells.length && cells[i].isNotEmpty
                                    ? null
                                    : context.colors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
