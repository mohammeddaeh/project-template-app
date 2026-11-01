import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/call_playground.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The confirm dialog, the bottom sheet and the filter sheet as playgrounds —
/// the controls configure the call, the button opens it with that
/// configuration, and the line under it reports what it returned.
class DialogsDemo extends StatefulWidget {
  const DialogsDemo({super.key});

  @override
  State<DialogsDemo> createState() => _DialogsDemoState();
}

enum _Status { draft, active, archived }

enum _Priority { high, low }

class _DialogsDemoState extends State<DialogsDemo> {
  String? _confirmResult;
  String? _sheetResult;
  String? _filterResult;

  // The filter sheet edits a copy; the page keeps what was applied and hands
  // it back on the next open.
  final Set<Object> _applied = {};
  SortOption<Object>? _sort;

  String _item(int n) => LocaleKeys.showcaseItem.tr(args: ['$n']);

  Future<void> _confirm(CallArgs a) async {
    final ok = await AppConfirmDialog.show(
      context,
      titleKey: a('titleKey'),
      messageKey: a('messageKey'),
      messageArgs: a('messageArgs'),
      confirmKey: a('confirmKey'),
      cancelKey: a('cancelKey'),
      isDestructive: a('isDestructive'),
      barrierDismissible: a('barrierDismissible'),
    );
    if (!mounted) return;
    setState(() => _confirmResult = '$ok');
  }

  Future<void> _sheet(CallArgs a) async {
    final String title = a('title');
    final int count = a('child');
    final picked = await AppBottomSheet.show<int>(
      context,
      title: title.isEmpty ? null : title,
      titleWidget: a('titleWidget'),
      isScrollable: a('isScrollable'),
      showDivider: a('showDivider'),
      maxHeightFraction: a('maxHeightFraction'),
      dismissOnTapOutside: a('dismissOnTapOutside'),
      child: Builder(
        builder: (sheet) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var n = 1; n <= count; n++)
              ListTile(
                title: Text(_item(n)),
                onTap: () => Navigator.of(sheet).pop(n),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(
      () => _sheetResult = picked == null
          ? LocaleKeys.showcaseDialogsDismissed.tr()
          : _item(picked),
    );
  }

  Future<void> _filters(CallArgs a) async {
    FilterOption<Object> option(Object v, String key) =>
        FilterOption(value: v, labelKey: key, isSelected: _applied.contains(v));

    await AppFilterSheet.show<Object>(
      context,
      filterGroups: [
        FilterGroup(
          titleKey: LocaleKeys.showcaseDialogsStatus,
          multiSelect: a('multiSelect'),
          options: [
            option(_Status.draft, LocaleKeys.showcaseDialogsDraft),
            option(_Status.active, LocaleKeys.active),
            option(_Status.archived, LocaleKeys.showcaseDialogsArchived),
          ],
        ),
        FilterGroup(
          titleKey: LocaleKeys.showcaseDialogsPriority,
          multiSelect: false,
          options: [
            option(_Priority.high, LocaleKeys.showcaseDialogsHigh),
            option(_Priority.low, LocaleKeys.showcaseDialogsLow),
          ],
        ),
      ],
      sortOptions: a<bool>('sortOptions')
          ? [
              SortOption(value: 'name', labelKey: LocaleKeys.showcaseName),
              SortOption(
                value: 'date',
                labelKey: LocaleKeys.showcaseDialogsDate,
              ),
            ]
          : null,
      activeSortOption: a<bool>('sortOptions') ? _sort : null,
      onApply: (selected, sort) {
        if (!mounted) return;
        setState(() {
          _applied
            ..clear()
            ..addAll(selected.map((o) => o.value));
          _sort = sort;
          final labels = [
            ...selected.map((o) => o.labelKey.tr()),
            if (sort != null)
              '${sort.labelKey.tr()} ${sort.isAscending ? '↑' : '↓'}',
          ];
          _filterResult = labels.isEmpty
              ? LocaleKeys.showcaseDialogsNoResult.tr()
              : labels.join(' · ');
        });
      },
      onReset: () {
        if (!mounted) return;
        setState(() {
          _applied.clear();
          _sort = null;
          _filterResult = LocaleKeys.showcaseDialogsFilterReset.tr();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CallPlayground(
          knobs: [
            ChoiceKnob<String>('titleKey', const {
              'LocaleKeys.showcaseDialogsLeaveTitle':
                  LocaleKeys.showcaseDialogsLeaveTitle,
              'LocaleKeys.showcaseDialogsDeleteTitle':
                  LocaleKeys.showcaseDialogsDeleteTitle,
            }, required: true),
            ChoiceKnob<String>('messageKey', const {
              'LocaleKeys.showcaseDialogsLeaveMessage':
                  LocaleKeys.showcaseDialogsLeaveMessage,
              'LocaleKeys.showcaseDialogsDeleteMessage':
                  LocaleKeys.showcaseDialogsDeleteMessage,
            }, required: true),
            ChoiceKnob<Map<String, String>?>('messageArgs', const {
              'null': null,
              "{'count': '3'}": {'count': '3'},
              "{'count': '500'}": {'count': '500'},
            }, apiDefaultCode: 'null'),
            ChoiceKnob<String?>('confirmKey', const {
              'null': null,
              'LocaleKeys.delete': LocaleKeys.delete,
              'LocaleKeys.save': LocaleKeys.save,
            }, apiDefaultCode: 'null'),
            ChoiceKnob<String?>('cancelKey', const {
              'null': null,
              'LocaleKeys.showcaseBack': LocaleKeys.showcaseBack,
            }, apiDefaultCode: 'null'),
            const BoolKnob('isDestructive'),
            const BoolKnob(
              'barrierDismissible',
              initial: true,
              apiDefault: true,
            ),
          ],
          code: (a) => writeCall('final ok = await AppConfirmDialog.show', [
            'context',
            ...a.named(),
          ]),
          builder: (context, a) => _Result(
            result: _confirmResult,
            child: AppButton(
              text: LocaleKeys.showcaseDialogsOpen.tr(),
              variant: a<bool>('isDestructive')
                  ? AppButtonVariant.danger
                  : AppButtonVariant.filled,
              onTap: () => _confirm(a),
            ),
          ),
        ),
        CallPlayground(
          knobs: [
            ChoiceKnob<int>('child', const {
              'Column(children: [/* 20 ListTiles */])': 20,
              'Column(children: [/* 3 ListTiles */])': 3,
            }, required: true),
            TextKnob(
              'title',
              initial: LocaleKeys.showcaseDialogsPickTitle.tr(),
              // Empty = not passed.
              apiDefault: '',
            ),
            ChoiceKnob<Widget?>('titleWidget', const {
              'null': null,
              'Icon(Icons.info_outline_rounded)': Icon(
                Icons.info_outline_rounded,
              ),
            }, apiDefaultCode: 'null'),
            const BoolKnob('isScrollable', initial: true, apiDefault: true),
            const BoolKnob('showDivider'),
            const NumberKnob(
              'maxHeightFraction',
              initial: 0.9,
              min: 0.3,
              max: 1,
              divisions: 7,
              apiDefault: 0.9,
            ),
            const BoolKnob(
              'dismissOnTapOutside',
              initial: true,
              apiDefault: true,
            ),
          ],
          code: (a) => writeCall(
            'final picked = await AppBottomSheet.show<int>',
            ['context', ...a.named()],
          ),
          builder: (context, a) => _Result(
            result: _sheetResult,
            child: AppButton(
              text: LocaleKeys.showcaseDialogsOpen.tr(),
              variant: AppButtonVariant.tonal,
              onTap: () => _sheet(a),
            ),
          ),
        ),
        CallPlayground(
          knobs: [
            const BoolKnob('multiSelect', initial: true, apiDefault: true),
            ChoiceKnob<bool>(
              'sortOptions',
              const {'null': false, '[SortOption(…), SortOption(…)]': true},
              initialCode: '[SortOption(…), SortOption(…)]',
              apiDefaultCode: 'null',
            ),
          ],
          code: (a) => writeCall('await AppFilterSheet.show<Object>', [
            'context',
            'filterGroups: [\n'
                '  FilterGroup(\n'
                '    titleKey: LocaleKeys.showcaseDialogsStatus,\n'
                '${a<bool>('multiSelect') ? '' : '    multiSelect: false,\n'}'
                '    options: [FilterOption(value: …, labelKey: …), …],\n'
                '  ),\n'
                '  FilterGroup(…, multiSelect: false),\n'
                ']',
            ...a.named(skip: {'multiSelect'}),
            'onApply: (selected, sort) => …',
            'onReset: () => …',
          ]),
          builder: (context, a) => _Result(
            result: _filterResult,
            child: AppButton(
              text: LocaleKeys.showcaseDialogsOpenFilter.tr(),
              variant: AppButtonVariant.tonal,
              onTap: () => _filters(a),
            ),
          ),
        ),
      ],
    );
  }
}

/// The button that opens one call, and under it what the last one returned.
class _Result extends StatelessWidget {
  const _Result({required this.result, required this.child});

  final String? result;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      child,
      12.heightBox,
      Text(
        LocaleKeys.showcaseDialogsResult.tr(
          args: [result ?? LocaleKeys.showcaseDialogsNoResult.tr()],
        ),
        textAlign: TextAlign.center,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    ],
  );
}
