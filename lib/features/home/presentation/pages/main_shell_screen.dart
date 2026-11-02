import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_template/features/home/presentation/cubits/navigation_cubit.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/widgets/dialogs/app_confirm_dialog.dart';
import 'package:app_template/ui/widgets/navigation/app_bottom_bar.dart';
import 'package:app_template/ui/widgets/navigation/nav_item.dart';
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
      // The shell blocks the pop (`canPop: false`) to ask first, so after a
      // yes nothing leaves on its own — the app has to say so. Android closes
      // the activity; iOS ignores it (apps do not quit themselves there, and
      // no system back reaches this dialog).
      await SystemNavigator.pop();
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
            child: ValueListenableBuilder<ShellAppearance>(
              valueListenable: ShellAppearance.notifier,
              builder: (context, look, _) => Scaffold(
                // The body ends at the bar's top edge — every tab screen sees
                // all of its content without a bottom inset of its own.
                // IndexedStack keeps each tab's state; AppTabSwitcher animates
                // the switch around it.
                body: AppTabSwitcher(
                  index: state.currentIndex,
                  transition: look.transition,
                  child: IndexedStack(
                    index: state.currentIndex,
                    children: items.map((e) => e.screenBuilder()).toList(),
                  ),
                ),
                bottomNavigationBar: AppBottomBar(
                  items: items,
                  currentIndex: state.currentIndex,
                  onTap: cubit.onItemTapped,
                  style: look.style,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
