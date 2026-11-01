import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/navigation/nav_item.dart';

/// How the bottom bar draws its tabs.
enum AppBottomBarStyle {
  /// Material 3 `NavigationBar`: every label, a pill behind the active icon.
  material,

  /// A rounded bar lifted off the screen edge; the active pill slides between
  /// tabs.
  floating,

  /// Icons only, and the active tab grows into a pill with its label.
  expanding,

  /// Icons only, a dot under the active one; labels reach screen readers.
  minimal,
}

/// How the body changes when the tab changes.
enum AppTabTransition {
  /// Material «fade through»: the old tab fades out, the new one fades and
  /// scales in.
  fadeThrough,

  /// The new tab slides in from the side of the tab it came from.
  sharedAxis,

  /// A plain cross-fade.
  fade,

  /// Switch at once.
  none,
}

/// The shell's bottom bar and tab transition — **one place to choose them**.
///
/// The defaults are the two lines below; the app's shell listens to [notifier],
/// so a screen (the showcase, a settings page) can change them while the app
/// runs.
///
/// ```dart
/// ShellAppearance.notifier.value =
///     const ShellAppearance(style: AppBottomBarStyle.floating);
/// ```
@immutable
class ShellAppearance {
  const ShellAppearance({
    this.style = AppBottomBarStyle.material,
    this.transition = AppTabTransition.fadeThrough,
  });

  final AppBottomBarStyle style;
  final AppTabTransition transition;

  static final ValueNotifier<ShellAppearance> notifier = ValueNotifier(
    const ShellAppearance(),
  );

  ShellAppearance copyWith({
    AppBottomBarStyle? style,
    AppTabTransition? transition,
  }) => ShellAppearance(
    style: style ?? this.style,
    transition: transition ?? this.transition,
  );

  @override
  bool operator ==(Object other) =>
      other is ShellAppearance &&
      other.style == style &&
      other.transition == transition;

  @override
  int get hashCode => Object.hash(style, transition);
}

/// **The bottom navigation bar**, in one of [AppBottomBarStyle]'s styles.
///
/// ```dart
/// AppBottomBar(
///   items: items,
///   currentIndex: state.currentIndex,
///   onTap: cubit.onItemTapped,
///   style: AppBottomBarStyle.floating,
/// )
/// ```
///
/// Every style keeps the same contract: the system gesture bar is padded
/// below it, a [NavItem.badgeCount] shows on its icon (`0` is a dot), and each
/// tab is a labelled button for screen readers even when its label is not
/// drawn.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.style = AppBottomBarStyle.material,
    super.key,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppBottomBarStyle style;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    return switch (style) {
      AppBottomBarStyle.material => NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        animationDuration: AppMotion.of(context).base,
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: _BadgedIcon(item: item, selected: false),
              selectedIcon: _BadgedIcon(item: item, selected: true),
              label: item.labelKey.tr(),
            ),
        ],
      ),
      AppBottomBarStyle.floating => _FloatingBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap,
      ),
      AppBottomBarStyle.expanding => _FlatBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap,
        expanding: true,
      ),
      AppBottomBarStyle.minimal => _FlatBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap,
        expanding: false,
      ),
    };
  }
}

/// The body's tab switch, animated by [transition] — around an
/// `IndexedStack`, so no tab loses its state.
class AppTabSwitcher extends StatefulWidget {
  const AppTabSwitcher({
    required this.index,
    required this.child,
    this.transition = AppTabTransition.fadeThrough,
    super.key,
  });

  final int index;
  final AppTabTransition transition;

  /// The `IndexedStack` of the tabs.
  final Widget child;

  @override
  State<AppTabSwitcher> createState() => _AppTabSwitcherState();
}

class _AppTabSwitcherState extends State<AppTabSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppMotion.base,
    value: 1,
  );

  /// +1 when the new tab is to the end of the old one, −1 to the start.
  double _direction = 1;

  @override
  void didUpdateWidget(AppTabSwitcher old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _direction = widget.index > old.index ? 1 : -1;
    final motion = AppMotion.of(context);
    if (widget.transition == AppTabTransition.none || motion.isReduced) {
      _ctrl.value = 1;
      return;
    }
    _ctrl.duration = motion.base;
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _ctrl, curve: AppMotion.baseCurve);
    return switch (widget.transition) {
      AppTabTransition.none => widget.child,
      AppTabTransition.fade => FadeTransition(
        opacity: curved,
        child: widget.child,
      ),
      AppTabTransition.fadeThrough => FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(curved),
          child: widget.child,
        ),
      ),
      AppTabTransition.sharedAxis => AnimatedBuilder(
        animation: curved,
        child: widget.child,
        builder: (context, child) {
          // «Start» follows the reading direction.
          final rtl = Directionality.of(context) == TextDirection.rtl;
          final dx = (1 - curved.value) * 0.12 * _direction * (rtl ? -1 : 1);
          return FractionalTranslation(
            translation: Offset(dx, 0),
            child: Opacity(opacity: curved.value, child: child),
          );
        },
      ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.item, required this.selected, this.color});

  final NavItem item;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(selected ? item.activeIcon : item.icon, color: color);
    final count = item.badgeCount;
    if (count == null) return icon;
    return Badge(
      label: count > 0 ? Text(count > 99 ? '99+' : '$count') : null,
      child: icon,
    );
  }
}

/// A tab as a button that names itself, whatever is drawn.
class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: item.labelKey.tr(),
    excludeSemantics: true,
    child: InkResponse(onTap: onTap, radius: 32, child: child),
  );
}

class _FloatingBar extends StatelessWidget {
  const _FloatingBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = AppMotion.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final n = items.length;
    // -1 … 1 across the bar, mirrored for right-to-left.
    final x = n == 1 ? 0.0 : (currentIndex / (n - 1) * 2 - 1) * (rtl ? -1 : 1);

    return ColoredBox(
      color: colors.bgPage,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: AppRadius.pillRadius,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              height: 64,
              child: LayoutBuilder(
                builder: (context, box) => Stack(
                  children: [
                    AnimatedAlign(
                      duration: motion.base,
                      curve: AppMotion.baseCurve,
                      alignment: Alignment(x, 0),
                      child: Container(
                        width: box.maxWidth / n - 12,
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: AppRadius.lgRadius,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < n; i++)
                          Expanded(
                            child: _TabButton(
                              item: items[i],
                              selected: i == currentIndex,
                              onTap: () => onTap(i),
                              child: _IconOverLabel(
                                item: items[i],
                                selected: i == currentIndex,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconOverLabel extends StatelessWidget {
  const _IconOverLabel({required this.item, required this.selected});

  final NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.onPrimaryContainer : colors.textMuted;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BadgedIcon(item: item, selected: selected, color: color),
        const SizedBox(height: 2),
        Text(
          item.labelKey.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// [AppBottomBarStyle.expanding] and [AppBottomBarStyle.minimal].
class _FlatBar extends StatelessWidget {
  const _FlatBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.expanding,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool expanding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tabs = [
      for (var i = 0; i < items.length; i++)
        _FlatTab(
          item: items[i],
          selected: i == currentIndex,
          onTap: () => onTap(i),
          expanding: expanding,
        ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: expanding
              // Idle tabs keep their icon's width, so the selected one has
              // the rest for its label — equal shares leave it none.
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      if (i == currentIndex)
                        Flexible(child: tabs[i])
                      else
                        tabs[i],
                  ],
                )
              : Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(child: Center(child: tabs[i])),
                  ],
                ),
        ),
      ),
    );
  }
}

class _FlatTab extends StatelessWidget {
  const _FlatTab({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.expanding,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool expanding;

  @override
  Widget build(BuildContext context) => _TabButton(
    item: item,
    selected: selected,
    onTap: onTap,
    child: expanding
        ? _ExpandingTab(item: item, selected: selected)
        : _DotTab(item: item, selected: selected),
  );
}

class _ExpandingTab extends StatelessWidget {
  const _ExpandingTab({required this.item, required this.selected});

  final NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = AppMotion.of(context);
    final color = selected ? colors.onPrimaryContainer : colors.textMuted;
    return AnimatedContainer(
      duration: motion.base,
      curve: AppMotion.baseCurve,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? colors.primaryContainer : Colors.transparent,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BadgedIcon(item: item, selected: selected, color: color),
          // Shrinks to an ellipsis when the tabs leave it too little room.
          Flexible(
            child: AnimatedSize(
              duration: motion.base,
              curve: AppMotion.baseCurve,
              child: selected
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: Text(
                        item.labelKey.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotTab extends StatelessWidget {
  const _DotTab({required this.item, required this.selected});

  final NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = AppMotion.of(context);
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            duration: motion.fast,
            scale: selected ? 1.12 : 1,
            child: _BadgedIcon(
              item: item,
              selected: selected,
              color: selected ? colors.primary : colors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: motion.base,
            curve: AppMotion.baseCurve,
            width: selected ? 6 : 0,
            height: 6,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
