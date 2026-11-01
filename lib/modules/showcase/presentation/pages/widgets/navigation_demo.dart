import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Tabs, the app bar, a miniature shell built from [NavItem]s, the step
/// indicator and the spotlight guide — each in a fixed box so it can be tried
/// without leaving the page.
class NavigationDemo extends StatefulWidget {
  const NavigationDemo({super.key});

  @override
  State<NavigationDemo> createState() => _NavigationDemoState();
}

class _NavigationDemoState extends State<NavigationDemo> {
  final _guideTarget = GlobalKey();
  int _navIndex = 0;
  int _step = 2;

  static const _steps = 4;

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

  List<AppTabItem> get _tabs => [
    AppTabItem(
      icon: Icons.inbox_outlined,
      activeIcon: Icons.inbox,
      label: LocaleKeys.showcaseNavigationInbox.tr(),
      badgeCount: 2,
      body: const _TabBody(LocaleKeys.showcaseNavigationInbox),
    ),
    AppTabItem(
      icon: Icons.archive_outlined,
      activeIcon: Icons.archive,
      label: LocaleKeys.showcaseNavigationArchive.tr(),
      body: const _TabBody(LocaleKeys.showcaseNavigationArchive),
    ),
  ];

  void _showGuide() => GuideOverlay.show(
    context,
    targetKey: _guideTarget,
    title: LocaleKeys.showcaseNavigationGuideTitle.tr(),
    message: LocaleKeys.showcaseNavigationGuideMessage.tr(),
    actionLabel: LocaleKeys.done.tr(),
  );

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final visible = _navItems.where((i) => i.isVisible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final type in AppTabBarType.values)
          DemoBlock(
            code:
                'AppTabBar(type: AppTabBarType.${type.name}, tabs: '
                '[AppTabItem(…)])',
            child: _Framed(
              height: 200,
              child: AppTabBar(type: type, tabs: _tabs),
            ),
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
                onBack: () =>
                    context.feedback.info(LocaleKeys.showcaseBack.tr()),
                actions: [
                  IconButton(
                    tooltip: LocaleKeys.showcaseAdd.tr(),
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                  ),
                ],
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
        DemoBlock(
          code: 'AppNavBar.root(titleKey: …) — no back button',
          child: _Framed(
            height: kToolbarHeight,
            child: AppNavBar.root(titleKey: LocaleKeys.showcaseNavigationInbox),
          ),
        ),
        DemoBlock(
          code: 'StepProgressIndicator(type: StepIndicatorType.…)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final type in StepIndicatorType.values) ...[
                StepProgressIndicator(
                  currentStep: _step,
                  totalSteps: _steps,
                  type: type,
                  // Labels under the dots; numbered circles already say it.
                  stepLabelResolver: type == StepIndicatorType.dots
                      ? (s) => LocaleKeys.showcaseStep.tr(args: ['$s'])
                      : null,
                ),
                16.heightBox,
              ],
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: LocaleKeys.showcaseBack.tr(),
                      variant: AppButtonVariant.outlined,
                      isEnabled: _step > 1,
                      onTap: () => setState(() => _step--),
                    ),
                  ),
                  12.widthBox,
                  Expanded(
                    child: AppButton(
                      text: LocaleKeys.showcaseNext.tr(),
                      isEnabled: _step < _steps,
                      onTap: () => setState(() => _step++),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'GuideOverlay.show(context, targetKey: …, title: …)',
          child: Row(
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
                  onTap: _showGuide,
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
