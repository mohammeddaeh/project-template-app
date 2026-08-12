import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/data_transfer/domain/transfer_resource.dart';
import 'package:app_template/modules/data_transfer/presentation/cubits/export_cubit.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/transfer_failure_view.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/locale/locale_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// Export, for whatever `resource` it is given.
///
/// **Read the build method and notice what is missing: any mention of notes,
/// or of any other feature.** Every label, column, format and filter is drawn
/// from the descriptor the server sent. That is the property the whole module
/// exists to have — a new transferable feature ships with no Dart at all.
@RoutePage()
class TransferExportScreen extends StatelessWidget {
  const TransferExportScreen({required this.resource, super.key});

  /// Wire name, e.g. `notes`. A plain string rather than an enum: an enum would
  /// need regenerating every time the server gained a resource.
  final String resource;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return BlocProvider(
      create: (_) => getIt<ExportCubit>()..load(resource),
      child: Builder(
        // Below the provider, so `context.read<ExportCubit>()` resolves. The
        // tempting `getIt<ExportCubit>()` instead would not throw and would be
        // wrong: the cubit is a factory, so it builds a second, empty instance.
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(LocaleKeys.exportTitle.tr())),
          body: BlocConsumer<ExportCubit, ExportState>(
            listener: (context, state) {
              if (state is ExportDone) _share(context, state.file);
            },
            builder: (context, state) => switch (state) {
              ExportInitial() || ExportLoading() => const LoadingWidget(),
              ExportFailed(:final message, :final code) => TransferFailureView(
                  message: message,
                  code: code,
                  onRetry: () => context.read<ExportCubit>().load(resource),
                ),
              ExportReady() => _Form(state: state, busy: false),
              ExportRunning(:final ready) => _Form(state: ready, busy: true),
              ExportDone(:final ready) => _Form(state: ready, busy: false),
            },
          ),
        ),
      ),
    );
  }

  /// Hands the file to the OS share sheet.
  ///
  /// Share rather than open: the file lives in the app's temporary directory,
  /// where "open" leaves the user with something that disappears on the next
  /// cache sweep. Sharing lets them put it somewhere they chose — Drive, mail,
  /// Files — which is what a person exporting data is actually trying to do.
  Future<void> _share(BuildContext context, File file) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: file.uri.pathSegments.last),
    );
    if (!context.mounted) return;
    context.feedback.success(LocaleKeys.exportReadyTitle.tr());
    context.read<ExportCubit>().reset();
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state, required this.busy});

  final ExportReady state;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExportCubit>();
    final isArabic = context.isAr;
    final resource = state.resource;

    return Stack(
      children: [
        ListView(
          padding: 16.allPadding,
          children: [
            Text(
              resource.label(isArabic: isArabic),
              style: context.textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              // Stated up front, not discovered through a 413. A limit the user
              // meets as a refusal is a limit they were never told about.
              LocaleKeys.exportRowLimit.tr(args: ['${resource.maxExportRows}']),
              style: context.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            SectionTitle(titleKey: LocaleKeys.exportFormat),
            const SizedBox(height: 8),
            SegmentedButton<TransferFormat>(
              segments: [
                for (final format in resource.exportFormats)
                  ButtonSegment(value: format, label: Text(format.label)),
              ],
              selected: {state.format},
              onSelectionChanged:
                  busy ? null : (s) => cubit.selectFormat(s.first),
            ),
            const SizedBox(height: 24),

            SectionTitle(titleKey: LocaleKeys.exportColumns),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final column in resource.columns)
                  FilterChip(
                    label: Text(column.label(isArabic: isArabic)),
                    selected: state.selectedColumns.contains(column.key),
                    onSelected:
                        busy ? null : (_) => cubit.toggleColumn(column.key),
                  ),
              ],
            ),

            // Filters are rendered from the descriptor too. This template ships
            // a free-text `q` because that is what the reference resource
            // declares; a resource with typed filters would extend the
            // descriptor and this switch, never this screen's callers.
            const SizedBox(height: 24),
            SectionTitle(titleKey: LocaleKeys.exportFilters),
            const SizedBox(height: 8),
            CustomTextField(
              hint: LocaleKeys.exportFilters.tr(),
              enabled: !busy,
              onChanged: (value) => cubit.setFilter('q', value),
            ),

            const SizedBox(height: 32),
            PrimaryButton(
              text: LocaleKeys.exportRun.tr(),
              isLoading: busy,
              onTap: busy ? null : cubit.run,
            ),
            const SizedBox(height: 16),
          ],
        ),
        if (busy)
          // A thin bar rather than a blocking overlay: the choices behind it
          // are still true and still worth reading while the file builds.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}
