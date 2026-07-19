import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/presentation/theme/theme_extensions.dart';
import '../offline_ux_cubit.dart';
import '../sync_manager_cubit.dart';

/// Compact badge showing pending change count + sync trigger button.
///
/// Shows nothing when there are no pending changes.
///
/// Example (in an AppBar):
/// ```dart
/// AppBar(
///   actions: [
///     const PendingChangesChip(),
///   ],
/// )
/// ```
class PendingChangesChip extends StatelessWidget {
  const PendingChangesChip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfflineUxCubit, OfflineUxState>(
      builder: (context, offlineState) {
        if (offlineState is! PendingChangesState) {
          return const SizedBox.shrink();
        }
        final pendingCount = offlineState.pendingCount;
        return BlocBuilder<SyncManagerCubit, SyncManagerState>(
          builder: (context, syncState) {
            final isRunning = syncState is SyncRunning;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: isRunning
                    ? null
                    : () => context.read<SyncManagerCubit>().triggerSync(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.statusWarningBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.colors.statusWarningFg, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRunning)
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.statusWarningFg,
                          ),
                        )
                      else
                        Icon(
                          Icons.sync_rounded,
                          size: 14,
                          color: context.colors.statusWarningFg,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        '$pendingCount',
                        style: context.textTheme.labelSmall?.copyWith(
                              color: context.colors.statusWarningFg,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

