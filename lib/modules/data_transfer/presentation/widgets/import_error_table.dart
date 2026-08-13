import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/data_transfer/domain/import_report.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// The row-by-row problem list — the thing the review phase exists to show.
///
/// Two details here are the difference between a report a user can act on and
/// one they cannot:
///
/// 1. **It points at the spreadsheet line, not the data row.** The server
///    numbers data rows from 1; Excel's gutter counts the header as line 1. A
///    report that says "row 12" when the user's screen says 13 sends them to
///    the wrong line, every time, in a list they are already frustrated by.
/// 2. **A truncated list says so.** The server caps at 200. Presenting those as
///    the total would understate the work left and leave the user importing a
///    file they believe is clean.
class ImportErrorTable extends StatelessWidget {
  const ImportErrorTable({required this.report, super.key});

  final ImportReport report;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    if (report.errors.isEmpty) {
      return EmptyStateWidget(
        titleKey: LocaleKeys.importRowsValid,
        icon: Icons.check_circle_outline,
      );
    }

    return ListView.separated(
      padding: 16.horizontalPadding,
      itemCount: report.errors.length + (report.truncatedErrors ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == report.errors.length) {
          return Padding(
            padding: 8.verticalPadding,
            child: Text(
              LocaleKeys.importErrorsTruncated
                  .tr(args: ['${report.errors.length}']),
              style: context.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          );
        }
        return _ErrorRow(error: report.errors[index]);
      },
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.error});

  final ImportRowError error;

  @override
  Widget build(BuildContext context) {
    // Amber for "this row will be skipped", red for "you must change this".
    // One colour for both would train the user to ignore whichever they meet
    // first — and the skip case is by far the more common.
    final isWarning = error.severity == ImportSeverity.warning;
    final tint = isWarning ? context.colors.statusWarningFg : context.colors.error;

    return AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isWarning ? Icons.info_outline : Icons.error_outline,
              size: 18,
              color: tint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // `spreadsheetLine`, not `row` — see the class doc.
                    '${LocaleKeys.importRowLabel.tr(args: ['${error.spreadsheetLine}'])}'
                    ' · ${error.column ?? LocaleKeys.importWholeRow.tr()}',
                    style: context.textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    error.message,
                    style: context.textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (error.value != null && error.value!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${error.value}"',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (error.duplicateOfRow != null) ...[
                    const SizedBox(height: 4),
                    // Names the other row so the user can go delete one of the
                    // pair. "Duplicate" without saying of what is a dead end.
                    Text(
                      LocaleKeys.importDuplicateOf.tr(
                        args: ['${error.duplicateOfRow! + 1}'],
                      ),
                      style: context.textTheme.bodySmall?.copyWith(color: tint),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
  }
}
