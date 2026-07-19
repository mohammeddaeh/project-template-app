import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

import '../offline_ux_cubit.dart';

/// Animated banner displayed at the top (or bottom) of a screen when the device
/// is offline or has pending unsynced changes.
///
/// Place inside [SyncUiHost] or wrap manually:
/// ```dart
/// Column(children: [
///   const SyncStatusBanner(),
///   Expanded(child: child),
/// ])
/// ```
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({
    super.key,
    this.position = BannerPosition.top,
  });

  final BannerPosition position;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfflineUxCubit, OfflineUxState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            final offset = position == BannerPosition.top
                ? const Offset(0, -1)
                : const Offset(0, 1);
            return SlideTransition(
              position: animation.drive(
                Tween(begin: offset, end: Offset.zero).chain(
                  CurveTween(curve: Curves.easeOut),
                ),
              ),
              child: child,
            );
          },
          child: switch (state) {
            OfflineState() => _BannerTile(
                key: const ValueKey('offline'),
                icon: Icons.cloud_off_rounded,
                message: LocaleKeys.noInternetConnection.tr(),
                color: context.colors.stateError,
                onColor: context.colors.onErrorContainer,
              ),
            PendingChangesState(:final pendingCount) => _BannerTile(
                key: const ValueKey('pending'),
                icon: Icons.sync_rounded,
                message: '$pendingCount pending changes — will sync when online',
                color: context.colors.statusWarningFg,
                onColor: context.colors.textPrimary,
              ),
            _ => const SizedBox.shrink(key: ValueKey('hidden')),
          },
        );
      },
    );
  }
}

enum BannerPosition { top, bottom }

class _BannerTile extends StatelessWidget {
  const _BannerTile({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
    required this.onColor,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
        color: color.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: context.textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

