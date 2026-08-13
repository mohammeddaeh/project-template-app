import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/access_control/domain/ability_set.dart';
import 'package:app_template/modules/access_control/integration/abilities_store.dart';

/// **The whole developer-facing surface of this module.**
///
/// ```dart
/// Can(
///   key: 'notes.delete',
///   child: IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
/// )
/// ```
///
/// One line per control. No list to maintain, no enum to regenerate: the key is
/// a string because the set of permissions lives on the server, and a typed
/// enum would have to be rebuilt every time a feature was guarded — exactly the
/// coupling this module exists to remove.
///
/// The typo that a plain string invites is caught instead: in debug builds the
/// module holds every key the server declares and **shouts** when a gate names
/// one that does not exist. See [AbilitiesStore.debugWarnIfUnknown].
///
/// ## ⚠️ This is not security
///
/// It decides whether a control is *drawn*. The server's `requirePermission`
/// decides whether the action *happens*, and it is the only thing that does. A
/// screen guarded here whose endpoint is unguarded there is not protected — see
/// `readme/permissions.md`.
///
/// ## Hide or disable
///
/// Hidden by default: an action the user can never perform is noise, and a
/// permanently greyed button invites the same question every time it is seen.
/// [CanMode.disable] is for the case where the control's *absence* would be
/// confusing — a step missing from a numbered sequence, a toolbar that changes
/// shape between accounts.
///
/// ## When the module is switched off
///
/// With `AppFeatures.accessControl == false` nothing is registered, and this
/// widget renders [child] unconditionally. An app built without access control
/// behaves exactly as it did before the module existed.
class Can extends StatelessWidget {
  const Can({
    super.key,
    required this.permission,
    required this.child,
    this.mode = CanMode.hide,
    this.fallback,
  }) : _anyOf = null;

  /// Passes when the account holds **any** of the keys — mirrors the server's
  /// `requireAnyPermission`.
  const Can.any({
    super.key,
    required List<String> permissions,
    required this.child,
    this.mode = CanMode.hide,
    this.fallback,
  }) : permission = null,
       _anyOf = permissions;

  /// The single key this control requires.
  final String? permission;

  final List<String>? _anyOf;

  final Widget child;
  final CanMode mode;

  /// Shown instead of [child] when the check fails and [mode] is
  /// [CanMode.hide]. Defaults to nothing at all.
  final Widget? fallback;

  List<String> get _keys => _anyOf ?? [permission!];

  @override
  Widget build(BuildContext context) {
    if (!_moduleActive) return child;

    final store = getIt<AbilitiesStore>();
    for (final key in _keys) {
      store.debugWarnIfUnknown(key);
    }

    // A stream, not a one-shot read: an administrator changing what this
    // account may do, a sign-out, or the first `/authz/me` landing must all
    // redraw the control rather than wait for the next unrelated rebuild.
    return StreamBuilder<AbilitySet>(
      stream: store.stream,
      initialData: store.abilities,
      builder: (context, snapshot) {
        final abilities = snapshot.data ?? AbilitySet.none;
        final allowed = abilities.canAny(_keys);

        if (allowed) return child;

        return switch (mode) {
          CanMode.hide => fallback ?? const SizedBox.shrink(),
          // Absorbs the pointer rather than relying on the child to disable
          // itself: the child is any widget, and a `Card` with an `onTap` has
          // no `onPressed` to null out.
          CanMode.disable => Opacity(
            opacity: 0.4,
            child: IgnorePointer(child: child),
          ),
        };
      },
    );
  }
}

enum CanMode {
  /// The control is not drawn. The default.
  hide,

  /// The control is drawn, dimmed and inert.
  disable,
}

/// Imperative checks — inside a callback, an `if`, a list filter.
///
/// ```dart
/// if (context.can('notes.delete')) _showDeleteAction();
/// ```
///
/// **Reads the current set synchronously and does not rebuild on its own.**
/// That is correct for a callback, which runs once at the moment of the tap.
/// Inside `build`, prefer [Can] — a value read here will not redraw when the
/// permission changes underneath it.
extension AbilityContext on BuildContext {
  bool can(String permission) {
    if (!_moduleActive) return true;
    final store = getIt<AbilitiesStore>();
    store.debugWarnIfUnknown(permission);
    return store.abilities.can(permission);
  }

  bool canAny(List<String> permissions) {
    if (!_moduleActive) return true;
    final store = getIt<AbilitiesStore>();
    for (final key in permissions) {
      store.debugWarnIfUnknown(key);
    }
    return store.abilities.canAny(permissions);
  }

  /// The full set, for a screen that reasons about permissions rather than
  /// gating on one — the roles editor, a diagnostics view.
  AbilitySet get abilities =>
      _moduleActive ? getIt<AbilitiesStore>().abilities : AbilitySet.unrestricted;
}

/// True only when the module is both enabled and wired.
///
/// The `isRegistered` half is not defensive clutter: `AppFeatures.accessControl`
/// can be on while `ModulesBootstrap` has not run yet (a widget test, an
/// isolated screen preview), and a gate that throws in that window would make
/// the module impossible to test around.
bool get _moduleActive =>
    AppFeatures.accessControl && getIt.isRegistered<AbilitiesStore>();
