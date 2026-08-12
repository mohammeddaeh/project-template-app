import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/data_transfer/domain/import_report.dart';
import 'package:app_template/modules/data_transfer/domain/transfer_resource.dart';
import 'package:app_template/modules/data_transfer/presentation/cubits/import_cubit.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/import_error_table.dart';
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
              if (state is ImportTemplateReady) _shareTemplate(context, state.file);
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
              ImportReviewing(:final report) => _ReviewStep(report: report),
              ImportCommitting() => const _Busy(labelKey: LocaleKeys.importCommitting),
              ImportCommitted(:final result) => _DoneStep(result: result),
            },
          ),
        ),
      ),
    );
  }

  Future<void> _shareTemplate(BuildContext context, File file) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: file.uri.pathSegments.last),
    );
    if (!context.mounted) return;
    context.feedback.success(LocaleKeys.importTemplateReady.tr());
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

        SectionTitle(titleKey: LocaleKeys.exportColumns),
        // Only importable columns. Showing `id` and `created_at` here would
        // invite the user to fill them in and then be told they were ignored.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final column in resource.importableColumns)
              ChipWidget(
                // `labelKey` receives an already-translated string, the same
                // passthrough `ErrorStateWidget` relies on: the label comes
                // from the server descriptor and was never a local key.
                labelKey: column.required
                    ? '${column.label(isArabic: isArabic)} *'
                    : column.label(isArabic: isArabic),
              ),
          ],
        ),
        const SizedBox(height: 24),

        AppButton(
          text: LocaleKeys.importDownloadTemplate.tr(),
          variant: AppButtonVariant.text,
          onTap: busy || resource.importFormats.isEmpty
              ? null
              : () => cubit.downloadTemplate(resource.importFormats.first),
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

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.report});

  final ImportReport report;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ImportCubit>();

    return Column(
      children: [
        Padding(
          padding: 16.allPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.importReviewTitle.tr(),
                style: context.textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              // Stated plainly, because it is the whole reason this step
              // exists. A user who thinks the import already happened will not
              // read the errors.
              Text(
                LocaleKeys.importNothingWritten.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.statusWarningFg,
                ),
              ),
              const SizedBox(height: 16),
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
            ],
          ),
        ),
        Expanded(child: ImportErrorTable(report: report)),
        SafeArea(
          child: Padding(
            padding: 16.allPadding,
            child: Column(
              children: [
                if (report.canCommit)
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
