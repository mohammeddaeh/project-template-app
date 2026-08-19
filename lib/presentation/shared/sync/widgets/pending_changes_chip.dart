import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import '../offline_ux_cubit.dart';
import '../sync_manager_cubit.dart';

/// Compact badge showing pending change count + sync trigger button.
///
/// Shows nothing when there are no pending changes — **or when the sync module
/// is switched off**, which is the case a caller must never have to handle.
///
/// ```dart
/// AppBar(actions: const [PendingChangesChip()])
/// ```
///
/// ## Self-contained on purpose
///
/// It resolves its own cubits instead of requiring providers above it, for the
/// same reason `LogoutSection` owns its `LogoutCubit`: the alternative is every
/// screen that wants a sync badge wrapping itself in two `BlocProvider`s **and
/// guarding on `AppFeatures.offlineSync` first**, because `OfflineUxCubit`
/// depends on `SyncQueueRepository`, which only exists once `SyncSDK` has run.
/// Forget the guard and the screen throws at `getIt` — on the build where sync
/// is off, which is the default and the one nobody tests.
///
/// The cubits are `lazySingleton`s, so this widget reads them and never closes
/// them: their lifetime is the app's, not this AppBar's.
class PendingChangesChip extends StatelessWidget {
  const PendingChangesChip({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppFeatures.offlineSync || !getIt.isRegistered<SyncQueueRepository>()) {
      return const SizedBox.shrink();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<OfflineUxCubit>()),
        BlocProvider.value(value: getIt<SyncManagerCubit>()),
      ],
      child: const _PendingChangesBadge(),
    );
  }
}

class _PendingChangesBadge extends StatelessWidget {
  const _PendingChangesBadge();

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

