import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/data_transfer/domain/transfer_resource.dart';
import 'package:app_template/modules/data_transfer/presentation/cubits/export_cubit.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/transfer_failure_view.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/transfer_file_sheet.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
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
              if (state is ExportDone) _deliver(context, state.file);
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

  /// Offers the finished file: preview, save, share, or open.
  ///
  /// It used to open the OS share sheet directly. The file lives in the app's
  /// **temporary** directory, so sharing was the only way it survived at all —
  /// and anyone who dismissed that sheet lost their export to the next cache
  /// sweep with no way back but re-running it. Now "save to device" is a real
  /// option, and preview lets them check the columns before doing either.
  Future<void> _deliver(BuildContext context, File file) async {
    final cubit = context.read<ExportCubit>();
    await TransferFileSheet.show(
      context,
      file: file,
      titleKey: LocaleKeys.fileReady,
    );
    if (!context.mounted) return;
    // Back to the form with the selection intact, whatever they chose — or
    // chose not to do.
    cubit.reset();
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.state, required this.busy});

  final ExportReady state;
  final bool busy;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  /// One controller per **declared** text filter, keyed by its wire key.
  ///
  /// Built from the descriptor rather than a single hardcoded `q` box. That box
  /// was the last piece of per-feature knowledge left in this screen, and it
  /// was wrong the moment a real application named its filter `search`: the
  /// field sent a parameter the server's schema ignored, so it filtered
  /// nothing, silently, with no error to notice.
  ///
  /// Controllers rather than an `onChanged(String)` callback because
  /// `CustomTextField`'s signature differs between the projects this module is
  /// copied into — one types it `VoidCallback` deliberately. A listener does
  /// not depend on that, which keeps this file identical everywhere.
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final filter in widget.state.resource.filters) {
      if (filter.type != TransferFilterType.text) continue;
      final controller = TextEditingController()
        ..addListener(() => _onTextFilterChanged(filter.key));
      _controllers[filter.key] = controller;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTextFilterChanged(String key) =>
      context.read<ExportCubit>().setFilter(key, _controllers[key]!.text);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExportCubit>();
    final isArabic = context.isAr;
    final state = widget.state;
    final busy = widget.busy;
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

            // Filters come from the descriptor — label, placeholder, query key
            // and all. The section disappears entirely for a resource that
            // declares none, rather than showing an unexplained empty box.
            if (resource.filters.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionTitle(titleKey: LocaleKeys.exportFilters),
              Text(
                // Says what the control is for. "Filters" over a bare text box
                // told the user nothing about what it searched or whether
                // leaving it empty meant "everything".
                LocaleKeys.exportFiltersHint.tr(),
                style: context.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final filter in resource.filters)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FilterField(
                    filter: filter,
                    controller: _controllers[filter.key],
                    value: state.filters[filter.key],
                    enabled: !busy,
                    onChanged: (value) => cubit.setFilter(filter.key, value),
                    isArabic: isArabic,
                  ),
                ),
            ],

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

/// One filter control, drawn from its declaration.
///
/// The `switch` is the only place this module knows what a filter type looks
/// like. A type the descriptor sends that this build cannot draw never reaches
/// here — the model drops it, because a `select` rendered as a free-text box
/// invites the user to type a value the server will reject.
class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.filter,
    required this.controller,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.isArabic,
  });

  final TransferFilter filter;

  /// Present for `text` filters only — the state owns and disposes it.
  final TextEditingController? controller;

  /// The current value from the cubit. Drives `select` and `boolean`, which
  /// have no controller of their own.
  final String? value;

  final bool enabled;
  final void Function(String value) onChanged;
  final bool isArabic;

  @override
  Widget build(BuildContext context) => switch (filter.type) {
        TransferFilterType.text => CustomTextField(
            controller: controller,
            labelText: filter.label(isArabic: isArabic),
            // The placeholder says what the box searches. Without it the field
            // reads as "Filters", which answers nothing.
            hint: filter.placeholder(isArabic: isArabic) ??
                filter.label(isArabic: isArabic),
            enabled: enabled,
          ),
        // The project's own select field: it takes items + a label resolver,
        // not DropdownMenuItems, and matches CustomTextField visually.
        TransferFilterType.select => AppSelectField<TransferFilterOption>(
            labelText: filter.label(isArabic: isArabic),
            hint: filter.placeholder(isArabic: isArabic),
            items: filter.options,
            labelResolver: (o) => o.label(isArabic: isArabic),
            value: filter.options
                .where((o) => o.value == value)
                .firstOrNull,
            enabled: enabled,
            onChanged: (o) => onChanged(o?.value ?? ''),
          ),
        TransferFilterType.boolean => SwitchListTile(
            title: Text(
              filter.label(isArabic: isArabic),
              style: context.textTheme.bodyMedium,
            ),
            value: value == 'true',
            // Cleared rather than sent as `false`: for most boolean filters
            // "off" means "do not filter", and sending `false` would narrow the
            // export to the rows that are explicitly false.
            onChanged:
                enabled ? (on) => onChanged(on ? 'true' : '') : null,
            contentPadding: EdgeInsets.zero,
          ),
        TransferFilterType.unknown => const SizedBox.shrink(),
      };
}
