import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/feedback.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Drag to reorder and swipe to act — [AppReorderableList], [AppSwipeActions]
/// and [SwipeAction] as playgrounds over a live list.
class GesturesDemo extends StatelessWidget {
  const GesturesDemo({super.key});

  static const _icons = {
    'Icons.delete_outline_rounded': Icons.delete_outline_rounded,
    'Icons.archive_outlined': Icons.archive_outlined,
    'Icons.done_rounded': Icons.done_rounded,
    'Icons.push_pin_outlined': Icons.push_pin_outlined,
  };

  static const _archive = 'archive';
  static const _delete = 'delete';

  static const _presets = {
    'null': null,
    'SwipeAction(icon: Icons.archive_outlined, tone: StatusTone.info, …)':
        _archive,
    'SwipeAction(icon: Icons.delete_outline_rounded, confirm: …, …)': _delete,
  };

  static _Spec? _preset(String? id) => switch (id) {
    _archive => _Spec(
      icon: Icons.archive_outlined,
      label: LocaleKeys.showcaseGesturesArchive.tr(),
      tone: StatusTone.info,
      confirm: false,
    ),
    _delete => _Spec(
      icon: Icons.delete_outline_rounded,
      label: LocaleKeys.delete.tr(),
      tone: StatusTone.error,
      confirm: true,
    ),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoPlayground(
          call: 'AppReorderableList<Item>',
          knobs: [
            ChoiceKnob<int>('items', const {
              'List.generate(3, …)': 3,
              'List.generate(5, …)': 5,
              'List.generate(8, …)': 8,
            }, initialCode: 'List.generate(5, …)'),
            const BoolKnob('handle', initial: true),
          ],
          trailingCode: const [
            'itemKey: (item) => item.id',
            'itemBuilder: (context, item, index) => AppListTile(…)',
            'onReorder: (from, to) => setState(() => items.insert(to, items.removeAt(from)))',
            'shrinkWrap: true',
            'physics: const NeverScrollableScrollPhysics()',
          ],
          previewAlignment: Alignment.topCenter,
          builder: (context, k) =>
              _ReorderPreview(count: k('items'), handle: k('handle')),
        ),
        DemoPlayground(
          call: 'AppSwipeActions',
          knobs: [
            ChoiceKnob<String?>(
              'startAction',
              _presets,
              initialCode: _presets.keys.elementAt(1),
              apiDefaultCode: 'null',
            ),
            ChoiceKnob<String?>(
              'endAction',
              _presets,
              initialCode: _presets.keys.elementAt(2),
              apiDefaultCode: 'null',
            ),
          ],
          trailingCode: const ['id: item.id', 'child: AppListTile(…)'],
          previewAlignment: Alignment.topCenter,
          builder: (context, k) => _SwipePreview(
            start: _preset(k('startAction')),
            end: _preset(k('endAction')),
          ),
        ),
        DemoPlayground(
          call: 'SwipeAction',
          knobs: [
            ChoiceKnob<IconData>('icon', _icons, required: true),
            TextKnob('label', initial: LocaleKeys.delete.tr(), required: true),
            EnumKnob(
              'tone',
              StatusTone.values,
              StatusTone.error,
              apiDefault: StatusTone.error,
            ),
            ChoiceKnob<bool>('confirm', const {
              'null': false,
              '() => AppConfirmDialog.show(context, …)': true,
            }, apiDefaultCode: 'null'),
          ],
          trailingCode: const ['onTriggered: () => remove(item)'],
          previewAlignment: Alignment.topCenter,
          builder: (context, k) => _SwipePreview(
            end: _Spec(
              icon: k('icon'),
              label: k('label'),
              tone: k('tone'),
              confirm: k('confirm'),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reorder ─────────────────────────────────────────────────────────────────

class _ReorderPreview extends StatefulWidget {
  const _ReorderPreview({required this.count, required this.handle});

  final int count;
  final bool handle;

  @override
  State<_ReorderPreview> createState() => _ReorderPreviewState();
}

class _ReorderPreviewState extends State<_ReorderPreview> {
  late List<int> _items = _fresh();

  List<int> _fresh() => List.generate(widget.count, (i) => i + 1);

  @override
  void didUpdateWidget(_ReorderPreview old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) _items = _fresh();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final muted = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textMuted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.handle
              ? LocaleKeys.showcaseGesturesHintHandle.tr()
              : LocaleKeys.showcaseGesturesHintLongPress.tr(),
          style: muted,
        ),
        const ResponsiveGap(8),
        AppReorderableList<int>(
          items: _items,
          itemKey: (n) => n,
          handle: widget.handle,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, n, index) => AppListTile(
            titleText: LocaleKeys.showcaseItem.tr(args: ['$n']),
            leadingIcon: Icons.label_outline_rounded,
          ),
          onReorder: (from, to) =>
              setState(() => _items.insert(to, _items.removeAt(from))),
        ),
        const ResponsiveGap(8),
        Text(
          LocaleKeys.showcaseGesturesOrder.tr(args: [_items.join(' · ')]),
          style: muted,
        ),
      ],
    );
  }
}

// ── Swipe ───────────────────────────────────────────────────────────────────

/// One side's action as the playground chose it.
class _Spec {
  const _Spec({
    required this.icon,
    required this.label,
    required this.tone,
    required this.confirm,
  });

  final IconData icon;
  final String label;
  final StatusTone tone;
  final bool confirm;
}

/// A few rows that really go: swiped out, then back with undo — from a
/// snackbar action when feedback is registered, from a line here otherwise.
class _SwipePreview extends StatefulWidget {
  const _SwipePreview({this.start, this.end});

  final _Spec? start;
  final _Spec? end;

  @override
  State<_SwipePreview> createState() => _SwipePreviewState();
}

class _SwipePreviewState extends State<_SwipePreview> {
  static const _count = 4;

  List<int> _items = List.generate(_count, (i) => i + 1);

  /// The last row removed and where it stood — what undo puts back.
  ({int item, int index, String message})? _removed;

  String _name(int n) => LocaleKeys.showcaseItem.tr(args: ['$n']);

  void _remove(int n, _Spec spec) {
    final index = _items.indexOf(n);
    final message = LocaleKeys.showcaseGesturesDone.tr(
      args: [spec.label, _name(n)],
    );
    setState(() {
      _items.removeAt(index);
      _removed = (item: n, index: index, message: message);
    });
    if (getIt.isRegistered<AppFeedbackService>()) {
      context.feedback.show(
        FeedbackConfig(
          type: FeedbackType.info,
          message: message,
          action: FeedbackAction(
            label: LocaleKeys.showcaseGesturesUndo.tr(),
            onTap: _undo,
          ),
        ),
      );
    }
  }

  void _undo() {
    final removed = _removed;
    if (removed == null || !mounted) return;
    setState(() {
      _items.insert(removed.index.clamp(0, _items.length), removed.item);
      _removed = null;
    });
  }

  void _reset() => setState(() {
    _items = List.generate(_count, (i) => i + 1);
    _removed = null;
  });

  SwipeAction? _action(_Spec? spec, int n) => spec == null
      ? null
      : SwipeAction(
          icon: spec.icon,
          label: spec.label,
          tone: spec.tone,
          confirm: spec.confirm
              ? () => AppConfirmDialog.show(
                  context,
                  titleKey: LocaleKeys.deleteConfirmTitle,
                  messageKey: LocaleKeys.deleteConfirmMessage,
                  isDestructive: spec.tone == StatusTone.error,
                )
              : null,
          onTriggered: () => _remove(n, spec),
        );

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final muted = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textMuted,
    );
    final inlineUndo = !getIt.isRegistered<AppFeedbackService>();
    final removed = _removed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(LocaleKeys.showcaseGesturesSwipeHint.tr(), style: muted),
        const ResponsiveGap(8),
        for (final n in _items)
          AppSwipeActions(
            key: ValueKey(n),
            id: n,
            startAction: _action(widget.start, n),
            endAction: _action(widget.end, n),
            child: AppListTile(
              titleText: _name(n),
              leadingIcon: Icons.mail_outline_rounded,
            ),
          ),
        if (_items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.screen.space(16)),
            child: Text(
              LocaleKeys.noDataFound.tr(),
              textAlign: TextAlign.center,
              style: muted,
            ),
          ),
        const ResponsiveGap(8),
        Row(
          children: [
            Expanded(
              child: inlineUndo && removed != null
                  ? Text(removed.message, style: muted)
                  : const SizedBox.shrink(),
            ),
            if (inlineUndo && removed != null)
              AppButton(
                text: LocaleKeys.showcaseGesturesUndo.tr(),
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
                onTap: _undo,
              ),
            if (_items.length < _count)
              AppButton(
                text: LocaleKeys.reset.tr(),
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
                onTap: _reset,
              ),
          ],
        ),
      ],
    );
  }
}
