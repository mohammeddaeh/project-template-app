import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/access_control/domain/permission_catalog.dart';
import 'package:app_template/modules/access_control/domain/role.dart';
import 'package:app_template/modules/access_control/presentation/cubits/role_editor_cubit.dart';
import 'package:app_template/modules/access_control/presentation/widgets/permission_matrix.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

/// One role's permissions.
///
/// The screen is a [PermissionMatrix] and a save button. Everything it draws
/// comes from the catalog — so the day a project guards its fortieth endpoint,
/// this file is untouched and the fortieth checkbox is already there.
///
/// Not a `@RoutePage`: it is always reached from the list, which already holds
/// the role and the catalog. Making it a route would mean re-fetching both to
/// satisfy a deep link nobody sends.
class RoleEditorScreen extends StatelessWidget {
  const RoleEditorScreen({
    required this.role,
    required this.catalog,
    super.key,
  });

  final Role role;
  final PermissionCatalog catalog;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return BlocProvider(
      create: (_) =>
          getIt<RoleEditorCubit>()..start(role: role, catalog: catalog),
      child: Builder(
        builder: (context) => BlocConsumer<RoleEditorCubit, RoleEditorState>(
          listener: (context, state) {
            switch (state) {
              case RoleEditorSaved():
                context.feedback.success(LocaleKeys.roleSaved.tr());
                // `true` tells the list its data is stale — the permission
                // count on the card just changed.
                Navigator.of(context).pop(true);
              case RoleEditorFailed(:final message):
                context.feedback.error(message);
              default:
                break;
            }
          },
          builder: (context, state) {
            final ready = switch (state) {
              RoleEditorReady() => state,
              RoleEditorSaving(:final ready) => ready,
              RoleEditorFailed(:final ready) => ready,
              _ => null,
            };
            if (ready == null) return const SizedBox.shrink();

            final saving = state is RoleEditorSaving;

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  ready.role.name.resolve(context.locale.languageCode),
                  overflow: TextOverflow.ellipsis,
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(24),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      LocaleKeys.roleEditorTitle.tr(),
                      style: context.textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
              body: Column(
                children: [
                  if (ready.isReadOnly)
                    // Said plainly instead of leaving the reader to work out
                    // why every checkbox is inert.
                    Container(
                      width: double.infinity,
                      color: context.colors.secondaryContainer,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        LocaleKeys.roleEditorReadOnly.tr(),
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                  Expanded(
                    child: PermissionMatrix(
                      catalog: ready.catalog,
                      selected: ready.selected,
                      staleKeys: ready.role.stalePermissions.toSet(),
                      readOnly: ready.isReadOnly || saving,
                      onToggle: context.read<RoleEditorCubit>().toggle,
                      onToggleGroup: (group, select) => context
                          .read<RoleEditorCubit>()
                          .toggleGroup(group, select: select),
                    ),
                  ),
                ],
              ),
              floatingActionButton: ready.isReadOnly
                  ? null
                  : FloatingActionButton.extended(
                      // Disabled while unchanged: a save that writes the set
                      // already stored is a request whose only effect is to
                      // bump `updated_at`, invalidating every member's cached
                      // ability set for nothing.
                      onPressed: saving || ready.isUnchanged
                          ? null
                          : context.read<RoleEditorCubit>().save,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(LocaleKeys.save.tr()),
                    ),
            );
          },
        ),
      ),
    );
  }
}
