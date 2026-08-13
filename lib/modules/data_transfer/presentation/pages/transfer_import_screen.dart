import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/data_transfer/domain/import_report.dart';
import 'package:app_template/modules/data_transfer/domain/transfer_resource.dart';
import 'package:app_template/modules/data_transfer/presentation/cubits/import_cubit.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/import_error_table.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/import_grid.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/transfer_file_sheet.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/transfer_format_sheet.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/transfer_failure_view.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/locale/locale_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// Import, for whatever `resource` it is given — and, like the export screen,
/// with no mention of any feature.
///
/// The screen mirrors the server's two phases exactly, because the phases are
/// the promise being made: **the review step exists so that nothing is written
/// until the user has seen what would be.** `ImportReviewing` says so on the
/// screen, in as many words.
@RoutePage()
class TransferImportScreen extends StatelessWidget {
  const TransferImportScreen({required this.resource, super.key});

  final String resource;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return BlocProvider(
      create: (_) => getIt<ImportCubit>()..load(resource),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(LocaleKeys.importTitle.tr())),
          body: BlocConsumer<ImportCubit, ImportState>(
            listener: (context, state) {
              // The template is offered, not pushed at the user: preview it,
              // save it, or share it. Opening the OS share sheet automatically
              // — which this used to do — made "share" the only outcome, and
              // the file lived in a temp directory that the next cache sweep
              // would take.
              if (state is ImportTemplateReady) {
                TransferFileSheet.show(
                  context,
                  file: state.file,
                  titleKey: LocaleKeys.templateReady,
                );
              }
              if (state is ImportCommitted) {
                context.feedback.success(LocaleKeys.importDoneTitle.tr());
              }
            },
            builder: (context, state) => switch (state) {
              ImportInitial() || ImportLoading() => const LoadingWidget(),
              ImportFailed(:final message, :final code) => TransferFailureView(
                  message: message,
                  code: code,
                  onRetry: () => context.read<ImportCubit>().load(resource),
                ),
              ImportReady(:final resource) =>
                _PickStep(resource: resource, busy: false),
              ImportTemplateLoading(:final resource) =>
                _PickStep(resource: resource, busy: true),
              ImportTemplateReady(:final resource) =>
                _PickStep(resource: resource, busy: false),
              ImportValidating() => const _Busy(labelKey: LocaleKeys.importValidating),
              ImportReviewing() => _ReviewStep(state: state),
              ImportCommitting() => const _Busy(labelKey: LocaleKeys.importCommitting),
              ImportCommitted(:final result) => _DoneStep(result: result),
            },
          ),
        ),
      ),
    );
  }

}

// ── Phase 0: choose a file ───────────────────────────────────────────────────

class _PickStep extends StatelessWidget {
  const _PickStep({required this.resource, required this.busy});

  final TransferResource resource;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ImportCubit>();
    final isArabic = context.isAr;

    return ListView(
      padding: 16.allPadding,
      children: [
        Text(
          resource.label(isArabic: isArabic),
          style: context.textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),

        SectionTitle(titleKey: LocaleKeys.importColumnsTitle),
        Text(
          // Answers the question the old chip row provoked: "why only three?"
          // A user looking at a seven-column export and a three-field import
          // has no way to know the other four are ours unless we say so.
          LocaleKeys.importColumnsHint.tr(),
          style: context.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final column in resource.importableColumns)
          _ColumnRow(column: column, isArabic: isArabic),

        if (resource.systemColumns.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            LocaleKeys.importSystemColumns.tr(
              args: [
                resource.systemColumns
                    .map((c) => c.label(isArabic: isArabic))
                    .join('، '),
              ],
            ),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 24),

        AppButton(
          text: LocaleKeys.importDownloadTemplate.tr(),
          variant: AppButtonVariant.text,
          onTap: busy || resource.importFormats.isEmpty
              ? null
              : () => _downloadTemplate(context, cubit, resource),
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          text: LocaleKeys.importPickFile.tr(),
          isLoading: busy,
          onTap: busy ? null : () => _pick(context, cubit, resource),
        ),
      ],
    );
  }

  /// Asks which format, then downloads.
  ///
  /// It used to take `importFormats.first` silently. CSV and XLSX are not
  /// interchangeable for the person about to fill the file in — one opens in a
  /// text editor, the other keeps dates as dates — so the choice is theirs. The
  /// sheet skips itself when the server offers only one, so the extra tap
  /// appears only where there is something to decide.
  Future<void> _downloadTemplate(
    BuildContext context,
    ImportCubit cubit,
    TransferResource resource,
  ) async {
    final format = await TransferFormatSheet.show(
      context,
      formats: resource.importFormats,
      titleKey: LocaleKeys.chooseFormat,
    );
    if (format == null) return; // Backed out — not an error.
    if (!context.mounted) return;
    await cubit.downloadTemplate(format);
  }

  /// Restricts the picker to what the resource actually accepts.
  ///
  /// Taken from the descriptor rather than hardcoded to `csv`/`xlsx`: a server
  /// that stops accepting one of them must not still be offered it here, or the
  /// refusal arrives after the upload instead of before it.
  Future<void> _pick(
    BuildContext context,
    ImportCubit cubit,
    TransferResource resource,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: resource.importFormats.map((f) => f.wire).toList(),
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return; // Cancelled — not an error.
    if (!context.mounted) return;
    await cubit.validate(File(path));
  }
}

// ── Phase 1: review ──────────────────────────────────────────────────────────

/// The review phase — **the screen this whole feature exists for.**
///
/// Two tabs over the same report: the file as an editable grid, and the problem
/// list. The grid is first because a red cell in front of the user is a fix
/// they make; a list of line numbers is a chore they postpone.
class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state});

  final ImportReviewing state;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    final cubit = context.read<ImportCubit>();
    final report = state.report;
    final warnings = report.errors
        .where((e) => e.severity == ImportSeverity.warning)
        .map((e) => e.row)
        .toSet()
        .length;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: 16.horizontalPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  LocaleKeys.importReviewTitle.tr(),
                  style: context.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                // Stated plainly, because it is the whole reason this step
                // exists. A user who thinks the import already happened will
                // not read the errors.
                Text(
                  LocaleKeys.importNothingWritten.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.statusWarningFg,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        labelText: LocaleKeys.importRowsValid.tr(
                          args: ['${report.validRows}'],
                        ),
                        value: '${report.validRows}',
                        color: context.colors.statusSuccessFg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        labelText: LocaleKeys.importRowsInvalid.tr(
                          args: ['${report.invalidRows}'],
                        ),
                        value: '${report.invalidRows}',
                        color: context.colors.error,
                      ),
                    ),
                  ],
                ),
                if (warnings > 0) ...[
                  const SizedBox(height: 8),
                  // Warnings are counted apart from errors on purpose: "12 rows
                  // will be skipped because they already exist" is information,
                  // not a fault, and folding it into the red number would make
                  // a correct import look broken.
                  Text(
                    LocaleKeys.importWarnings.tr(args: ['$warnings']),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.statusWarningFg,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TabBar(
            tabs: [
              Tab(text: LocaleKeys.importGridTab.tr()),
              Tab(text: LocaleKeys.importListTab.tr()),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                if (report.hasGrid)
                  ImportGrid(
                    report: report,
                    resource: state.resource,
                    onEditCell: cubit.editCell,
                    onDeleteRow: cubit.deleteRow,
                  )
                else
                  // Past the preview cap the server sends no rows. Saying so
                  // beats an empty grid that looks like a loading failure.
                  Padding(
                    padding: 24.allPadding,
                    child: EmptyStateWidget(
                      titleKey: LocaleKeys.importRowsTooMany,
                      icon: Icons.table_chart_outlined,
                    ),
                  ),
                ImportErrorTable(report: report),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: 16.allPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.dirty)
                    // The report on screen describes the rows *before* these
                    // edits, and the staged token describes data that no longer
                    // exists — a deleted row renumbered everything after it. So
                    // the only action offered is to re-check.
                    PrimaryButton(
                      text: LocaleKeys.importRecheck.tr(),
                      onTap: cubit.recheck,
                    )
                  else if (report.canCommit)
                    PrimaryButton(
                      text: LocaleKeys.importConfirm.tr(
                        args: ['${report.validRows}'],
                      ),
                      onTap: cubit.confirm,
                    )
                  else
                    // No token, so no button. The server withheld one because
                    // nothing is importable, and an enabled confirm here would
                    // report "inserted: 0" as a success.
                    Text(
                      LocaleKeys.importNothingValid.tr(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (state.dirty) ...[
                    const SizedBox(height: 6),
                    Text(
                      LocaleKeys.importEditedNotice.tr(),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.statusWarningFg,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 8),
                  AppButton(
                    text: LocaleKeys.importStartOver.tr(),
                    variant: AppButtonVariant.text,
                    onTap: cubit.startOver,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Phase 2: done ────────────────────────────────────────────────────────────

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.result});

  final ImportResult result;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ImportCubit>();

    return Padding(
      padding: 16.allPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: context.colors.statusSuccessFg,
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.importDoneTitle.tr(),
            style: context.textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          // Every count, including the zeros: "0 skipped" is information, and
          // hiding it leaves the user wondering whether skipping happened at
          // all. `failed` is the exception — it is non-zero only when a staged
          // row stopped validating between the two phases, which is rare enough
          // that showing "0 failed" on every success would raise a question no
          // one asked.
          Text(
            LocaleKeys.importInserted.tr(args: ['${result.inserted}']),
            style: context.textTheme.bodyMedium,
          ),
          Text(
            LocaleKeys.importUpdated.tr(args: ['${result.updated}']),
            style: context.textTheme.bodyMedium,
          ),
          Text(
            LocaleKeys.importSkipped.tr(args: ['${result.skipped}']),
            style: context.textTheme.bodyMedium,
          ),
          if (result.failed > 0)
            Text(
              LocaleKeys.importFailedRows.tr(args: ['${result.failed}']),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.error,
              ),
            ),
          const Spacer(),
          AppButton(
            text: LocaleKeys.importStartOver.tr(),
            onTap: cubit.startOver,
          ),
        ],
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(),
            const SizedBox(height: 16),
            Text(labelKey.tr(), style: context.textTheme.bodyMedium),
          ],
        ),
      );
}

/// One importable column, explained.
///
/// Replaces a row of chips that carried a name and a bare `*`. The chips were
/// also visually wrong — `ChipWidget` wraps a bare `InputChip`, whose default
/// palette is the Material *selection* palette, not this project's semantic
/// tokens, so column names came out in colours that belong to a chosen filter.
///
/// Everything here reads from `context.colors` / `context.textTheme`, which is
/// the rule in `lib/CLAUDE.md`.
class _ColumnRow extends StatelessWidget {
  const _ColumnRow({required this.column, required this.isArabic});

  final TransferColumn column;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final hint = column.hint(isArabic: isArabic);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconFor(column.type),
            size: 18,
            color: context.colors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        column.label(isArabic: isArabic),
                        style: context.textTheme.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // A word, not an asterisk. "*" is a convention people read
                    // past; "Required" is not.
                    _Badge(
                      text: column.required
                          ? LocaleKeys.importRequired.tr()
                          : LocaleKeys.importOptional.tr(),
                      color: column.required
                          ? context.colors.statusWarningFg
                          : context.colors.textMuted,
                    ),
                  ],
                ),
                if (hint != null && hint.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  // The server's own explanation of what this column means —
                  // not a sample value, which is what used to be shown here and
                  // answered a question nobody was asking.
                  Text(
                    hint,
                    style: context.textTheme.bodySmall,
                  ),
                ],
                if (column.example != null && column.example!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    LocaleKeys.importColumnExample.tr(args: [column.example!]),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A glyph for the cell type, so "this wants a date" is visible before the
  /// user fills the file in rather than after the importer refuses it.
  static IconData _iconFor(TransferColumnType type) => switch (type) {
        TransferColumnType.number => Icons.tag,
        TransferColumnType.boolean => Icons.check_box_outlined,
        TransferColumnType.date => Icons.event_outlined,
        TransferColumnType.datetime => Icons.schedule_outlined,
        TransferColumnType.string || TransferColumnType.unknown =>
          Icons.text_fields,
      };
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: context.textTheme.bodySmall?.copyWith(color: color),
        ),
      );
}
