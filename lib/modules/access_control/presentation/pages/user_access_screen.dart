import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/access_control/domain/permission_catalog.dart';
import 'package:app_template/modules/access_control/domain/role.dart';
import 'package:app_template/modules/access_control/presentation/cubits/user_access_cubit.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// One account's access: which roles it holds, and the exceptions on top.
///
/// The exceptions are why this screen exists. Without them, "Sara also approves
/// invoices" is modelled by inventing a role with one member, and a deployment
/// ends up with forty roles nobody can describe.
///
/// It shows the **resolved** set alongside the choices, because the server
/// closes denies upward (`inference.ts` rule 4): denying a view also removes
/// the actions that needed it, and an administrator who cannot see that
/// happening will not understand what they just did.
@RoutePage()
class UserAccessScreen extends StatelessWidget {
  const UserAccessScreen({required this.userId, super.key});

  final int userId;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return BlocProvider(
      create: (_) => getIt<UserAccessCubit>()..load(userId),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(LocaleKeys.userAccessTitle.tr())),
          body: BlocConsumer<UserAccessCubit, UserAccessState>(
            listener: (context, state) {
              if (state is UserAccessActionFailed) {
                context.feedback.error(state.message);
              }
            },
            builder: (context, state) => switch (state) {
              UserAccessInitial() || UserAccessLoading() => const LoadingWidget(),
              UserAccessFailed(:final message) => ErrorStateWidget(
                messageKey: message,
                onRetry: () => context.read<UserAccessCubit>().load(userId),
              ),
              UserAccessReady() => _Body(state: state, busy: false),
              UserAccessSaving(:final ready) => _Body(state: ready, busy: true),
              UserAccessActionFailed(:final ready) =>
                _Body(state: ready, busy: false),
            },
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.busy});

  final UserAccessReady state;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final language = context.locale.languageCode;
    final access = state.access;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        if (access.isSuperAdmin)
          Card(
            color: context.colors.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.verified_user),
              title: Text(LocaleKeys.superAdminBadge.tr()),
            ),
          ),

        _SectionTitle(text: LocaleKeys.userAccessRoles.tr()),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: state.allRoles.map((role) {
            final held = access.roles.any((r) => r.id == role.id);
            return FilterChip(
              label: Text(role.name.resolve(language)),
              selected: held,
              onSelected: busy
                  ? null
                  : (_) => context.read<UserAccessCubit>().toggleRole(role),
            );
          }).toList(),
        ),

        _SectionTitle(text: LocaleKeys.userAccessOverrides.tr()),
        Text(
          LocaleKeys.userAccessOverridesHint.tr(),
          style: context.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        ...state.catalog.groups.map(
          (group) => _OverrideGroup(
            group: group,
            language: language,
            access: access,
            busy: busy,
          ),
        ),

        _SectionTitle(
          text: LocaleKeys.userAccessEffective.tr(
            args: ['${access.effectivePermissions.length}'],
          ),
        ),
        // The keys verbatim. This is the answer the server will actually give,
        // and a friendly rendering of it would hide the very case the section
        // exists for: a permission that vanished because a deny closed upward.
        Text(
          (access.effectivePermissions.toList()..sort()).join('\n'),
          style: context.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _OverrideGroup extends StatelessWidget {
  const _OverrideGroup({
    required this.group,
    required this.language,
    required this.access,
    required this.busy,
  });

  final PermissionGroup group;
  final String language;
  final UserAccess access;
  final bool busy;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(
            group.label.resolve(language),
            style: context.textTheme.titleSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Divider(height: 1),
        // The synthetic `manage` key is not offered here: an override is an
        // exception on one permission, and "everything, including what is added
        // later" is a role's job, not an exception's.
        ...group.permissions.where((p) => !p.synthetic).map((permission) {
          final effect = access.effectFor(permission.key);
          final effective = access.effectivePermissions.contains(permission.key);

          return ListTile(
            dense: true,
            onTap: busy
                ? null
                : () => context.read<UserAccessCubit>().cycleOverride(
                    permission.key,
                  ),
            title: Text(
              permission.label.resolve(language),
              overflow: TextOverflow.ellipsis,
            ),
            leading: Icon(
              effective ? Icons.check_circle : Icons.remove_circle_outline,
              size: 18,
              color: effective ? context.colors.primary : context.colors.error,
            ),
            trailing: _EffectChip(effect: effect),
          );
        }),
      ],
    ),
  );
}

class _EffectChip extends StatelessWidget {
  const _EffectChip({this.effect});

  final OverrideEffect? effect;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (effect) {
      null => (LocaleKeys.overrideInherit.tr(), context.colors.secondaryContainer),
      OverrideEffect.allow => (
        LocaleKeys.overrideAllow.tr(),
        context.colors.primaryContainer,
      ),
      OverrideEffect.deny => (
        LocaleKeys.overrideDeny.tr(),
        context.colors.errorContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: context.textTheme.labelSmall),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: context.textTheme.titleMedium),
  );
}
