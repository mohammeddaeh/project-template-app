import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/clipboard/clipboard_service.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/playground_tokens.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Cards, rows, detail headers and the small labels that sit on them —
/// everything a detail or list page reads from, each with its options as
/// controls.
class DisplayDemo extends StatefulWidget {
  const DisplayDemo({super.key});

  @override
  State<DisplayDemo> createState() => _DisplayDemoState();
}

class _DisplayDemoState extends State<DisplayDemo> {
  final _filters = <String>{LocaleKeys.showcaseDisplayOpen};
  final _tags = <String>[
    LocaleKeys.showcaseDisplayDraft,
    LocaleKeys.showcaseDisplayUrgent,
  ];
  int _taps = 0;

  static const _ref = 'REF-2041-07';

  static const _icons = <String, IconData?>{
    'null': null,
    'Icons.description_outlined': Icons.description_outlined,
    'Icons.folder_outlined': Icons.folder_outlined,
    'Icons.inventory_2_outlined': Icons.inventory_2_outlined,
  };

  static const _labelKeys = <String, String>{
    'LocaleKeys.showcaseDisplayOpen': LocaleKeys.showcaseDisplayOpen,
    'LocaleKeys.showcaseDisplayDraft': LocaleKeys.showcaseDisplayDraft,
    'LocaleKeys.showcaseDisplayUrgent': LocaleKeys.showcaseDisplayUrgent,
  };

  static const _subtitleKeys = <String, String?>{
    'null': null,
    'LocaleKeys.showcaseDisplaySubtitle': LocaleKeys.showcaseDisplaySubtitle,
  };

  void _tapped(String key) => context.feedback.info(key.tr());

  void _count() => setState(() => _taps++);

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    // Copying goes through `ClipboardService` — offered only where it exists.
    final canCopy = getIt.isRegistered<ClipboardService>();
    final title = LocaleKeys.showcaseDisplayTitle.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── AppCard ─────────────────────────────────────────────────────────
        DemoPlayground(
          call: 'AppCard',
          knobs: [
            EnumKnob('variant', AppCardVariant.values, AppCardVariant.card),
            ChoiceKnob<double>('padding', const {
              'const EdgeInsets.all(16)': 16,
              'EdgeInsets.zero': 0,
              'const EdgeInsets.all(8)': 8,
              'const EdgeInsets.all(24)': 24,
            }, apiDefaultCode: 'const EdgeInsets.all(16)'),
            ChoiceKnob<double?>('margin', const {
              'null': null,
              'EdgeInsets.zero': 0,
              'const EdgeInsets.all(24)': 24,
            }, apiDefaultCode: 'null'),
            ChoiceKnob<double?>('elevation', const {
              'null': null,
              '0': 0,
              '2': 2,
              '8': 8,
            }, apiDefaultCode: 'null'),
          ],
          trailingCode: const ['child: Text(…)'],
          builder: (context, k) {
            final margin = k<double?>('margin');
            return AppCard(
              variant: k('variant'),
              padding: EdgeInsets.all(k('padding')),
              margin: margin == null ? null : EdgeInsets.all(margin),
              elevation: k('elevation'),
              child: Text(LocaleKeys.showcaseDisplaySubtitle.tr()),
            );
          },
        ),
        // ── AppListTile ─────────────────────────────────────────────────────
        DemoPlayground(
          call: 'AppListTile',
          knobs: [
            TextKnob('titleText', initial: title, required: true),
            ChoiceKnob<String?>(
              'subtitleKey',
              _subtitleKeys,
              initialCode: 'LocaleKeys.showcaseDisplaySubtitle',
              apiDefaultCode: 'null',
            ),
            ChoiceKnob<IconData?>(
              'leadingIcon',
              _icons,
              initialCode: 'Icons.description_outlined',
              apiDefaultCode: 'null',
            ),
            ChoiceKnob<String?>('leading', const {
              'null': null,
              'AvatarWidget(initial: …)': 'avatar',
            }, apiDefaultCode: 'null'),
            ChoiceKnob<String?>('trailing', const {
              'null': null,
              'StatusChip(…)': 'chip',
              'Icon(Icons.more_vert)': 'icon',
              'Text(…)': 'text',
            }, apiDefaultCode: 'null'),
            colorKnob('titleColor', const ['primary', 'error']),
            callbackKnob('onTap', code: '() => taps++'),
            callbackKnob('onLongPress', code: '() => toast(…)', initial: false),
            const BoolKnob('dense'),
            const BoolKnob('enabled', initial: true, apiDefault: true),
            const BoolKnob('showDivider'),
          ],
          builder: (context, k) {
            final trailing = switch (k<String?>('trailing')) {
              'chip' => const StatusChip(
                labelKey: LocaleKeys.showcaseDisplayOpen,
                tone: StatusTone.success,
              ),
              'icon' => const Icon(Icons.more_vert),
              'text' => Text('$_taps'),
              _ => null,
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppListTile(
                  titleText: k('titleText'),
                  subtitleKey: k('subtitleKey'),
                  leadingIcon: k('leadingIcon'),
                  leading: k<String?>('leading') == null
                      ? null
                      : AvatarWidget(initial: k('titleText'), radius: 18),
                  trailing: trailing,
                  titleColor: tokenColor(context, k('titleColor')),
                  onTap: k('onTap') ? _count : null,
                  onLongPress: k('onLongPress')
                      ? () => _tapped(LocaleKeys.showcaseDisplayLongPress)
                      : null,
                  dense: k('dense'),
                  enabled: k('enabled'),
                  showDivider: k('showDivider'),
                ),
                8.heightBox,
                Text(
                  LocaleKeys.showcaseDisplayTaps.tr(args: ['$_taps']),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            );
          },
        ),
        // ── KeyValueRow ─────────────────────────────────────────────────────
        DemoPlayground(
          call: 'KeyValueRow',
          knobs: [
            ChoiceKnob<String>('labelKey', const {
              'LocaleKeys.showcaseDisplayReference':
                  LocaleKeys.showcaseDisplayReference,
              'LocaleKeys.showcaseDisplayOwner':
                  LocaleKeys.showcaseDisplayOwner,
            }, required: true),
            const TextKnob('value', initial: _ref),
            ChoiceKnob<String?>('valueWidget', const {
              'null': null,
              'StatusChip(…)': 'chip',
              'Icon(Icons.verified_outlined)': 'icon',
            }, apiDefaultCode: 'null'),
            BoolKnob('copyable', initial: canCopy),
            const BoolKnob('ltr', initial: true),
            const BoolKnob('showDivider', initial: true, apiDefault: true),
          ],
          builder: (context, k) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyValueRow(
                labelKey: k('labelKey'),
                value: k('value'),
                valueWidget: switch (k<String?>('valueWidget')) {
                  'chip' => const StatusChip(
                    labelKey: LocaleKeys.showcaseDisplayOpen,
                    tone: StatusTone.success,
                  ),
                  'icon' => Icon(
                    Icons.verified_outlined,
                    color: context.colors.primary,
                  ),
                  _ => null,
                },
                // The copy button calls `ClipboardService` — only with one.
                copyable: k<bool>('copyable') && canCopy,
                ltr: k('ltr'),
                showDivider: k('showDivider'),
              ),
              if (k<bool>('copyable') && !canCopy)
                Text(
                  LocaleKeys.showcaseDisplayNoClipboard.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
            ],
          ),
        ),
        DemoBlock(
          code: 'KeyValueSection(titleKey: …, rows: [KeyValueRow(…), …])',
          child: KeyValueSection(
            titleKey: LocaleKeys.showcaseDisplayDetails,
            padding: EdgeInsets.zero,
            rows: [
              KeyValueRow(
                labelKey: LocaleKeys.showcaseDisplayReference,
                value: _ref,
                copyable: canCopy,
                ltr: true,
              ),
              KeyValueRow(
                labelKey: LocaleKeys.showcaseDisplayOwner,
                value: LocaleKeys.showcaseName.tr(),
                showDivider: false,
              ),
            ],
          ),
        ),
        // ── ExpandableSection ───────────────────────────────────────────────
        DemoPlayground(
          call: 'ExpandableSection',
          knobs: [
            TextKnob(
              'titleText',
              initial: LocaleKeys.showcaseDisplayDetails.tr(),
              required: true,
            ),
            ChoiceKnob<String?>(
              'subtitleKey',
              _subtitleKeys,
              initialCode: 'LocaleKeys.showcaseDisplaySubtitle',
              apiDefaultCode: 'null',
            ),
            ChoiceKnob<IconData?>(
              'leading',
              const {
                'null': null,
                'Icon(Icons.unfold_more)': Icons.unfold_more,
                'Icon(Icons.tune)': Icons.tune,
              },
              initialCode: 'Icon(Icons.unfold_more)',
              apiDefaultCode: 'null',
            ),
            const BoolKnob('initiallyExpanded'),
            // Controlled: the parent owns the state and the tap only reports.
            ChoiceKnob<bool?>('isExpanded', const {
              'null': null,
              'true': true,
              'false': false,
            }, apiDefaultCode: 'null'),
            callbackKnob('onToggle', code: '() => toast(…)', initial: false),
            const BoolKnob('showDivider', initial: true, apiDefault: true),
          ],
          trailingCode: const ['child: Text(…)'],
          builder: (context, k) {
            final leading = k<IconData?>('leading');
            return ExpandableSection(
              // `initiallyExpanded` is read once — a new value starts afresh.
              key: ValueKey(k<bool>('initiallyExpanded')),
              titleText: k('titleText'),
              subtitleKey: k('subtitleKey'),
              leading: leading == null ? null : Icon(leading),
              initiallyExpanded: k('initiallyExpanded'),
              isExpanded: k('isExpanded'),
              onToggle: k('onToggle')
                  ? () => _tapped(LocaleKeys.showcaseDisplayToggled)
                  : null,
              showDivider: k('showDivider'),
              child: Text(LocaleKeys.showcaseDisplayFolded.tr()),
            );
          },
        ),
        // ── StatCard ────────────────────────────────────────────────────────
        DemoPlayground(
          call: 'StatCard',
          knobs: [
            const TextKnob('value', initial: '128', required: true),
            TextKnob(
              'labelText',
              initial: LocaleKeys.showcaseDisplayItems.tr(),
              required: true,
            ),
            ChoiceKnob<IconData?>(
              'icon',
              _icons,
              initialCode: 'Icons.inventory_2_outlined',
              apiDefaultCode: 'null',
            ),
            colorKnob('color', const [
              'error',
              'feedbackSuccess',
              'feedbackWarning',
            ]),
            callbackKnob('onTap', code: '() => toast(…)'),
            const BoolKnob('isLoading'),
          ],
          builder: (context, k) => SizedBox(
            width: 200,
            child: StatCard(
              value: k('value'),
              labelText: k('labelText'),
              icon: k('icon'),
              color: tokenColor(context, k('color')),
              onTap: k('onTap')
                  ? () => _tapped(LocaleKeys.showcaseDisplayItems)
                  : null,
              isLoading: k('isLoading'),
            ),
          ),
        ),
        // ── DetailHeaderCard · DetailFact ───────────────────────────────────
        DemoPlayground(
          call: 'DetailHeaderCard',
          knobs: [
            TextKnob('title', initial: title, required: true),
            ChoiceKnob<String>('leading', const {
              'AvatarWidget(initial: …)': 'avatar',
              'Icon(Icons.description_outlined)': 'icon',
            }, required: true),
            ChoiceKnob<String?>(
              'subtitle',
              {
                'null': null,
                'LocaleKeys.showcaseDisplaySubtitle.tr()':
                    LocaleKeys.showcaseDisplaySubtitle,
              },
              initialCode: 'LocaleKeys.showcaseDisplaySubtitle.tr()',
              apiDefaultCode: 'null',
            ),
            ChoiceKnob<int>(
              'tags',
              const {
                'const []': 0,
                '[StatusChip(…)]': 1,
                '[StatusChip(…), StatusChip(…)]': 2,
              },
              initialCode: '[StatusChip(…), StatusChip(…)]',
              apiDefaultCode: 'const []',
            ),
            ChoiceKnob<int>(
              'facts',
              const {'const []': 0, '[DetailFact(…) × 3]': 3},
              initialCode: '[DetailFact(…) × 3]',
              apiDefaultCode: 'const []',
            ),
            ChoiceKnob<String?>('trailing', const {
              'null': null,
              'IconButton(…)': 'button',
            }, apiDefaultCode: 'null'),
            ChoiceKnob<String?>('footer', const {
              'null': null,
              'Text(…)': 'text',
            }, apiDefaultCode: 'null'),
          ],
          builder: (context, k) {
            final t = k<String>('title');
            final subtitle = k<String?>('subtitle');
            return DetailHeaderCard(
              title: t,
              subtitle: subtitle?.tr(),
              leading: k<String>('leading') == 'avatar'
                  ? AvatarWidget(initial: t)
                  : Icon(
                      Icons.description_outlined,
                      size: 40,
                      color: context.colors.primary,
                    ),
              tags: [
                if (k<int>('tags') >= 1)
                  const StatusChip(
                    labelKey: LocaleKeys.showcaseDisplayOpen,
                    tone: StatusTone.success,
                  ),
                if (k<int>('tags') >= 2)
                  const StatusChip(
                    labelKey: LocaleKeys.showcaseDisplayUrgent,
                    tone: StatusTone.warning,
                  ),
              ],
              facts: [
                if (k<int>('facts') > 0) ...[
                  DetailFact(
                    icon: Icons.place_outlined,
                    label: LocaleKeys.showcaseDisplayLocation.tr(),
                    value: LocaleKeys.showcaseDisplayLocationValue.tr(),
                    onEdit: () => _tapped(LocaleKeys.showcaseDisplayEdit),
                    editTooltip: LocaleKeys.showcaseDisplayEdit.tr(),
                  ),
                  DetailFact(
                    icon: Icons.tag,
                    label: LocaleKeys.showcaseDisplayReference.tr(),
                    value: _ref,
                    forceLtr: true,
                  ),
                  // No value ⇒ the fact says "not specified" by itself.
                  DetailFact(
                    icon: Icons.event_outlined,
                    label: LocaleKeys.showcaseDisplayDue.tr(),
                    value: null,
                  ),
                ],
              ],
              trailing: k<String?>('trailing') == null
                  ? null
                  : IconButton(
                      tooltip: LocaleKeys.showcaseDisplayEdit.tr(),
                      onPressed: () => _tapped(LocaleKeys.showcaseDisplayEdit),
                      icon: const Icon(Icons.edit_outlined),
                    ),
              footer: k<String?>('footer') == null
                  ? null
                  : Text(
                      LocaleKeys.showcaseDisplayFooter.tr(),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textMuted,
                      ),
                    ),
            );
          },
        ),
        DemoPlayground(
          call: 'DetailFact',
          knobs: [
            ChoiceKnob<IconData>('icon', const {
              'Icons.place_outlined': Icons.place_outlined,
              'Icons.tag': Icons.tag,
              'Icons.event_outlined': Icons.event_outlined,
            }, required: true),
            TextKnob(
              'label',
              initial: LocaleKeys.showcaseDisplayLocation.tr(),
              required: true,
            ),
            ChoiceKnob<String?>(
              'value',
              {
                'null': null,
                "'$_ref'": _ref,
                'LocaleKeys.showcaseDisplayLocationValue.tr()':
                    LocaleKeys.showcaseDisplayLocationValue,
              },
              initialCode: 'LocaleKeys.showcaseDisplayLocationValue.tr()',
              required: true,
            ),
            ChoiceKnob<String?>('hint', {
              'null': null,
              'LocaleKeys.showcaseDisplaySubtitle.tr()':
                  LocaleKeys.showcaseDisplaySubtitle,
            }, apiDefaultCode: 'null'),
            callbackKnob('onEdit', code: '() => toast(…)'),
            const BoolKnob('forceLtr'),
            colorKnob('valueColor', const ['primary', 'error']),
          ],
          builder: (context, k) {
            final value = k<String?>('value');
            return DetailFact(
              icon: k('icon'),
              label: k('label'),
              value: value == null || value == _ref ? value : value.tr(),
              hint: k<String?>('hint')?.tr(),
              onEdit: k('onEdit')
                  ? () => _tapped(LocaleKeys.showcaseDisplayEdit)
                  : null,
              editTooltip: LocaleKeys.showcaseDisplayEdit.tr(),
              forceLtr: k('forceLtr'),
              valueColor: tokenColor(context, k('valueColor')),
            );
          },
        ),
        DemoBlock(
          code:
              'DetailSectionHeader(icon: …, title: …, trailing: …) · '
              'SectionTitle(titleKey: …, trailing: …)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DetailSectionHeader(
                icon: Icons.list_alt_outlined,
                title: LocaleKeys.showcaseDisplayDetails.tr(),
                subtitle: LocaleKeys.showcaseDisplaySubtitle.tr(),
                trailing: const StatusChip(
                  labelText: '3',
                  tone: StatusTone.info,
                ),
              ),
              16.heightBox,
              SectionTitle(
                titleKey: LocaleKeys.showcaseDisplayDetails,
                padding: EdgeInsets.zero,
                trailing: TextButton(
                  onPressed: () => _tapped(LocaleKeys.showcaseDisplayDetails),
                  child: Text(LocaleKeys.showcaseDisplayEdit.tr()),
                ),
              ),
            ],
          ),
        ),
        // ── BadgeWidget ─────────────────────────────────────────────────────
        DemoPlayground(
          call: 'BadgeWidget',
          knobs: [
            const NumberKnob(
              'count',
              initial: 4,
              min: 0,
              max: 120,
              integer: true,
            ),
            colorKnob('backgroundColor', const ['primary', 'feedbackSuccess']),
            colorKnob('textColor', const ['onBrand', 'textPrimary']),
            ChoiceKnob<IconData>('child', const {
              'Icon(Icons.notifications_outlined)':
                  Icons.notifications_outlined,
              'Icon(Icons.mail_outline)': Icons.mail_outline,
            }, required: true),
          ],
          // 0 draws no badge; above 99 reads «99+».
          builder: (context, k) => BadgeWidget(
            count: k<double>('count').round(),
            backgroundColor: tokenColor(context, k('backgroundColor')),
            textColor: tokenColor(context, k('textColor')),
            child: Icon(k<IconData>('child'), size: 32),
          ),
        ),
        DemoPlayground(
          call: 'BadgeWidget',
          knobs: [
            TextKnob(
              'label',
              initial: LocaleKeys.showcaseDisplayNew.tr(),
              required: true,
            ),
            colorKnob('backgroundColor', const ['primary', 'feedbackSuccess']),
          ],
          trailingCode: const ['child: Icon(Icons.inbox_outlined)'],
          builder: (context, k) => BadgeWidget(
            label: k('label'),
            backgroundColor: tokenColor(context, k('backgroundColor')),
            child: const Icon(Icons.inbox_outlined, size: 32),
          ),
        ),
        // ── ChipWidget · TagWidget ──────────────────────────────────────────
        DemoPlayground(
          call: 'ChipWidget',
          knobs: [
            ChoiceKnob<String>('labelKey', _labelKeys, required: true),
            const BoolKnob('selected'),
            callbackKnob('onSelected', code: '(on) => toast(…)'),
            callbackKnob('onDeleted', code: '() => toast(…)', initial: false),
          ],
          builder: (context, k) => ChipWidget(
            labelKey: k('labelKey'),
            selected: k('selected'),
            onSelected: k('onSelected')
                ? (on) => context.feedback.info(
                    LocaleKeys.showcaseDisplaySelected.tr(args: ['$on']),
                  )
                : null,
            onDeleted: k('onDeleted')
                ? () => _tapped(LocaleKeys.showcaseDisplayDeleted)
                : null,
          ),
        ),
        DemoBlock(
          code: 'ChipWidget — a filter set and removable tags, in use',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in [
                LocaleKeys.showcaseDisplayOpen,
                LocaleKeys.showcaseDisplayClosed,
              ])
                ChipWidget(
                  labelKey: k,
                  selected: _filters.contains(k),
                  onSelected: (on) =>
                      setState(() => on ? _filters.add(k) : _filters.remove(k)),
                ),
              for (final k in _tags)
                ChipWidget(
                  labelKey: k,
                  onDeleted: () => setState(() => _tags.remove(k)),
                ),
            ],
          ),
        ),
        DemoPlayground(
          call: 'TagWidget',
          knobs: [
            ChoiceKnob<String>('labelKey', _labelKeys, required: true),
            colorKnob('backgroundColor', const ['error', 'bgBrand']),
            colorKnob('foregroundColor', const ['textOnPrimary', 'onBrand']),
          ],
          builder: (context, k) => TagWidget(
            labelKey: k('labelKey'),
            backgroundColor: tokenColor(context, k('backgroundColor')),
            foregroundColor: tokenColor(context, k('foregroundColor')),
          ),
        ),
        // ── ShimmerText ─────────────────────────────────────────────────────
        DemoPlayground(
          call: 'Skeletonized',
          knobs: [const BoolKnob('enabled', initial: true, required: true)],
          trailingCode: const ['child: ShimmerText(title)'],
          previewAlignment: AlignmentDirectional.centerStart,
          builder: (context, k) => Skeletonized(
            enabled: k('enabled'),
            child: ShimmerText(title, style: context.textTheme.titleMedium),
          ),
        ),
        // ── AppDateText ─────────────────────────────────────────────────────
        DemoPlayground(
          call: 'AppDateText',
          knobs: [
            EnumKnob(
              'calendar',
              AppDateCalendar.values,
              AppDateCalendar.both,
              apiDefault: AppDateCalendar.hijri,
            ),
            EnumKnob('layout', AppDateLayout.values, AppDateLayout.stacked),
            EnumKnob(
              'monthFormat',
              AppDateMonthFormat.values,
              AppDateMonthFormat.nameFull,
            ),
            EnumKnob('language', AppDateLanguage.values, AppDateLanguage.auto),
            const TextKnob('partSeparator', initial: '/', apiDefault: '/'),
            const TextKnob(
              'calendarSeparator',
              initial: '  •  ',
              apiDefault: '  •  ',
            ),
          ],
          // A named argument may come before the positional one.
          trailingCode: const ['DateTime(2026, 3, 15)'],
          builder: (context, k) => AppDateText(
            DateTime(2026, 3, 15),
            calendar: k('calendar'),
            layout: k('layout'),
            monthFormat: k('monthFormat'),
            language: k('language'),
            partSeparator: k('partSeparator'),
            calendarSeparator: k('calendarSeparator'),
            style: context.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
