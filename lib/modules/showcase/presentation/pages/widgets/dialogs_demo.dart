import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The confirm dialog in both tones, the bottom sheet's shapes and the filter
/// sheet — each one reports what it returned under its buttons.
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

  Future<void> _confirm({required bool destructive}) async {
    final bool ok;
    if (destructive) {
      ok = await AppConfirmDialog.show(
        context,
        titleKey: LocaleKeys.showcaseDialogsDeleteTitle,
        messageKey: LocaleKeys.showcaseDialogsDeleteMessage,
        messageArgs: const {'count': '3'},
        confirmKey: LocaleKeys.delete,
        isDestructive: true,
      );
    } else {
      ok = await AppConfirmDialog.show(
        context,
        titleKey: LocaleKeys.showcaseDialogsLeaveTitle,
        messageKey: LocaleKeys.showcaseDialogsLeaveMessage,
      );
    }
    if (!mounted) return;
    setState(() => _confirmResult = '$ok');
  }

  Future<void> _listSheet() async {
    final picked = await AppBottomSheet.show<int>(
      context,
      title: LocaleKeys.showcaseDialogsPickTitle.tr(),
      showDivider: true,
      child: Builder(
        builder: (sheet) => Column(
          children: [
            for (var n = 1; n <= 20; n++)
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

  Future<void> _fixedSheet() async {
    final done = await AppBottomSheet.show<bool>(
      context,
      isScrollable: false,
      maxHeightFraction: 0.4,
      dismissOnTapOutside: false,
      titleWidget: Icon(
        Icons.info_outline_rounded,
        color: context.colors.primary,
      ),
      child: Builder(
        builder: (sheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.showcaseDialogsFixedBody.tr(),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
            16.heightBox,
            AppButton(
              text: LocaleKeys.done.tr(),
              onTap: () => Navigator.of(sheet).pop(true),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(
      () => _sheetResult = done == true
          ? LocaleKeys.done.tr()
          : LocaleKeys.showcaseDialogsDismissed.tr(),
    );
  }

  Future<void> _filters() async {
    FilterOption<Object> option(Object v, String key) =>
        FilterOption(value: v, labelKey: key, isSelected: _applied.contains(v));

    await AppFilterSheet.show<Object>(
      context,
      filterGroups: [
        FilterGroup(
          titleKey: LocaleKeys.showcaseDialogsStatus,
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
      sortOptions: [
        SortOption(value: 'name', labelKey: LocaleKeys.showcaseName),
        SortOption(value: 'date', labelKey: LocaleKeys.showcaseDialogsDate),
      ],
      activeSortOption: _sort,
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
        DemoBlock(
          code:
              'await AppConfirmDialog.show(context, titleKey: …, '
              'messageKey: …, messageArgs: {…}, isDestructive: …)',
          child: _Result(
            result: _confirmResult,
            children: [
              AppButton(
                text: LocaleKeys.showcaseDialogsNormal.tr(),
                onTap: () => _confirm(destructive: false),
              ),
              AppButton(
                text: LocaleKeys.showcaseDialogsDestructive.tr(),
                variant: AppButtonVariant.danger,
                onTap: () => _confirm(destructive: true),
              ),
            ],
          ),
        ),
        DemoBlock(
          code:
              'await AppBottomSheet.show<T>(context, title: …, '
              'showDivider: true · isScrollable: false, '
              'maxHeightFraction: 0.4, dismissOnTapOutside: false)',
          child: _Result(
            result: _sheetResult,
            children: [
              AppButton(
                text: LocaleKeys.showcaseDialogsScrollable.tr(),
                variant: AppButtonVariant.tonal,
                onTap: _listSheet,
              ),
              AppButton(
                text: LocaleKeys.showcaseDialogsFixed.tr(),
                variant: AppButtonVariant.tonal,
                onTap: _fixedSheet,
              ),
            ],
          ),
        ),
        DemoBlock(
          code:
              'AppFilterSheet.show<T>(context, filterGroups: [FilterGroup('
              'options: [FilterOption(…)], multiSelect: …)], '
              'sortOptions: [SortOption(…)], onApply: …, onReset: …)',
          child: _Result(
            result: _filterResult,
            children: [
              AppButton(
                text: LocaleKeys.showcaseDialogsOpenFilter.tr(),
                variant: AppButtonVariant.tonal,
                onTap: _filters,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The buttons of one demo, and under them what the last one returned.
class _Result extends StatelessWidget {
  const _Result({required this.result, required this.children});

  final String? result;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(spacing: 8, runSpacing: 8, children: children),
      12.heightBox,
      Text(
        LocaleKeys.showcaseDialogsResult.tr(
          args: [result ?? LocaleKeys.showcaseDialogsNoResult.tr()],
        ),
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    ],
  );
}
