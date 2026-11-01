import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/modules/sim_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/resources/permission_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `modules/access_control/` played on the device: pick a role, and the
/// actions it may not perform hide or dim — exactly what `Can` does, gated
/// here from a local set because the real one reads the signed-in account.
class AccessSimDemo extends StatefulWidget {
  const AccessSimDemo({super.key});

  @override
  State<AccessSimDemo> createState() => _AccessSimDemoState();
}

enum _Role { viewer, editor, admin }

class _AccessSimDemoState extends State<AccessSimDemo> {
  /// The keys are the generated [PermKeys] — the same constants real code
  /// passes to `Can`.
  static const _grants = {
    _Role.viewer: {PermKeys.notesView},
    _Role.editor: {
      PermKeys.notesView,
      PermKeys.notesCreate,
      PermKeys.notesUpdate,
    },
    _Role.admin: {
      PermKeys.notesView,
      PermKeys.notesCreate,
      PermKeys.notesUpdate,
      PermKeys.notesDelete,
    },
  };

  static const _keys = [
    PermKeys.notesView,
    PermKeys.notesCreate,
    PermKeys.notesUpdate,
    PermKeys.notesDelete,
  ];

  _Role _role = _Role.editor;
  bool _disable = false;

  String _roleLabel(_Role r) => switch (r) {
    _Role.viewer => LocaleKeys.showcaseAccessRoleViewer.tr(),
    _Role.editor => LocaleKeys.showcaseAccessRoleEditor.tr(),
    _Role.admin => LocaleKeys.showcaseAccessRoleAdmin.tr(),
  };

  bool _can(String key) => _grants[_role]!.contains(key);

  static void _noop() {}

  /// What `Can` renders for one control: the child, nothing, or the child
  /// dimmed and inert.
  Widget _gate(String key, Widget child) {
    if (_can(key)) return child;
    if (!_disable) return const SizedBox.shrink();
    return Opacity(opacity: 0.4, child: IgnorePointer(child: child));
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    final motion = AppMotion.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SimNotice(),
        DemoBlock(
          code: 'Can(permission: PermKeys.notesDelete, child: …)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChipRow<_Role>(
                items: _Role.values,
                labelResolver: _roleLabel,
                selectedValue: _role,
                onSelected: (r) => setState(() => _role = r ?? _role),
              ),
              8.heightBox,
              ChipRow<bool>(
                items: const [false, true],
                labelResolver: (d) => d ? 'CanMode.disable' : 'CanMode.hide',
                selectedValue: _disable,
                onSelected: (d) => setState(() => _disable = d ?? _disable),
                scrollable: false,
              ),
              16.heightBox,
              AnimatedSize(
                duration: motion.base,
                alignment: AlignmentDirectional.topStart,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _gate(
                      PermKeys.notesView,
                      AppButton(
                        text: LocaleKeys.showcaseAccessView.tr(),
                        variant: AppButtonVariant.outlined,
                        leadingIcon: Icons.visibility_outlined,
                        onTap: _noop,
                      ),
                    ),
                    _gate(
                      PermKeys.notesCreate,
                      AppButton(
                        text: LocaleKeys.showcaseAdd.tr(),
                        leadingIcon: Icons.add,
                        onTap: _noop,
                      ),
                    ),
                    _gate(
                      PermKeys.notesUpdate,
                      AppButton(
                        text: LocaleKeys.edit.tr(),
                        variant: AppButtonVariant.tonal,
                        leadingIcon: Icons.edit_outlined,
                        onTap: _noop,
                      ),
                    ),
                    _gate(
                      PermKeys.notesDelete,
                      AppButton(
                        text: LocaleKeys.delete.tr(),
                        variant: AppButtonVariant.danger,
                        leadingIcon: Icons.delete_outline,
                        onTap: _noop,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'context.can(PermKeys.…) · context.abilities',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final key in _keys)
                AppListTile(
                  titleText: key,
                  leadingIcon: _can(key)
                      ? Icons.check_circle_outline
                      : Icons.block_outlined,
                  trailing: StatusChip(
                    labelText: _can(key)
                        ? LocaleKeys.showcaseAccessAllowed.tr()
                        : LocaleKeys.showcaseAccessDenied.tr(),
                    tone: _can(key) ? StatusTone.success : StatusTone.neutral,
                  ),
                  dense: true,
                  showDivider: key != _keys.last,
                ),
            ],
          ),
        ),
        DemoBlock(
          code: "requirePermission('notes.delete') — backend",
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: colors.statusWarningFg),
              8.widthBox,
              Expanded(
                child: Text(
                  LocaleKeys.showcaseAccessNotSecurity.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.statusWarningFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
