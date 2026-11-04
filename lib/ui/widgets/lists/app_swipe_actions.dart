import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/misc/status_chip.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// إجراءٌ يكشفه سحبُ الصفّ — حذف · أرشفة · إخفاء.
class SwipeAction {
  const SwipeAction({
    required this.icon,
    required this.label,
    required this.onTriggered,
    this.tone = StatusTone.error,
    this.confirm,
  });

  final IconData icon;

  /// نصٌّ مترجَم — يظهر بجانب الأيقونة، ويقرؤه قارئ الشاشة اسماً للإجراء.
  final String label;

  /// لونُ الخلفية المكشوفة — بنفس ألوان `StatusChip`.
  final StatusTone tone;

  /// يُنادى بعد خروج الصفّ. **وعليه أن يحذف العنصر من القائمة بنفس الإطار** —
  /// `Dismissible` المسحوب لا يبقى بالشجرة.
  final VoidCallback onTriggered;

  /// سؤالٌ قبل التنفيذ (`AppConfirmDialog.show`) — `false` يُعيد الصفّ مكانه
  /// ولا يُنادي [onTriggered]. `null` ⇐ تنفيذٌ مباشر.
  final Future<bool> Function()? confirm;
}

/// **صفٌّ يُسحب جانباً لينفّذ إجراءً** — غلافُ `Dismissible`.
///
/// ```dart
/// AppSwipeActions(
///   id: note.id,
///   endAction: SwipeAction(
///     icon: Icons.delete_outline_rounded,
///     label: LocaleKeys.delete.tr(),
///     onTriggered: () => cubit.remove(note),
///   ),
///   child: AppListTile(titleText: note.title),
/// )
/// ```
///
/// - **الاتجاه بالبداية والنهاية لا باليسار واليمين**: [startAction] يُكشف
///   بجانب بداية السطر (يمينٌ بالعربية)، و[endAction] بنهايته.
/// - **الخلفية** بلون [SwipeAction.tone] من الثيم، وفيها الأيقونة والنصّ.
/// - **قارئ الشاشة** لا يسحب — فكلُّ إجراءٍ إجراءٌ مسمّى بالصفّ نفسه، يمرّ بنفس
///   [SwipeAction.confirm].
/// - **التراجع** مسؤوليةُ المستدعي: يحذف العنصر بـ[SwipeAction.onTriggered]
///   ويعرض رسالةً بزرّ «تراجع» يعيده لموضعه (راجع §40 بدليل الودجات).
class AppSwipeActions extends StatelessWidget {
  const AppSwipeActions({
    required this.id,
    required this.child,
    this.startAction,
    this.endAction,
    super.key,
  });

  /// هويّةُ العنصر الثابتة — بها يُعرف الصفّ وهو ينزلق خارجاً.
  final Object id;

  final Widget child;

  /// يُكشف بسحب الصفّ من بداية السطر نحو نهايته.
  final SwipeAction? startAction;

  /// يُكشف بسحب الصفّ من نهاية السطر نحو بدايته.
  final SwipeAction? endAction;

  SwipeAction? _actionFor(DismissDirection direction) => switch (direction) {
    DismissDirection.startToEnd => startAction,
    DismissDirection.endToStart => endAction,
    _ => null,
  };

  Future<void> _triggerFromSemantics(SwipeAction action) async {
    if (await action.confirm?.call() ?? true) action.onTriggered();
  }

  @override
  Widget build(BuildContext context) {
    final start = startAction;
    final end = endAction;
    if (start == null && end == null) return child;

    final motion = AppMotion.of(context);
    final direction = start != null && end != null
        ? DismissDirection.horizontal
        : start != null
        ? DismissDirection.startToEnd
        : DismissDirection.endToStart;

    return Semantics(
      customSemanticsActions: {
        for (final action in [?start, ?end])
          CustomSemanticsAction(label: action.label): () =>
              _triggerFromSemantics(action),
      },
      child: Dismissible(
        key: ValueKey<Object>(id),
        direction: direction,
        movementDuration: motion.base,
        resizeDuration: motion.base,
        // Dismissible يرسم [background] لسحب البداية، و[secondaryBackground]
        // للنهاية — وإن غاب الأول فالثاني يُرسم بمكانه.
        background: start != null
            ? _SwipeBackground(action: start, atStart: true)
            : _SwipeBackground(action: end!, atStart: false),
        secondaryBackground: start != null && end != null
            ? _SwipeBackground(action: end, atStart: false)
            : null,
        confirmDismiss: (direction) async =>
            await _actionFor(direction)?.confirm?.call() ?? true,
        onDismissed: (direction) => _actionFor(direction)?.onTriggered(),
        child: child,
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.action, required this.atStart});

  final SwipeAction action;
  final bool atStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (action.tone) {
      StatusTone.neutral => (colors.statusNeutralBg, colors.statusNeutralFg),
      StatusTone.info => (colors.statusInfoBg, colors.statusInfoFg),
      StatusTone.success => (colors.statusSuccessBg, colors.statusSuccessFg),
      StatusTone.warning => (colors.statusWarningBg, colors.statusWarningFg),
      StatusTone.error => (colors.statusErrorBg, colors.statusErrorFg),
    };
    return ColoredBox(
      color: background,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.screen.space(20)),
        child: Align(
          alignment: atStart
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, color: foreground, size: 22),
              SizedBox(width: context.screen.space(8)),
              Flexible(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
