import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/access_control/domain/role.dart';
import 'package:app_template/modules/access_control/presentation/cubits/roles_cubit.dart';
import 'package:app_template/modules/access_control/presentation/pages/role_editor_screen.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// Role administration — **the whole of it, for every application built on this
/// template.**
///
/// Nothing here names a permission or a feature. The roles come from the
/// server, their permissions are rendered against the catalog the server
/// declares, and a project that adds twenty guarded endpoints tomorrow manages
/// them from this exact screen without a line of Dart changing.
@RoutePage()
class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return BlocProvider(
      create: (_) => getIt<RolesCubit>()..load(),
      child: Builder(
        // Below the provider, so `context.read<RolesCubit>()` resolves. The
        // tempting `getIt<RolesCubit>()` instead would not throw and would be
        // wrong: the cubit is a factory, so it builds a second, empty instance.
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(LocaleKeys.rolesTitle.tr())),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createRole(context),
            icon: const Icon(Icons.add),
            label: Text(LocaleKeys.roleCreate.tr()),
          ),
          body: BlocConsumer<RolesCubit, RolesState>(
            listener: (context, state) {
              // A refused write is a toast over the list, not a replacement for
              // it: nothing the user was looking at became invalid.
              if (state is RolesActionFailed) {
                context.feedback.error(state.message);
              }
            },
            builder: (context, state) => switch (state) {
              RolesInitial() || RolesLoading() => const LoadingWidget(),
              RolesFailed(:final message) => ErrorStateWidget(
                // Receives an already-translated string; `.tr()` on a value
                // that is not a key returns it unchanged, which is what makes
                // this compatible with the widget's key-based API.
                messageKey: message,
                onRetry: () => context.read<RolesCubit>().load(),
              ),
              RolesReady() => _RolesList(state: state),
              RolesActionFailed(:final ready) => _RolesList(state: ready),
            },
          ),
        ),
      ),
    );
  }

  Future<void> _createRole(BuildContext context) async {
    final cubit = context.read<RolesCubit>();
    final draft = await showDialog<_RoleDraft>(
      context: context,
      builder: (_) => const _CreateRoleDialog(),
    );
    if (draft == null) return;

    await cubit.create(
      key: draft.key,
      nameAr: draft.nameAr,
      nameEn: draft.nameEn,
    );
  }
}

class _RolesList extends StatelessWidget {
  const _RolesList({required this.state});

  final RolesReady state;

  @override
  Widget build(BuildContext context) {
    if (state.roles.isEmpty) {
      return EmptyStateWidget(titleKey: LocaleKeys.rolesEmpty.tr());
    }

    return RefreshIndicator(
      onRefresh: () => context.read<RolesCubit>().refreshRoles(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
        itemCount: state.roles.length,
        itemBuilder: (context, index) {
          final role = state.roles[index];
          return _RoleCard(
            role: role,
            busy: state.busyRoleId == role.id,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RoleEditorScreen(
                  role: role,
                  catalog: state.catalog,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.busy,
    required this.onOpen,
  });

  final Role role;
  final bool busy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final language = context.locale.languageCode;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        // A system role opens read-only rather than not opening: seeing what
        // `super_admin` grants is exactly what an administrator needs, and
        // refusing to show it would make the most powerful role the least
        // legible.
        onTap: busy ? null : onOpen,
        title: Row(
          children: [
            Flexible(child: Text(role.name.resolve(language))),
            if (role.isSystem) _Badge(text: LocaleKeys.roleSystemBadge.tr()),
            if (!role.isActive)
              _Badge(
                text: LocaleKeys.roleInactiveBadge.tr(),
                color: context.colors.errorContainer,
              ),
          ],
        ),
        subtitle: Text(
          '${LocaleKeys.rolePermissionsCount.tr(args: ['${role.permissions.length}'])}'
          ' · '
          '${LocaleKeys.roleMembers.tr(args: ['${role.usersCount}'])}'
          '${role.hasStaleGrants ? ' · ⚠️ ${LocaleKeys.roleStaleGrants.tr(args: ['${role.stalePermissions.length}'])}' : ''}',
          style: context.textTheme.bodySmall,
        ),
        trailing: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : role.isSystem
            // No deactivate control at all: the server refuses it, and a button
            // that exists only to produce an error is worse than no button.
            ? null
            : IconButton(
                tooltip: role.isActive
                    ? LocaleKeys.roleDeactivate.tr()
                    : LocaleKeys.roleActivate.tr(),
                icon: Icon(
                  role.isActive ? Icons.block : Icons.restore,
                ),
                onPressed: () => context.read<RolesCubit>().setActive(
                  role,
                  isActive: !role.isActive,
                ),
              ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? context.colors.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: context.textTheme.labelSmall),
    ),
  );
}

class _RoleDraft {
  const _RoleDraft({
    required this.key,
    required this.nameAr,
    required this.nameEn,
  });

  final String key;
  final String nameAr;
  final String nameEn;
}

class _CreateRoleDialog extends StatefulWidget {
  const _CreateRoleDialog();

  @override
  State<_CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<_CreateRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _key = TextEditingController();
  final _nameAr = TextEditingController();
  final _nameEn = TextEditingController();

  @override
  void dispose() {
    _key.dispose();
    _nameAr.dispose();
    _nameEn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(LocaleKeys.roleCreate.tr()),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _key,
            decoration: InputDecoration(
              labelText: LocaleKeys.roleKeyLabel.tr(),
              helperText: LocaleKeys.roleKeyHint.tr(),
              helperMaxLines: 2,
            ),
            // Mirrors the server's `roleKeySchema`. Checked here as well so the
            // refusal arrives while the field is still focused, rather than as
            // a 422 after the dialog closes.
            validator: (value) =>
                RegExp(r'^[a-z][a-z0-9_]{1,63}$').hasMatch(value?.trim() ?? '')
                ? null
                : LocaleKeys.roleKeyHint.tr(),
          ),
          TextFormField(
            controller: _nameAr,
            decoration: InputDecoration(labelText: LocaleKeys.roleNameArLabel.tr()),
            validator: _required,
          ),
          TextFormField(
            controller: _nameEn,
            decoration: InputDecoration(labelText: LocaleKeys.roleNameEnLabel.tr()),
            validator: _required,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(LocaleKeys.cancel.tr()),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState?.validate() != true) return;
          Navigator.of(context).pop(
            _RoleDraft(
              key: _key.text.trim(),
              nameAr: _nameAr.text.trim(),
              nameEn: _nameEn.text.trim(),
            ),
          );
        },
        child: Text(LocaleKeys.save.tr()),
      ),
    ],
  );

  String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? LocaleKeys.fieldRequired.tr() : null;
}
