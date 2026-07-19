import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:app_template/Features/home/presentation/cubits/navigation_cubit.dart';
import 'package:app_template/Features/home/presentation/pages/home_screen.dart';
import 'package:app_template/Features/auth/profile/presentation/pages/profile_screen.dart';
import 'package:app_template/Features/settings/presentation/pages/settings_screen.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/screens/main_shell_screen.dart';
import 'package:app_template/shared/widgets/navigation/nav_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Routable wrapper for [MainShellScreen].
///
/// Provides [NavigationCubit] and wires the three main tabs:
///   Home → Profile → Settings
@RoutePage()
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<NavigationCubit>(),
      child: MainShellScreen(
        items: [
          NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            labelKey: LocaleKeys.tabHome,
            screenBuilder: () => const HomeScreen(),
          ),
          NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            labelKey: LocaleKeys.tabProfile,
            screenBuilder: () => const ProfileScreen(),
          ),
          NavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            labelKey: LocaleKeys.tabSettings,
            screenBuilder: () => const SettingsScreen(),
          ),
        ],
      ),
    );
  }
}
