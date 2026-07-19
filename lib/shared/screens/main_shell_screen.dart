import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/Features/home/presentation/cubits/navigation_cubit.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/dialogs/app_confirm_dialog.dart';
import 'package:app_template/shared/widgets/navigation/nav_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// الشاشة الحاضنة لشريط التنقل السفلي.
///
/// **الاستخدام:**
/// ```dart
/// // في app_router.dart — ShellRoute أو كشاشة جذر
/// MainShellScreen(
///   items: [
///     NavItem(
///       icon: Icons.home_outlined,
///       activeIcon: Icons.home,
///       labelKey: LocaleKeys.tabHome,
///       screenBuilder: () => const HomeScreen(),
///     ),
///     NavItem(
///       icon: Icons.person_outline,
///       activeIcon: Icons.person,
///       labelKey: LocaleKeys.tabProfile,
///       screenBuilder: () => const ProfileScreen(),
///     ),
///   ],
/// )
/// ```
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, required this.items});

  final List<NavItem> items;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NavigationCubit>().setItems(widget.items);
  }

  // ── Exit Dialog ──────────────────────────────────────────────────────────

  Future<void> _handleExitDialog(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.exitAppTitle,
      messageKey: LocaleKeys.exitAppMessage,
      confirmKey: LocaleKeys.confirm,
      cancelKey: LocaleKeys.cancel,
      isDestructive: false,
      barrierDismissible: true,
    );
    if (!context.mounted) return;
    if (confirmed) {
      context.read<NavigationCubit>().confirmExit();
    } else {
      context.read<NavigationCubit>().dismissExitDialog();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationCubit, NavigationState>(
      listenWhen: (prev, curr) => !prev.showExitDialog && curr.showExitDialog,
      listener: (context, _) => _handleExitDialog(context),
      child: BlocBuilder<NavigationCubit, NavigationState>(
        builder: (context, state) {
          // ignore: unnecessary_statements — registers EasyLocalization dependency so .tr() labels rebuild on locale change
          context.locale;
          final cubit = context.read<NavigationCubit>();
          final items = cubit.visibleItems;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) => cubit.onBackPressed(),
            child: Scaffold(
              // extendBody: الـ body يمتد خلف NavigationBar في وضع edge-to-edge.
              // المحتوى محمي عبر SafeArea داخل كل شاشة فرعية.
              extendBody: true,
              // IndexedStack يحفظ حالة كل شاشة عند التبديل بين التبويبات
              body: IndexedStack(
                index: state.currentIndex,
                children: items.map((e) => e.screenBuilder()).toList(),
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: state.currentIndex,
                onDestinationSelected: cubit.onItemTapped,
                destinations: items.map((item) {
                  return NavigationDestination(
                    icon: _buildIcon(item, isSelected: false),
                    selectedIcon: _buildIcon(item, isSelected: true),
                    label: item.labelKey.tr(),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIcon(NavItem item, {required bool isSelected}) {
    final icon = Icon(isSelected ? item.activeIcon : item.icon);
    if (item.badgeCount == null) return icon;

    return Badge(
      label: item.badgeCount! > 0 ? Text(item.badgeCount!.toString()) : null,
      child: icon,
    );
  }
}
