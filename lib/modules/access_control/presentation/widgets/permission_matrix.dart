import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/access_control/domain/permission_catalog.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

/// **The screen the whole module exists to make possible.**
///
/// One card per resource, one row per action, drawn entirely from the catalog
/// the server sent. Read the build method and notice what is missing: any
/// mention of notes, roles, invoices, or any permission at all. A backend that
/// starts guarding a new resource tomorrow gets a labelled card here from a
/// build shipped today — the same property `modules/data_transfer/` has for
/// import and export.
///
/// Used twice: by the role editor (writable) and by the per-account screen
/// (read-only, showing what the roles resolved to).
class PermissionMatrix extends StatelessWidget {
  const PermissionMatrix({
    super.key,
    required this.catalog,
    required this.selected,
    this.onToggle,
    this.onToggleGroup,
    this.staleKeys = const {},
    this.readOnly = false,
  });

  final PermissionCatalog catalog;

  /// The keys currently held — **as stored**, so a wildcard stays a wildcard.
  final Set<String> selected;

  final void Function(String key)? onToggle;
  final void Function(PermissionGroup group, bool select)? onToggleGroup;

  /// Stored grants this server no longer declares. Shown rather than hidden —
  /// a screen that quietly dropped them would show a role different from the
  /// one in the database.
  final Set<String> staleKeys;

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final language = context.locale.languageCode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        if (!catalog.enforced)
          _Notice(message: LocaleKeys.accessNotEnforced.tr()),
        ...catalog.groups.map(
          (group) => _GroupCard(
            group: group,
            language: language,
            selected: selected,
            staleKeys: staleKeys,
            readOnly: readOnly,
            onToggle: onToggle,
            onToggleGroup: onToggleGroup,
          ),
        ),
        // Stale grants belong to no group — their resource no longer exists —
        // so they would be invisible without a section of their own.
        if (staleKeys.isNotEmpty) _StaleCard(keys: staleKeys),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.language,
    required this.selected,
    required this.staleKeys,
    required this.readOnly,
    this.onToggle,
    this.onToggleGroup,
  });

  final PermissionGroup group;
  final String language;
  final Set<String> selected;
  final Set<String> staleKeys;
  final bool readOnly;
  final void Function(String key)? onToggle;
  final void Function(PermissionGroup group, bool select)? onToggleGroup;

  @override
  Widget build(BuildContext context) {
    final real = group.permissions.where((p) => !p.synthetic).toList();
    final allSelected = real.isNotEmpty && real.every((p) => selected.contains(p.key));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              group.label.resolve(language),
              style: context.textTheme.titleMedium,
            ),
            subtitle: group.labelInferred
                // The server had no label and humanized the key. Said out loud
                // rather than hidden: an English word in an Arabic screen is a
                // visible prompt to add the real one.
                ? Text(
                    group.resource,
                    style: context.textTheme.bodySmall,
                  )
                : null,
            trailing: readOnly
                ? null
                : TextButton(
                    onPressed: () => onToggleGroup?.call(group, !allSelected),
                    child: Text(
                      allSelected
                          ? LocaleKeys.permissionClearAll.tr()
                          : LocaleKeys.permissionSelectAll.tr(),
                    ),
                  ),
          ),
          const Divider(height: 1),
          ...group.permissions.map(
            (permission) => _PermissionTile(
              permission: permission,
              language: language,
              value: selected.contains(permission.key),
              readOnly: readOnly,
              onChanged: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.permission,
    required this.language,
    required this.value,
    required this.readOnly,
    this.onChanged,
  });

  final PermissionDescriptor permission;
  final String language;
  final bool value;
  final bool readOnly;
  final void Function(String key)? onChanged;

  @override
  Widget build(BuildContext context) {
    // The consequence of the tick, shown **before** it is saved rather than
    // discovered afterwards. Granting "edit" without this looks like it grants
    // only editing, and the server will also grant viewing.
    final subtitle = permission.synthetic
        ? LocaleKeys.permissionManageHint.tr()
        : permission.implies.isEmpty
        ? null
        : LocaleKeys.permissionImplies.tr(args: [permission.implies.join('، ')]);

    return CheckboxListTile(
      dense: true,
      value: value,
      onChanged: readOnly ? null : (_) => onChanged?.call(permission.key),
      title: Row(
        children: [
          Expanded(child: Text(permission.label.resolve(language))),
          if (permission.synthetic)
            Icon(Icons.all_inclusive, size: 16, color: context.colors.primary),
        ],
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: context.textTheme.bodySmall),
    );
  }
}

class _StaleCard extends StatelessWidget {
  const _StaleCard({required this.keys});

  final Set<String> keys;

  @override
  Widget build(BuildContext context) => Card(
    color: context.colors.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.roleStaleGrants.tr(args: ['${keys.length}']),
            style: context.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          // The keys verbatim: whoever cleans these up needs the exact string
          // that is in the database, not a friendly name nothing can be looked
          // up by.
          Text(keys.join('\n'), style: context.textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    color: context.colors.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: context.textTheme.bodySmall)),
        ],
      ),
    ),
  );
}
