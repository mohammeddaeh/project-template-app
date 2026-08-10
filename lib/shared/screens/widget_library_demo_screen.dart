import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/feedback/feedback_style.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

@RoutePage(name: 'WidgetLibraryDemoRoute')
class WidgetLibraryDemoScreen extends StatefulWidget {
  const WidgetLibraryDemoScreen({super.key});

  @override
  State<WidgetLibraryDemoScreen> createState() =>
      _WidgetLibraryDemoScreenState();
}

enum _SkeletonVariant { listTile, card, gridItem, profile, statRow }

class _WidgetLibraryDemoScreenState extends State<WidgetLibraryDemoScreen> {
  FeedbackStyle _feedbackStyle = FeedbackStyle.motionToast;
  _SkeletonVariant _skeletonVariant = _SkeletonVariant.listTile;
  late final TextEditingController _textCtrl;
  late final TextEditingController _passCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: 'أبو سعد');
    _passCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.widgetLibraryTitle.tr()),
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: RefreshWrapper(
        onRefresh: () async {},
        child: KeyboardDismissWidget(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Toast & Feedback ─────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.notifications_rounded,
                  title: LocaleKeys.feedback.tr(),
                ),
                _FeedbackStyleSelector(
                  selected: _feedbackStyle,
                  onChanged: (s) => setState(() => _feedbackStyle = s),
                ),
                const SizedBox(height: 8),
                AppCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _btn(
                        context,
                        LocaleKeys.toastSuccess.tr(),
                        () => context.feedback.success(
                          LocaleKeys.success.tr(),
                          style: _feedbackStyle,
                        ),
                      ),
                      _btn(
                        context,
                        LocaleKeys.toastError.tr(),
                        () => context.feedback.error(
                          LocaleKeys.error.tr(),
                          style: _feedbackStyle,
                        ),
                      ),
                      _btn(
                        context,
                        LocaleKeys.warning.tr(),
                        () => context.feedback.warning(
                          LocaleKeys.warning.tr(),
                          style: _feedbackStyle,
                        ),
                      ),
                      _btn(
                        context,
                        LocaleKeys.snackbar.tr(),
                        () => context.feedback.info(
                          LocaleKeys.info.tr(),
                          style: _feedbackStyle,
                        ),
                      ),
                      _btn(
                        context,
                        LocaleKeys.toast.tr(),
                        () => context.feedback.toast(
                          LocaleKeys.toastMessage.tr(),
                          style: _feedbackStyle,
                        ),
                      ),
                      _btn(context, LocaleKeys.loading.tr(), () async {
                        context.showLoadingDialog();
                        await Future.delayed(const Duration(seconds: 2));
                        if (context.mounted) context.dismissDialog();
                      }),
                    ],
                  ),
                ),

                // ── Dialogs & Sheets ─────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.layers_rounded,
                  title: LocaleKeys.dialog.tr(),
                ),
                AppCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _btn(
                        context,
                        LocaleKeys.dialog.tr(),
                        () => context.showCustomDialog(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(LocaleKeys.dialogContent.tr()),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(LocaleKeys.done.tr()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _btn(
                        context,
                        LocaleKeys.confirm.tr(),
                        () => context.showConfirmDialog(
                          title: LocaleKeys.confirm.tr(),
                          message: LocaleKeys.logoutConfirmMessage.tr(),
                          onConfirm: () =>
                              context.feedback.toast(LocaleKeys.done.tr()),
                        ),
                      ),
                      _btn(
                        context,
                        LocaleKeys.bottomSheet.tr(),
                        () => context.showAppBottomSheet(
                          size: AppBottomSheetSize.compact,
                          title: LocaleKeys.title.tr(),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(LocaleKeys.sheetContent.tr()),
                          ),
                        ),
                      ),
                      _btn(
                        context,
                        LocaleKeys.customSheet.tr(),
                        () => AppBottomSheet.show<void>(
                          context,
                          title: LocaleKeys.title.tr(),
                          showDivider: true,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(LocaleKeys.sheetContent.tr()),
                          ),
                        ),
                      ),
                      _btn(
                        context,
                        LocaleKeys.filterSheet.tr(),
                        () => AppFilterSheet.show<String>(
                          context,
                          filterGroups: [
                            FilterGroup<String>(
                              titleKey: LocaleKeys.filter,
                              options: [
                                FilterOption<String>(
                                  value: 'active',
                                  labelKey: 'active',
                                ),
                                FilterOption<String>(
                                  value: 'inactive',
                                  labelKey: 'inactive',
                                ),
                              ],
                            ),
                          ],
                          sortOptions: [
                            SortOption<String>(
                              value: 'name',
                              labelKey: LocaleKeys.firstName,
                            ),
                            SortOption<String>(
                              value: 'date',
                              labelKey: LocaleKeys.birthdate,
                            ),
                          ],
                          onApply: (_, _) =>
                              context.feedback.toast(LocaleKeys.apply.tr()),
                          onReset: () =>
                              context.feedback.toast(LocaleKeys.reset.tr()),
                        ),
                      ),
                      _btn(
                        context,
                        LocaleKeys.deleteConfirmTitle.tr(),
                        () => AppConfirmDialog.show(
                          context,
                          titleKey: LocaleKeys.deleteConfirmTitle,
                          messageKey: LocaleKeys.deleteConfirmMessage,
                          isDestructive: true,
                          onConfirm: () => context.feedback.success(
                            LocaleKeys.deletedSuccessfully.tr(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Date & Time ───────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.calendar_month_rounded,
                  title:
                      '${LocaleKeys.dateMaterial.tr()} / ${LocaleKeys.timeMaterial.tr()}',
                ),
                AppCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _btn(context, LocaleKeys.dateMaterial.tr(), () async {
                        final d = await context.showDatePicker(
                          initDate: DateTime.now(),
                          mode: DatePickerDisplayMode.material,
                        );
                        if (context.mounted && d != null) {
                          context.feedback.toast(
                            '${d.day}/${d.month}/${d.year}',
                          );
                        }
                      }),
                      _btn(context, LocaleKeys.dateCalendar.tr(), () async {
                        final d = await context.showDatePicker(
                          initDate: DateTime.now(),
                          mode: DatePickerDisplayMode.calendar,
                        );
                        if (context.mounted && d != null) {
                          context.feedback.toast(
                            '${d.day}/${d.month}/${d.year}',
                          );
                        }
                      }),
                      _btn(
                        context,
                        LocaleKeys.timeMaterial.tr(),
                        () => context.showTimePicker(
                          initDate: DateTime.now(),
                          mode: TimePickerDisplayMode.material,
                          onSelect: (t) => context.feedback.toast(
                            '${t.hour}:${t.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── App States ────────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.toggle_on_rounded,
                  title: LocaleKeys.states.tr(),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.emptyState.tr(),
                        style: context.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 150,
                        child: EmptyStateWidget(titleKey: LocaleKeys.noItems),
                      ),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.errorRetry.tr(),
                        style: context.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 190,
                        child: ErrorStateWidget(
                          messageKey: LocaleKeys.somethingWrong,
                          onRetry: () =>
                              context.feedback.toast(LocaleKeys.retry.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.loading.tr(),
                        style: context.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      const SizedBox(height: 70, child: LoadingWidget()),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.noInternet.tr(),
                        style: context.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 190,
                        child: NoInternetWidget(
                          onRetry: () =>
                              context.feedback.toast(LocaleKeys.retry.tr()),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Inline Feedback States ────────────────────────────────────
                _SectionHeader(
                  icon: Icons.check_circle_outline_rounded,
                  title: LocaleKeys.feedback.tr(),
                ),
                AppCard(
                  child: Column(
                    children: [
                      SuccessStateWidget(messageKey: LocaleKeys.success),
                      const SizedBox(height: 12),
                      WarningStateWidget(messageKey: LocaleKeys.warning),
                      const SizedBox(height: 12),
                      InfoStateWidget(messageKey: LocaleKeys.info),
                    ],
                  ),
                ),

                // ── Skeleton Templates ────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.view_agenda_outlined,
                  title: LocaleKeys.skeletonTemplates.tr(),
                ),
                _SkeletonVariantSelector(
                  selected: _skeletonVariant,
                  onChanged: (v) => setState(() => _skeletonVariant = v),
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(_skeletonVariant),
                      child: _SkeletonPreview(variant: _skeletonVariant),
                    ),
                  ),
                ),

                // ── Placeholders (raw SkeletonWidget + ImagePlaceholder) ──────
                _SectionHeader(
                  icon: Icons.image_outlined,
                  title: LocaleKeys.placeholders.tr(),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonWidget(width: double.infinity, height: 14),
                      const SizedBox(height: 6),
                      const SkeletonWidget(width: 200, height: 14),
                      const SizedBox(height: 6),
                      const SkeletonWidget(width: 240, height: 14),
                      const SizedBox(height: 12),
                      const ImagePlaceholderWidget(size: 80),
                    ],
                  ),
                ),

                // ── Images & Avatars ──────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.person_rounded,
                  title: LocaleKeys.images.tr(),
                ),
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      AvatarWidget(initial: 'A', radius: 30),
                      AvatarWidget(
                        imageUrl:
                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSq22-qX2XIigf9NEEn13kxJ5f037oXYL5DZA&s',
                        radius: 30,
                      ),
                      AvatarWidget(initial: 'م ع', radius: 30),
                      ImagePlaceholderWidget(size: 60),
                    ],
                  ),
                ),

                // ── Text Inputs ───────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.edit_rounded,
                  title: LocaleKeys.textInputs.tr(),
                ),
                CustomTextField(
                  controller: _textCtrl,
                  labelText: LocaleKeys.fullName.tr(),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _passCtrl,
                  labelText: LocaleKeys.password.tr(),
                  isFieldObscure: true,
                ),
                const SizedBox(height: 8),
                AppSearchBar(
                  hint: context.isAr ? 'ابحث...' : 'Search...',
                  onSearch: (q) => context.feedback.toast('search: $q'),
                  onClear: () {},
                ),

                // ── Layout Widgets ────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.grid_view_rounded,
                  title: LocaleKeys.layout.tr(),
                ),
                SectionTitle(
                  titleKey: LocaleKeys.about,
                  trailing: TextButton(
                    onPressed: () =>
                        context.feedback.toast(LocaleKeys.about.tr()),
                    child: Text(LocaleKeys.about.tr()),
                  ),
                ),
                const DividerWidget(),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        LocaleKeys.login,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        inverseColor: true,
                      ),
                      Spacing.vertical8,
                      AppText(LocaleKeys.password),
                    ],
                  ),
                ),

                // ── Indicators ────────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.speed_rounded,
                  title: LocaleKeys.indicators.tr(),
                ),
                AppCard(
                  child: Column(
                    children: [
                      const SizedBox(height: 70, child: AppLoader()),
                      const SizedBox(height: 8),
                      ProgressIndicatorWidget(value: 0.9, linear: false),
                      ProgressIndicatorWidget(value: 0.9, linear: true),
                      ProgressIndicatorWidget(value: 0.5, linear: true),
                      ProgressIndicatorWidget(value: 0.2, linear: true),
                    ],
                  ),
                ),

                // ── Misc Widgets ──────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.widgets_rounded,
                  title: LocaleKeys.misc.tr(),
                ),
                AppCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppText(LocaleKeys.success, fontSize: 14),
                      TagWidget(labelKey: LocaleKeys.cancel),
                      ChipWidget(
                        labelKey: LocaleKeys.confirm,
                        selected: false,
                        onSelected: (_) {},
                      ),
                      BadgeWidget(
                        count: 3,
                        child: const Icon(Icons.notifications_rounded),
                      ),
                    ],
                  ),
                ),

                // ── Tab Navigation ────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.tab_rounded,
                  title: LocaleKeys.tabNavigation.tr(),
                ),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    height: 320,
                    child: AppTabBar(
                      type: AppTabBarType.top,
                      tabs: [
                        AppTabItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home,
                          label: LocaleKeys.tabHome.tr(),
                          body: Center(child: Text(LocaleKeys.tabHome.tr())),
                        ),
                        AppTabItem(
                          icon: Icons.search_outlined,
                          activeIcon: Icons.search,
                          label: context.isAr ? 'بحث' : 'Search',
                          body: Center(
                            child: Text(
                              context.isAr ? 'محتوى البحث' : 'Search content',
                            ),
                          ),
                        ),
                        AppTabItem(
                          icon: Icons.notifications_outlined,
                          activeIcon: Icons.notifications,
                          label: LocaleKeys.notifications.tr(),
                          badgeCount: 3,
                          body: Center(
                            child: Text(LocaleKeys.notifications.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Detail-screen vocabulary ──────────────────────────────────
                // The three widgets a detail screen is built from. Shown
                // together on purpose: their whole point is that every entity
                // renders identically, and what they replace is four private
                // copies that had already drifted apart.
                _SectionHeader(
                  icon: Icons.article_outlined,
                  title: LocaleKeys.detailWidgets.tr(),
                ),
                DetailHeaderCard(
                  title: LocaleKeys.detailWidgetsSampleTitle.tr(),
                  subtitle: 'sample@example.com',
                  leading: AvatarWidget(
                    initial: LocaleKeys.detailWidgetsSampleTitle.tr()[0],
                    radius: 28,
                  ),
                  tags: [
                    TagWidget(labelKey: LocaleKeys.active),
                    TagWidget(labelKey: LocaleKeys.systemDefault),
                  ],
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        context.feedback.toast(LocaleKeys.done.tr()),
                  ),
                  facts: [
                    DetailFact(
                      icon: Icons.alternate_email,
                      label: LocaleKeys.eMail.tr(),
                      value: 'sample@example.com',
                      forceLtr: true,
                    ),
                    // The editable variant — the control exists only when
                    // `onEdit` is passed, and is absent rather than disabled.
                    DetailFact(
                      icon: Icons.military_tech_outlined,
                      label: LocaleKeys.level.tr(),
                      value: '10',
                      hint: LocaleKeys.roleLevelHint.tr(),
                      onEdit: () => context.feedback.toast(LocaleKeys.done.tr()),
                      editTooltip: LocaleKeys.edit.tr(),
                    ),
                    // The case worth previewing: an ABSENT value, stated rather
                    // than dropped. A row that disappears cannot be told from
                    // one that failed to load, so a demo showing only populated
                    // facts proves nothing about the widget's actual job.
                    DetailFact(
                      icon: Icons.place_outlined,
                      label: LocaleKeys.address.tr(),
                      value: null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DetailSectionHeader(
                  icon: Icons.groups_outlined,
                  title: LocaleKeys.detailWidgetsSampleSection.tr(),
                  subtitle: LocaleKeys.detailWidgetsSampleSubtitle.tr(),
                  trailing: Text(
                    '4',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ),

                // ── Card variants ─────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.crop_square_rounded,
                  title: LocaleKeys.cardVariant.tr(),
                ),
                const _CardVariantDemo(),

                // ── List filtering (ListFilterBar) ────────────────────────────
                _SectionHeader(
                  icon: Icons.filter_list_rounded,
                  title: LocaleKeys.listFiltering.tr(),
                ),
                const _ListFilterBarDemo(),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Live mirror for [AppCardVariant] — the same content drawn both ways.
///
/// Side by side because the difference *is* the absence: `container` draws no
/// surface at all, and a single rendering cannot show that. Content which
/// paints its own background (like [DetailHeaderCard] above) needs this
/// variant, or it ends up inside a second visible card.
class _CardVariantDemo extends StatefulWidget {
  const _CardVariantDemo();

  @override
  State<_CardVariantDemo> createState() => _CardVariantDemoState();
}

class _CardVariantDemoState extends State<_CardVariantDemo> {
  AppCardVariant _variant = AppCardVariant.card;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<AppCardVariant>(
          segments: [
            ButtonSegment(
              value: AppCardVariant.card,
              label: Text(LocaleKeys.cardVariantCard.tr()),
            ),
            ButtonSegment(
              value: AppCardVariant.container,
              label: Text(LocaleKeys.cardVariantContainer.tr()),
            ),
          ],
          selected: {_variant},
          onSelectionChanged: (s) => setState(() => _variant = s.first),
        ),
        const SizedBox(height: 12),
        AppCard(
          variant: _variant,
          margin: EdgeInsets.zero,
          child: Text(
            LocaleKeys.cardVariantSample.tr(),
            style: context.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

/// Live mirror for [ListFilterBar] — the shared search + active-filter bar.
///
/// Both halves are exercised, because the interesting behaviour is the second:
/// toggling a filter shows how the chips appear, how the reserved height
/// changes with them (`heightFor`), and that clearing is offered beside what it
/// clears rather than back inside the filter sheet. A preview with nothing
/// active tests only the search box, which was never the risky part.
class _ListFilterBarDemo extends StatefulWidget {
  const _ListFilterBarDemo();

  @override
  State<_ListFilterBarDemo> createState() => _ListFilterBarDemoState();
}

class _ListFilterBarDemoState extends State<_ListFilterBarDemo> {
  String? _query;
  bool _statusFilter = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    // The search term is part of `activeFilters`, not separate from it:
    // leaving it out lets "no results" read as "nothing exists".
    final active = <String>[
      if (_query != null && _query!.isNotEmpty) '"$_query"',
      if (_statusFilter) LocaleKeys.active.tr(),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: ListFilterBar.heightFor(hasActiveFilters: active.isNotEmpty),
            child: ListFilterBar(
              hint: LocaleKeys.searchDemoHint.tr(),
              activeFilters: active,
              isLoading: _busy,
              onSearch: (q) => setState(() => _query = q),
              onClearSearch: () => setState(() => _query = null),
              onClearAll: () => setState(() {
                _query = null;
                _statusFilter = false;
              }),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text(LocaleKeys.active.tr()),
                selected: _statusFilter,
                onSelected: (v) => setState(() => _statusFilter = v),
              ),
              FilterChip(
                label: Text(LocaleKeys.loading.tr()),
                selected: _busy,
                onSelected: (v) => setState(() => _busy = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

Widget _btn(BuildContext context, String label, VoidCallback onTap) =>
    FilledButton.tonal(onPressed: onTap, child: Text(label));

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: context.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 15,
              color: context.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonVariantSelector extends StatelessWidget {
  const _SkeletonVariantSelector({
    required this.selected,
    required this.onChanged,
  });

  final _SkeletonVariant selected;
  final ValueChanged<_SkeletonVariant> onChanged;

  String _label(BuildContext context, _SkeletonVariant v) => switch (v) {
    _SkeletonVariant.listTile => LocaleKeys.skeletonListTile.tr(),
    _SkeletonVariant.card => LocaleKeys.skeletonCard.tr(),
    _SkeletonVariant.gridItem => LocaleKeys.skeletonGridItem.tr(),
    _SkeletonVariant.profile => LocaleKeys.skeletonProfile.tr(),
    _SkeletonVariant.statRow => LocaleKeys.skeletonStatRow.tr(),
  };

  @override
  Widget build(BuildContext context) {
    context.locale;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<_SkeletonVariant>(
        segments: _SkeletonVariant.values
            .map(
              (v) => ButtonSegment<_SkeletonVariant>(
                value: v,
                label: Text(_label(context, v)),
              ),
            )
            .toList(),
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonPreview extends StatelessWidget {
  const _SkeletonPreview({required this.variant});

  final _SkeletonVariant variant;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      _SkeletonVariant.listTile => const Column(
        children: [
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
        ],
      ),
      _SkeletonVariant.card => const Column(
        children: [SkeletonCard(), SkeletonCard(showImage: false, lines: 2)],
      ),
      _SkeletonVariant.gridItem => const Row(
        children: [
          Expanded(child: SkeletonGridItem()),
          Expanded(child: SkeletonGridItem()),
        ],
      ),
      _SkeletonVariant.profile => const SkeletonProfile(),
      _SkeletonVariant.statRow => const Column(
        children: [
          SkeletonStatRow(),
          SkeletonListTile(showAvatar: false, lines: 1),
          SkeletonListTile(showAvatar: false, lines: 1),
        ],
      ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackStyleSelector extends StatelessWidget {
  const _FeedbackStyleSelector({
    required this.selected,
    required this.onChanged,
  });

  final FeedbackStyle selected;
  final ValueChanged<FeedbackStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    context.locale;
    return SegmentedButton<FeedbackStyle>(
      expandedInsets: EdgeInsets.zero,
      segments: [
        ButtonSegment<FeedbackStyle>(
          value: FeedbackStyle.motionToast,
          icon: const Icon(Icons.dynamic_feed_rounded, size: 15),
          label: Text(context.isAr ? 'موشن' : 'Motion'),
        ),
        ButtonSegment<FeedbackStyle>(
          value: FeedbackStyle.snackbar,
          icon: const Icon(Icons.view_agenda_rounded, size: 15),
          label: Text(context.isAr ? 'سناك' : 'Snackbar'),
        ),
        ButtonSegment<FeedbackStyle>(
          value: FeedbackStyle.simpleToast,
          icon: const Icon(Icons.info_outline_rounded, size: 15),
          label: Text(context.isAr ? 'بسيط' : 'Simple'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
