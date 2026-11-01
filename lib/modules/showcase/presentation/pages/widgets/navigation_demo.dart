import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/playground_tokens.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Tabs, the app bar, a miniature shell built from [NavItem]s, the step
/// indicator and the spotlight guide — each in a fixed box so it can be tried
/// without leaving the page, with its options as controls.
class NavigationDemo extends StatefulWidget {
  const NavigationDemo({super.key});

  @override
  State<NavigationDemo> createState() => _NavigationDemoState();
}

class _NavigationDemoState extends State<NavigationDemo> {
  final _guideTarget = GlobalKey();
  int _navIndex = 0;

  /// The shell's tabs as data — the real shell reads the same class.
  late final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.inbox_outlined,
      activeIcon: Icons.inbox,
      labelKey: LocaleKeys.showcaseNavigationInbox,
      badgeCount: 3,
      screenBuilder: () => const _TabBody(LocaleKeys.showcaseNavigationInbox),
    ),
    NavItem(
      icon: Icons.archive_outlined,
      activeIcon: Icons.archive,
      labelKey: LocaleKeys.showcaseNavigationArchive,
      screenBuilder: () => const _TabBody(LocaleKeys.showcaseNavigationArchive),
    ),
    NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      labelKey: LocaleKeys.showcaseNavigationProfile,
      screenBuilder: () => const _TabBody(LocaleKeys.showcaseNavigationProfile),
    ),
  ];

  /// Up to four sample tabs; the first carries a badge and an active icon.
  static const _tabSamples = [
    (Icons.inbox_outlined, Icons.inbox, LocaleKeys.showcaseNavigationInbox, 2),
    (
      Icons.archive_outlined,
      Icons.archive,
      LocaleKeys.showcaseNavigationArchive,
      null,
    ),
    (
      Icons.person_outline,
      Icons.person,
      LocaleKeys.showcaseNavigationProfile,
      null,
    ),
    (Icons.settings_outlined, Icons.settings, LocaleKeys.settings, null),
  ];

  List<AppTabItem> _tabs(int count) => [
    for (final (icon, active, key, badge) in _tabSamples.take(count))
      AppTabItem(
        icon: icon,
        activeIcon: active,
        label: key.tr(),
        badgeCount: badge,
        body: _TabBody(key),
      ),
  ];

  void _say(String key) => context.feedback.info(key.tr());

  List<Widget> _actions(int count) => [
    if (count >= 1)
      IconButton(
        tooltip: LocaleKeys.showcaseAdd.tr(),
        onPressed: () => _say(LocaleKeys.showcaseAdd),
        icon: const Icon(Icons.add),
      ),
    if (count >= 2)
      IconButton(
        tooltip: LocaleKeys.showcaseNavigationSearch.tr(),
        onPressed: () => _say(LocaleKeys.showcaseNavigationSearch),
        icon: const Icon(Icons.search),
      ),
  ];

  static const _actionCodes = <String, int>{
    'null': 0,
    '[IconButton(…)]': 1,
    '[IconButton(…), IconButton(…)]': 2,
  };

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final visible = _navItems.where((i) => i.isVisible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── AppTabBar ───────────────────────────────────────────────────────
        DemoPlayground(
          call: 'AppTabBar',
          knobs: [
            ChoiceKnob<int>('tabs', const {
              '[AppTabItem(…) × 2]': 2,
              '[AppTabItem(…) × 3]': 3,
              '[AppTabItem(…) × 4]': 4,
            }, required: true),
            EnumKnob('type', AppTabBarType.values, AppTabBarType.bottom),
            const NumberKnob(
              'initialIndex',
              initial: 0,
              min: 0,
              max: 3,
              integer: true,
              apiDefault: 0,
            ),
            colorKnob('activeColor', const ['secondary', 'error']),
            colorKnob('inactiveColor', const ['borderSubtle', 'textPrimary']),
            callbackKnob('onTabChanged', code: '(i) => toast(…)'),
          ],
          builder: (context, k) {
            final count = k<int>('tabs');
            final type = k<AppTabBarType>('type');
            // An index past the last tab is out of range — kept on the last.
            final index = k<double>('initialIndex').round().clamp(0, count - 1);
            return _Framed(
              height: 200,
              child: AppTabBar(
                // The tab controller is made once — a new shape starts afresh.
                key: ValueKey('$type-$count-$index'),
                type: type,
                tabs: _tabs(count),
                initialIndex: index,
                activeColor: tokenColor(context, k('activeColor')),
                inactiveColor: tokenColor(context, k('inactiveColor')),
                onTabChanged: k('onTabChanged')
                    ? (i) => context.feedback.info(
                        LocaleKeys.showcaseNavigationTabChanged.tr(
                          args: ['$i'],
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
        // ── AppNavBar ───────────────────────────────────────────────────────
        DemoPlayground(
          call: 'AppNavBar',
          knobs: [
            TextKnob(
              'titleText',
              initial: LocaleKeys.showcaseNavigationInbox.tr(),
            ),
            // null = automatic: shown when the route can go back.
            ChoiceKnob<bool?>(
              'showBackButton',
              const {'null': null, 'true': true, 'false': false},
              initialCode: 'true',
              apiDefaultCode: 'null',
            ),
            // Without one, back pops — here that would leave the tour.
            callbackKnob('onBack', code: '() => toast(…)'),
            ChoiceKnob<IconData?>('leading', const {
              'null': null,
              'Icon(Icons.menu)': Icons.menu,
            }, apiDefaultCode: 'null'),
            ChoiceKnob<int>(
              'actions',
              _actionCodes,
              initialCode: '[IconButton(…)]',
              apiDefaultCode: 'null',
            ),
            const BoolKnob('centerTitle', initial: true, apiDefault: true),
            const NumberKnob(
              'elevation',
              initial: 0,
              min: 0,
              max: 8,
              integer: true,
              apiDefault: 0,
            ),
            colorKnob('backgroundColor', const [
              'bgNeutral',
              'primaryContainer',
            ]),
          ],
          builder: (context, k) {
            final leading = k<IconData?>('leading');
            final actions = k<int>('actions');
            return _Framed(
              height: kToolbarHeight,
              child: AppNavBar(
                titleText: k('titleText'),
                showBackButton: k('showBackButton'),
                onBack: k('onBack')
                    ? () => _say(LocaleKeys.showcaseBack)
                    : null,
                leading: leading == null ? null : Icon(leading),
                actions: actions == 0 ? null : _actions(actions),
                centerTitle: k('centerTitle'),
                elevation: k('elevation'),
                backgroundColor: tokenColor(context, k('backgroundColor')),
              ),
            );
          },
        ),
        DemoPlayground(
          call: 'AppNavBar.root',
          knobs: [
            TextKnob(
              'titleText',
              initial: LocaleKeys.showcaseNavigationArchive.tr(),
            ),
            ChoiceKnob<int>('actions', _actionCodes, apiDefaultCode: 'null'),
            colorKnob('backgroundColor', const [
              'bgNeutral',
              'primaryContainer',
            ]),
          ],
          // A root screen has no back button, whatever the route can do.
          builder: (context, k) {
            final actions = k<int>('actions');
            return _Framed(
              height: kToolbarHeight,
              child: AppNavBar.root(
                titleText: k('titleText'),
                actions: actions == 0 ? null : _actions(actions),
                backgroundColor: tokenColor(context, k('backgroundColor')),
              ),
            );
          },
        ),
        DemoBlock(
          code:
              'Scaffold(appBar: AppNavBar(…), body: navItems[i]'
              '.screenBuilder()) — NavItem',
          child: _Framed(
            height: 280,
            child: Scaffold(
              appBar: AppNavBar(
                titleKey: visible[_navIndex].labelKey,
                showBackButton: true,
                onBack: () => _say(LocaleKeys.showcaseBack),
                actions: _actions(1),
              ),
              body: visible[_navIndex].screenBuilder(),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _navIndex,
                onDestinationSelected: (i) => setState(() => _navIndex = i),
                destinations: [
                  for (final item in visible)
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: (item.badgeCount ?? 0) > 0,
                        label: Text('${item.badgeCount}'),
                        child: Icon(item.icon),
                      ),
                      selectedIcon: Icon(item.activeIcon),
                      label: item.labelKey.tr(),
                    ),
                ],
              ),
            ),
          ),
        ),
        // ── StepProgressIndicator ───────────────────────────────────────────
        DemoPlayground(
          call: 'StepProgressIndicator',
          knobs: [
            const NumberKnob(
              'currentStep',
              initial: 2,
              min: 1,
              max: 8,
              integer: true,
              required: true,
            ),
            const NumberKnob(
              'totalSteps',
              initial: 4,
              min: 2,
              max: 8,
              integer: true,
              required: true,
            ),
            EnumKnob(
              'type',
              StepIndicatorType.values,
              StepIndicatorType.numbered,
            ),
            callbackKnob(
              'stepLabelResolver',
              code: "(s) => 'Step \$s'",
              initial: false,
            ),
            colorKnob('activeColor', const ['secondary', 'feedbackSuccess']),
            colorKnob('inactiveColor', const ['bgNeutral', 'textPrimary']),
          ],
          builder: (context, k) {
            final current = k<double>('currentStep').round();
            final total = k<double>('totalSteps').round();
            // The widget asserts the range — say so rather than draw a lie.
            if (current > total) {
              return Text(
                LocaleKeys.showcaseNavigationStepRange.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.error,
                ),
              );
            }
            return StepProgressIndicator(
              currentStep: current,
              totalSteps: total,
              type: k('type'),
              stepLabelResolver: k('stepLabelResolver')
                  ? (s) => LocaleKeys.showcaseStep.tr(args: ['$s'])
                  : null,
              activeColor: tokenColor(context, k('activeColor')),
              inactiveColor: tokenColor(context, k('inactiveColor')),
            );
          },
        ),
        // ── GuideOverlay ────────────────────────────────────────────────────
        DemoPlayground(
          call: 'GuideOverlay.show',
          knobs: const [
            NumberKnob(
              'holePadding',
              initial: 8,
              min: 0,
              max: 24,
              integer: true,
              apiDefault: 8,
            ),
            NumberKnob(
              'holeRadius',
              initial: 12,
              min: 0,
              max: 40,
              integer: true,
              apiDefault: 12,
            ),
          ],
          // Named arguments may come before the positional context.
          trailingCode: const [
            'context',
            'targetKey: key',
            'title: …',
            'message: …',
            'actionLabel: …',
          ],
          builder: (context, k) => Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                key: _guideTarget,
                size: 40,
                color: context.colors.primary,
              ),
              16.widthBox,
              Expanded(
                child: AppButton(
                  text: LocaleKeys.showcaseNavigationGuideShow.tr(),
                  onTap: () => GuideOverlay.show(
                    context,
                    targetKey: _guideTarget,
                    title: LocaleKeys.showcaseNavigationGuideTitle.tr(),
                    message: LocaleKeys.showcaseNavigationGuideMessage.tr(),
                    actionLabel: LocaleKeys.done.tr(),
                    holePadding: k('holePadding'),
                    holeRadius: k('holeRadius'),
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

/// A fixed-height, outlined frame — a scaffold needs a bounded box.
class _Framed extends StatelessWidget {
  const _Framed({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.borderSubtle),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(height: height, child: child),
    ),
  );
}

class _TabBody extends StatelessWidget {
  const _TabBody(this.labelKey);

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    return Center(
      child: Text(
        labelKey.tr(),
        style: context.textTheme.titleMedium?.copyWith(
          color: context.colors.textMuted,
        ),
      ),
    );
  }
}
