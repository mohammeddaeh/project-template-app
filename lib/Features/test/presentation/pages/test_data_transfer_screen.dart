import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/data_transfer/data_transfer_plugin.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
import 'package:app_template/presentation/locale/locale_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// **Scenario #14 — Import / export, live against `backend_template`.**
///
/// Required by the mirror rule in the root `CLAUDE.md`: a module with
/// user-facing options has to have an interactive control here.
///
/// What this screen demonstrates that a static demo could not: the resource
/// list is **not written anywhere in this file**. It is fetched from
/// `GET /api/v1/data-transfer/resources` and rendered as it arrives. Declare a
/// new `*.transfer.ts` on the server, restart nothing here, and it appears —
/// which is the property the whole module exists to have, and the only honest
/// way to show it is to fetch it.
@RoutePage()
class TestDataTransferScreen extends StatefulWidget {
  const TestDataTransferScreen({super.key});

  @override
  State<TestDataTransferScreen> createState() => _TestDataTransferScreenState();
}

class _TestDataTransferScreenState extends State<TestDataTransferScreen> {
  late Future<List<TransferResource>>? _future = _load();

  Future<List<TransferResource>> _load() async {
    // Guarded, not assumed: with the flag off nothing is registered and
    // `getIt` would throw rather than return an empty list.
    if (!AppFeatures.dataTransfer) return const [];
    final result = await getIt<DataTransferRepository>().resources();
    return result.fold((_) => const [], (resources) => resources);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.testDataTransferTitle.tr())),
      body: ListView(
        padding: 16.allPadding,
        children: [
          _FlagBanner(enabled: AppFeatures.dataTransfer),
          const SizedBox(height: 16),

          Text(
            LocaleKeys.testDataTransferSubtitle.tr(),
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          if (!AppFeatures.dataTransfer)
            EmptyStateWidget(
              titleKey: LocaleKeys.transferModuleOff,
              icon: Icons.toggle_off_outlined,
            )
          else
            FutureBuilder<List<TransferResource>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingWidget();
                }
                final resources = snapshot.data ?? const <TransferResource>[];
                if (resources.isEmpty) {
                  return ErrorStateWidget(
                    messageKey: LocaleKeys.transferNoResources,
                    onRetry: () => setState(() => _future = _load()),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      LocaleKeys.transferResourcesFound
                          .tr(args: ['${resources.length}']),
                      style: context.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    for (final resource in resources)
                      _ResourceCard(resource: resource),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// States the flag rather than hiding behind it. A demo screen that silently
/// does nothing when a feature is off teaches the reader that the feature is
/// broken.
class _FlagBanner extends StatelessWidget {
  const _FlagBanner({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(
          children: [
            Icon(
              enabled ? Icons.check_circle_outline : Icons.info_outline,
              color: enabled
                  ? context.colors.statusSuccessFg
                  : context.colors.statusWarningFg,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AppFeatures.dataTransfer = $enabled',
                style: context.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource});

  final TransferResource resource;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isAr;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    resource.label(isArabic: isArabic),
                    style: context.textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  resource.name,
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Everything below is read off the descriptor — the counts, the
            // formats, whether import is offered at all.
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final format in resource.exportFormats)
                  ChipWidget(labelKey: '↓ ${format.label}'),
                for (final format in resource.importFormats)
                  ChipWidget(labelKey: '↑ ${format.label}'),
                ChipWidget(
                  labelKey: '${resource.columns.length} cols '
                      '(${resource.importableColumns.length} importable)',
                ),
                ChipWidget(labelKey: 'max ${resource.maxExportRows}'),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              text: LocaleKeys.dataTransfer.tr(),
              variant: AppButtonVariant.tonal,
              onTap: () =>
                  DataTransferSheet.show(context, resource: resource.name),
            ),
          ],
        ),
      ),
    );
  }
}
