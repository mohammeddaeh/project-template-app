import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/ui/feedback/selection_haptic.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/navigation/nav_item.dart';

/// **الشريطُ الجانبيّ** — تبويباتُ القشرة نفسُها على شاشةٍ عرضُها ٨٤٠ فأكثر
/// (`context.screen.usesSideNavigation`): لوحٌ أفقيّ، حيث العرضُ وافرٌ والارتفاعُ
/// شحيح. وتحتها [AppBottomBar] — راجع `readme/ui/22_RESPONSIVE.md` §٤‑ج.
///
/// ```dart
/// Row(
///   children: [
///     BrandNavRail(items: items, currentIndex: i, onTap: cubit.onItemTapped),
///     Expanded(child: body),
///   ],
/// )
/// ```
///
/// أوّلَ `Row` يقع على **يمين** الشاشة بالعربية تلقائياً. والتبويباتُ والشارةُ
/// والاهتزازُ كما بالشريط السفلي، فلا شيء يتغيّر بتدوير الجهاز سوى المكان.
class BrandNavRail extends StatelessWidget {
  const BrandNavRail({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    // Background and the edge line on the box; NavigationRail keeps the system
    // inset itself (its own SafeArea) — test/brand_nav_rail_test.dart measures
    // the first tab below the status bar.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: BorderDirectional(end: BorderSide(color: colors.borderSubtle)),
      ),
      child: NavigationRail(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          // The current tab again is not a change, so it does not vibrate.
          if (index != currentIndex) selectionHaptic();
          onTap(index);
        },
        labelType: NavigationRailLabelType.all,
        backgroundColor: Colors.transparent,
        // ⛔ لا `elevation: 0` ولا `indicatorColor` مع `useIndicator: false` —
        // كلاهما `assert` يرسم شاشةً حمراء، ولا يظهر على هاتفٍ قطّ.
        indicatorColor: colors.primaryContainer,
        selectedIconTheme: IconThemeData(color: colors.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: colors.textSecondary),
        selectedLabelTextStyle: context.textTheme.labelMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: context.textTheme.labelMedium?.copyWith(
          color: colors.textSecondary,
        ),
        destinations: [
          for (final item in items)
            NavigationRailDestination(
              icon: _RailIcon(item: item, selected: false),
              selectedIcon: _RailIcon(item: item, selected: true),
              label: Text(item.labelKey.tr()),
            ),
        ],
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  const _RailIcon({required this.item, required this.selected});

  final NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(selected ? item.activeIcon : item.icon);
    final count = item.badgeCount;
    if (count == null) return icon;
    return Badge(
      label: count > 0 ? Text(count > 99 ? '99+' : '$count') : null,
      child: icon,
    );
  }
}
