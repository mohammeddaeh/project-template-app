import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/access_control/access_control_plugin.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
import 'package:app_template/presentation/locale/locale_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// **Scenario #15 — Roles & permissions, live against `backend_template`.**
///
/// Required by the mirror rule in the root `CLAUDE.md`: a module with
/// user-facing options has to have an interactive control here.
///
/// What this screen demonstrates that a static demo could not: **the permission
/// list is not written anywhere in this file.** It is fetched from
/// `GET /api/v1/authz/catalog`, and the gate below is driven by a key the
/// reader types. Guard a new route on the server with
/// `requirePermission('invoices.approve')`, restart nothing here, and the key
/// works — which is the property the whole module exists to have, and the only
/// honest way to show it is to fetch it.
@RoutePage()
class TestAccessControlScreen extends StatefulWidget {
  const TestAccessControlScreen({super.key});

  @override
  State<TestAccessControlScreen> createState() =>
      _TestAccessControlScreenState();
}

class _TestAccessControlScreenState extends State<TestAccessControlScreen> {
  final _keyController = TextEditingController(text: 'notes.update');
  CanMode _mode = CanMode.hide;

  late Future<PermissionCatalog?> _catalog = _loadCatalog();

  Future<PermissionCatalog?> _loadCatalog() async {
    // Guarded, not assumed: with the flag off nothing is registered and
    // `getIt` would throw rather than return null.
    if (!AppFeatures.accessControl) return null;
    final result = await getIt<AccessControlRepository>().catalog();
    // A non-admin account is refused the catalog by design — `roles.view`
    // guards it. Reporting that as "no catalog" is the honest rendering.
    return result.fold((_) => null, (catalog) => catalog);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.testAccessControlTitle.tr())),
      body: ListView(
        padding: 16.allPadding,
        children: [
          _FlagBanner(enabled: AppFeatures.accessControl),
          const SizedBox(height: 16),

          Text(
            LocaleKeys.testAccessControlSubtitle.tr(),
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          if (!AppFeatures.accessControl)
            EmptyStateWidget(
              titleKey: LocaleKeys.accessModuleOff,
              icon: Icons.toggle_off_outlined,
            )
          else ...[
            _AbilitiesCard(onRefresh: () => setState(() {})),
            const SizedBox(height: 16),
            _GatePlayground(
              controller: _keyController,
              mode: _mode,
              onModeChanged: (mode) => setState(() => _mode = mode),
            ),
            const SizedBox(height: 16),
            FutureBuilder<PermissionCatalog?>(
              future: _catalog,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingWidget();
                }
                final catalog = snapshot.data;
                if (catalog == null) {
                  return ErrorStateWidget(
                    messageKey: LocaleKeys.forbiddenAction,
                    onRetry: () =>
                        setState(() => _catalog = _loadCatalog()),
                  );
                }
                return _CatalogCard(catalog: catalog);
              },
            ),
            const SizedBox(height: 16),
            AppButton(
              text: LocaleKeys.accessOpenRoles.tr(),
              onTap: () => context.router.push(const RolesRoute()),
            ),
          ],
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
            'AppFeatures.accessControl = $enabled',
            style: context.textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}

/// What this account actually holds, straight from the store every gate reads.
class _AbilitiesCard extends StatelessWidget {
  const _AbilitiesCard({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final store = getIt<AbilitiesStore>();

    return StreamBuilder<AbilitySet>(
      stream: store.stream,
      initialData: store.abilities,
      builder: (context, snapshot) {
        final abilities = snapshot.data ?? AbilitySet.none;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.accessMyPermissions.tr(
                  args: ['${abilities.permissions.length}'],
                ),
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  // `enforced` is the server's own flag. Shown because a
                  // deployment mid-rollout answers `false`, every gate stays
                  // open, and without this the screen would look broken.
                  ChipWidget(labelKey: 'enforced: ${abilities.enforced}'),
                  ChipWidget(labelKey: 'super admin: ${abilities.isSuperAdmin}'),
                  ChipWidget(labelKey: 'version: ${abilities.version}'),
                ],
              ),
              if (abilities.permissions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  (abilities.permissions.toList()..sort()).join('\n'),
                  style: context.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              AppButton(
                text: LocaleKeys.accessRefreshAbilities.tr(),
                variant: AppButtonVariant.tonal,
                onTap: () async {
                  await AccessControlPlugin.refresh(getIt);
                  onRefresh();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The interactive control the mirror rule asks for.
///
/// Type any key and watch the same `Can` widget open and close, in both modes.
/// Typing a key nothing declares is the other half of the demo: in a debug
/// build it produces the loud warning that makes a typo impossible to miss.
class _GatePlayground extends StatelessWidget {
  const _GatePlayground({
    required this.controller,
    required this.mode,
    required this.onModeChanged,
  });

  final TextEditingController controller;
  final CanMode mode;
  final ValueChanged<CanMode> onModeChanged;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: LocaleKeys.accessTryKeyLabel.tr(),
            helperText: LocaleKeys.accessUnknownKeyHint.tr(),
            helperMaxLines: 2,
          ),
          onChanged: (_) => onModeChanged(mode),
        ),
        const SizedBox(height: 12),
        SegmentedButton<CanMode>(
          segments: [
            ButtonSegment(
              value: CanMode.hide,
              label: Text(LocaleKeys.accessModeHide.tr()),
            ),
            ButtonSegment(
              value: CanMode.disable,
              label: Text(LocaleKeys.accessModeDisable.tr()),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) => onModeChanged(selection.first),
        ),
        const SizedBox(height: 16),
        // The live gate. Nothing about it is special to this screen — it is the
        // same widget a feature would write around a delete button.
        Can(
          permission: controller.text.trim(),
          mode: mode,
          fallback: Text(
            LocaleKeys.accessGateRefused.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.error,
            ),
          ),
          child: AppButton(
            text: LocaleKeys.accessGateAllowed.tr(),
            onTap: () {},
          ),
        ),
      ],
    ),
  );
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.catalog});

  final PermissionCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isAr;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.accessCatalogSummary.tr(
              args: ['${catalog.groups.length}'],
            ),
            style: context.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          // Read off the catalog — the resources, their labels, their action
          // counts. None of it is written in this file.
          for (final group in catalog.groups)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.label.resolve(isArabic ? 'ar' : 'en'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ChipWidget(labelKey: '${group.permissions.length}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
