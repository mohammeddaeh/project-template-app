import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/clipboard/clipboard_service.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Cards, rows, detail headers and the small labels that sit on them —
/// everything a detail or list page reads from.
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
  bool _waiting = false;

  static void _noop() {}

  void _tapped(String key) => context.feedback.info(key.tr());

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
        DemoBlock(
          code: 'AppCard(variant: AppCardVariant.…)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final v in AppCardVariant.values)
                AppCard(
                  variant: v,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Text(v.name),
                ),
            ],
          ),
        ),
        DemoBlock(
          code: 'AppListTile(titleKey · leadingIcon · trailing · dense · …)',
          child: Column(
            children: [
              AppListTile(
                titleKey: LocaleKeys.showcaseDisplayTitle,
                subtitleKey: LocaleKeys.showcaseDisplaySubtitle,
                leadingIcon: Icons.description_outlined,
                trailing: const Icon(Icons.chevron_right),
                showDivider: true,
                onTap: () => _tapped(LocaleKeys.showcaseDisplayTitle),
              ),
              AppListTile(
                titleText: LocaleKeys.showcaseItem.tr(args: ['3']),
                leading: AvatarWidget(
                  initial: LocaleKeys.showcaseItem.tr(),
                  radius: 18,
                ),
                dense: true,
                showDivider: true,
                onTap: _noop,
              ),
              AppListTile(
                titleKey: LocaleKeys.showcaseDisplayClosed,
                leadingIcon: Icons.lock_outline,
                enabled: false,
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'KeyValueSection(rows: [KeyValueRow(copyable: …, ltr: …)])',
          child: KeyValueSection(
            titleKey: LocaleKeys.showcaseDisplayDetails,
            padding: EdgeInsets.zero,
            rows: [
              KeyValueRow(
                labelKey: LocaleKeys.showcaseDisplayReference,
                value: 'REF-2041-07',
                copyable: canCopy,
                ltr: true,
              ),
              KeyValueRow(
                labelKey: LocaleKeys.showcaseDisplayOwner,
                value: LocaleKeys.showcaseName.tr(),
              ),
              KeyValueRow(
                labelKey: LocaleKeys.showcaseDisplayStatus,
                valueWidget: const StatusChip(
                  labelKey: LocaleKeys.showcaseDisplayOpen,
                  tone: StatusTone.success,
                ),
                showDivider: false,
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'ExpandableSection(titleKey: …, child: …)',
          child: ExpandableSection(
            titleKey: LocaleKeys.showcaseDisplayDetails,
            subtitleKey: LocaleKeys.showcaseDisplaySubtitle,
            leading: const Icon(Icons.unfold_more),
            showDivider: false,
            child: Text(LocaleKeys.showcaseDisplayFolded.tr()),
          ),
        ),
        DemoBlock(
          code: 'StatCard(value: …, labelKey: …, isLoading: …)',
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '128',
                  labelKey: LocaleKeys.showcaseDisplayItems,
                  icon: Icons.inventory_2_outlined,
                  onTap: () => _tapped(LocaleKeys.showcaseDisplayItems),
                ),
              ),
              12.widthBox,
              Expanded(
                child: StatCard(
                  value: '7',
                  labelKey: LocaleKeys.showcaseDisplayUrgent,
                  icon: Icons.priority_high,
                  color: context.colors.error,
                ),
              ),
              12.widthBox,
              const Expanded(
                child: StatCard(
                  value: '0',
                  labelKey: LocaleKeys.loading,
                  isLoading: true,
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code:
              'DetailHeaderCard(title · leading · tags · facts) · '
              'DetailFact · DetailSectionHeader',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DetailHeaderCard(
                title: title,
                subtitle: LocaleKeys.showcaseDisplaySubtitle.tr(),
                leading: AvatarWidget(initial: title),
                tags: const [
                  StatusChip(
                    labelKey: LocaleKeys.showcaseDisplayOpen,
                    tone: StatusTone.success,
                  ),
                  StatusChip(
                    labelKey: LocaleKeys.showcaseDisplayUrgent,
                    tone: StatusTone.warning,
                  ),
                ],
                facts: [
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
                    value: 'REF-2041-07',
                    forceLtr: true,
                  ),
                  // No value ⇒ the fact says "not specified" by itself.
                  DetailFact(
                    icon: Icons.event_outlined,
                    label: LocaleKeys.showcaseDisplayDue.tr(),
                    value: null,
                  ),
                ],
              ),
              16.heightBox,
              DetailSectionHeader(
                icon: Icons.list_alt_outlined,
                title: LocaleKeys.showcaseDisplayDetails.tr(),
                subtitle: LocaleKeys.showcaseDisplaySubtitle.tr(),
                trailing: const StatusChip(
                  labelText: '3',
                  tone: StatusTone.info,
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'SectionTitle(titleKey: …, trailing: …)',
          child: SectionTitle(
            titleKey: LocaleKeys.showcaseDisplayDetails,
            padding: EdgeInsets.zero,
            trailing: TextButton(
              onPressed: () => _tapped(LocaleKeys.showcaseDisplayDetails),
              child: Text(LocaleKeys.showcaseDisplayEdit.tr()),
            ),
          ),
        ),
        DemoBlock(
          code: 'BadgeWidget(count: … | label: …, child: …)',
          child: Wrap(
            spacing: 24,
            children: [
              const BadgeWidget(
                count: 4,
                child: Icon(Icons.notifications_outlined),
              ),
              const BadgeWidget(count: 120, child: Icon(Icons.mail_outline)),
              BadgeWidget(
                label: LocaleKeys.showcaseDisplayNew.tr(),
                child: const Icon(Icons.inbox_outlined),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'ChipWidget(selected: …, onSelected: …, onDeleted: …)',
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
        DemoBlock(
          code: 'TagWidget(labelKey: …, backgroundColor: …)',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const TagWidget(labelKey: LocaleKeys.showcaseDisplayDraft),
              TagWidget(
                labelKey: LocaleKeys.showcaseDisplayUrgent,
                backgroundColor: context.colors.error,
                foregroundColor: context.colors.textOnPrimary,
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'StatusChip(tone: StatusTone.…)',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in StatusTone.values)
                StatusChip(labelText: t.name, tone: t),
            ],
          ),
        ),
        DemoBlock(
          code: 'ShimmerText(value) — Text, or a bone inside Skeletonized',
          child: Row(
            children: [
              Expanded(
                child: Skeletonized(
                  enabled: _waiting,
                  child: ShimmerText(
                    title,
                    style: context.textTheme.titleMedium,
                  ),
                ),
              ),
              Switch(
                value: _waiting,
                onChanged: (v) => setState(() => _waiting = v),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'AppDateText(date)',
          child: AppDateText(DateTime(2026, 3, 15)),
        ),
      ],
    );
  }
}
