import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────────────

enum AppTabBarType {
  /// NavigationBar at the bottom — للتنقل بين الشاشات الرئيسية
  bottom,

  /// TabBar at the top — للتبويب داخل شاشة واحدة
  top,
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTabItem — بيانات تبويبة واحدة
// ─────────────────────────────────────────────────────────────────────────────

class AppTabItem {
  const AppTabItem({
    required this.icon,
    required this.label,
    required this.body,
    this.activeIcon,
    this.badgeCount,
  });

  final IconData icon;

  /// أيقونة مختلفة عند التحديد (اختيارية — الافتراضي: نفس icon)
  final IconData? activeIcon;

  final String label;
  final Widget body;

  /// null أو 0 = لا يظهر Badge
  final int? badgeCount;

  bool get _hasBadge => badgeCount != null && badgeCount! > 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTabBar
// ─────────────────────────────────────────────────────────────────────────────

/// Widget موحّد للتنقل بالتبويب.
///
/// النوع [AppTabBarType.bottom]:
///   يُلفّ الشاشة كاملةً — ضعه مباشرةً كـ body في الـ route الجذر.
///
/// النوع [AppTabBarType.top]:
///   يحتاج مساحةً محدودة الارتفاع — اكتبه داخل [Expanded] أو [SizedBox].
///
/// ```dart
/// // Bottom navigation example
/// AppTabBar(
///   type: AppTabBarType.bottom,
///   tabs: [
///     AppTabItem(icon: Icons.home,    label: 'الرئيسية', body: HomeScreen()),
///     AppTabItem(icon: Icons.person,  label: 'الملف',    body: ProfileScreen()),
///     AppTabItem(icon: Icons.settings,label: 'الإعدادات', body: SettingsScreen(),
///                badgeCount: 3),
///   ],
/// )
///
/// // Top tab example (inside a screen)
/// Expanded(
///   child: AppTabBar(
///     type: AppTabBarType.top,
///     tabs: [
///       AppTabItem(icon: Icons.list,  label: 'الكل',    body: AllList()),
///       AppTabItem(icon: Icons.check, label: 'المنجزة', body: DoneList()),
///     ],
///   ),
/// )
/// ```
class AppTabBar extends StatefulWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    this.type = AppTabBarType.bottom,
    this.activeColor,
    this.inactiveColor,
    this.initialIndex = 0,
    this.onTabChanged,
  }) : assert(tabs.length >= 2, 'AppTabBar requires at least 2 tabs');

  final List<AppTabItem> tabs;
  final AppTabBarType type;

  /// لون التبويبة النشطة — الافتراضي: context.colors.primary
  final Color? activeColor;

  /// لون التبويبات الغير نشطة — الافتراضي: context.colors.textMuted
  final Color? inactiveColor;

  final int initialIndex;
  final ValueChanged<int>? onTabChanged;

  @override
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar>
    with SingleTickerProviderStateMixin {
  late int _activeIndex;
  late final TabController _tabController;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.initialIndex;
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (_activeIndex == index) return;
    setState(() => _activeIndex = index);
    widget.onTabChanged?.call(index);
    if (widget.type == AppTabBarType.bottom) {
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.type == AppTabBarType.bottom
        ? _BottomNav(
            tabs: widget.tabs,
            activeIndex: _activeIndex,
            pageController: _pageController,
            activeColor: widget.activeColor ?? context.colors.primary,
            inactiveColor: widget.inactiveColor ?? context.colors.textMuted,
            bgColor: context.colors.bgCard,
            onTap: _onTap,
          )
        : _TopTab(
            tabs: widget.tabs,
            tabController: _tabController,
            activeColor: widget.activeColor ?? context.colors.primary,
            inactiveColor: widget.inactiveColor ?? context.colors.textMuted,
            onTap: _onTap,
          );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomNav
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.activeIndex,
    required this.pageController,
    required this.activeColor,
    required this.inactiveColor,
    required this.bgColor,
    required this.onTap,
  });

  final List<AppTabItem> tabs;
  final int activeIndex;
  final PageController pageController;
  final Color activeColor;
  final Color inactiveColor;
  final Color bgColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        // Swipe مُعطَّل لأن NavigationBar لا تدعم الإيماءة الجانبية بشكل رسمي
        physics: const NeverScrollableScrollPhysics(),
        children: tabs.map((t) => t.body).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeIndex,
        backgroundColor: bgColor,
        indicatorColor: activeColor.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: onTap,
        destinations: tabs.map((tab) {
          return NavigationDestination(
            icon: _NavIcon(tab: tab, color: inactiveColor, isSelected: false),
            selectedIcon: _NavIcon(tab: tab, color: activeColor, isSelected: true),
            label: tab.label,
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopTab
// ─────────────────────────────────────────────────────────────────────────────

class _TopTab extends StatelessWidget {
  const _TopTab({
    required this.tabs,
    required this.tabController,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final List<AppTabItem> tabs;
  final TabController tabController;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: tabController,
          labelColor: activeColor,
          unselectedLabelColor: inactiveColor,
          indicatorColor: activeColor,
          onTap: onTap,
          tabs: tabs.map((tab) {
            return Tab(
              icon: tab._hasBadge
                  ? Badge(
                      label: Text('${tab.badgeCount}'),
                      child: Icon(tab.icon),
                    )
                  : Icon(tab.icon),
              text: tab.label,
            );
          }).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: tabs.map((t) => t.body).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavIcon — أيقونة NavigationDestination مع badge اختياري
// ─────────────────────────────────────────────────────────────────────────────

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.tab,
    required this.color,
    required this.isSelected,
  });

  final AppTabItem tab;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final iconData = isSelected ? (tab.activeIcon ?? tab.icon) : tab.icon;
    final icon = Icon(iconData, color: color);

    if (!tab._hasBadge) return icon;

    return Badge(
      label: Text('${tab.badgeCount}'),
      child: icon,
    );
  }
}
