import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The bottom bar's styles and the tab transitions — in a phone frame to play
/// with, then applied to the app's own bar while it runs.
class BottomBarDemo extends StatelessWidget {
  const BottomBarDemo({super.key});

  static const _tabs = [
    (Icons.home_outlined, Icons.home, LocaleKeys.tabHome),
    (Icons.search, Icons.search, LocaleKeys.showcaseBottomBarExplore),
    (Icons.favorite_outline, Icons.favorite, LocaleKeys.showcaseBottomBarSaved),
    (Icons.person_outline, Icons.person, LocaleKeys.tabProfile),
    (Icons.settings_outlined, Icons.settings, LocaleKeys.tabSettings),
  ];

  static List<NavItem> _items(int count, double badge) => [
    for (var i = 0; i < count; i++)
      NavItem(
        icon: _tabs[i].$1,
        activeIcon: _tabs[i].$2,
        labelKey: _tabs[i].$3,
        screenBuilder: () => const SizedBox(),
        badgeCount: i == 1 && badge >= 0 ? badge.round() : null,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoPlayground(
          call: 'ShellAppearance',
          knobs: [
            EnumKnob(
              'style',
              AppBottomBarStyle.values,
              AppBottomBarStyle.material,
            ),
            EnumKnob(
              'transition',
              AppTabTransition.values,
              AppTabTransition.fadeThrough,
            ),
            const BoolKnob('translucent'),
            const NumberKnob(
              'tabs',
              initial: 4,
              min: 2,
              max: 5,
              integer: true,
              inCall: false,
            ),
            const NumberKnob(
              'badge',
              initial: 3,
              min: -1,
              max: 12,
              integer: true,
              inCall: false,
            ),
          ],
          builder: (context, k) => _PhoneFrame(
            style: k('style'),
            transition: k('transition'),
            translucent: k('translucent'),
            items: _items(k<double>('tabs').round(), k('badge')),
          ),
        ),
        const DemoBlock(
          code: 'ShellAppearance.notifier.value = …',
          child: _ApplyToApp(),
        ),
      ],
    );
  }
}

/// A small screen with a real [AppBottomBar] and [AppTabSwitcher].
class _PhoneFrame extends StatefulWidget {
  const _PhoneFrame({
    required this.style,
    required this.transition,
    required this.translucent,
    required this.items,
  });

  final AppBottomBarStyle style;
  final AppTabTransition transition;
  final bool translucent;
  final List<NavItem> items;

  @override
  State<_PhoneFrame> createState() => _PhoneFrameState();
}

class _PhoneFrameState extends State<_PhoneFrame> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final index = _index.clamp(0, widget.items.length - 1);
    return ClipRRect(
      borderRadius: AppRadius.lgRadius,
      // The frame sits mid-page: the device's system-bar inset is not its own.
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: SizedBox(
          height: 320,
          child: Scaffold(
            backgroundColor: colors.bgPage,
            extendBody: widget.translucent,
            body: AppTabSwitcher(
              index: index,
              transition: widget.transition,
              child: IndexedStack(
                index: index,
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    _TabBody(
                      labelKey: widget.items[i].labelKey,
                      icon: widget.items[i].activeIcon,
                    ),
                ],
              ),
            ),
            bottomNavigationBar: AppBottomBar(
              items: widget.items,
              currentIndex: index,
              onTap: (i) => setState(() => _index = i),
              style: widget.style,
              translucent: widget.translucent,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.labelKey, required this.icon});

  final String labelKey;
  final IconData icon;

  /// A list long enough to scroll under the bar — a translucent bar shows
  /// nothing over an empty page.
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Icon(icon, size: 48, color: context.colors.textMuted),
      const SizedBox(height: 8),
      Text(
        labelKey.tr(),
        style: context.textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      for (var i = 0; i < 8; i++)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: i.isEven
                  ? context.colors.primaryContainer
                  : context.colors.bgCard,
              borderRadius: AppRadius.mdRadius,
            ),
          ),
        ),
    ],
  );
}

/// Applies the chosen look to the app's own bar — try it, then switch tabs.
class _ApplyToApp extends StatelessWidget {
  const _ApplyToApp();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ShellAppearance>(
    valueListenable: ShellAppearance.notifier,
    builder: (context, look, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKeys.showcaseBottomBarApplyHint.tr(),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChipRow<AppBottomBarStyle>(
                items: AppBottomBarStyle.values,
                labelResolver: (s) => s.name,
                selectedValue: look.style,
                onSelected: (s) {
                  if (s != null) {
                    ShellAppearance.notifier.value = look.copyWith(style: s);
                  }
                },
              ),
              const SizedBox(height: 8),
              ChipRow<AppTabTransition>(
                items: AppTabTransition.values,
                labelResolver: (t) => t.name,
                selectedValue: look.transition,
                onSelected: (t) {
                  if (t != null) {
                    ShellAppearance.notifier.value = look.copyWith(
                      transition: t,
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              ChipRow<bool>(
                items: const [false, true],
                labelResolver: (t) => 'translucent: $t',
                selectedValue: look.translucent,
                onSelected: (t) {
                  if (t != null) {
                    ShellAppearance.notifier.value = look.copyWith(
                      translucent: t,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
