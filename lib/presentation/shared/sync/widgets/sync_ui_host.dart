import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../offline_ux_cubit.dart';
import '../sync_manager_cubit.dart';
import 'sync_status_banner.dart';

/// Wraps a screen with all sync-aware UI scaffolding:
/// - [SyncStatusBanner] at the top (offline / pending changes)
/// - Conflict resolution sheet trigger
/// - Sync error snackbar
///
/// ## Usage
/// ```dart
/// SyncUiHost(
///   child: Scaffold(
///     appBar: AppBar(
///       actions: [const PendingChangesChip()],
///     ),
///     body: UsersScreen(),
///   ),
/// )
/// ```
///
/// ## Notes
/// - Both [OfflineUxCubit] and [SyncManagerCubit] must be provided above this widget.
/// - Safe to use on any screen — shows nothing if sync is disabled.
class SyncUiHost extends StatefulWidget {
  const SyncUiHost({
    super.key,
    required this.child,
    this.bannerPosition = BannerPosition.top,
    this.showConflictSheet = true,
    this.showErrorSnackBar = true,
  });

  final Widget child;
  final BannerPosition bannerPosition;

  /// When true: automatically shows a bottom sheet on [ConflictDetected].
  final bool showConflictSheet;

  /// When true: shows a SnackBar on [SyncFailedState].
  final bool showErrorSnackBar;

  @override
  State<SyncUiHost> createState() => _SyncUiHostState();
}

class _SyncUiHostState extends State<SyncUiHost> {
  @override
  void initState() {
    super.initState();
    // Start offline UX monitoring when the host mounts.
    context.read<OfflineUxCubit>().init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SyncManagerCubit, SyncManagerState>(
          listener: _handleSyncManagerState,
        ),
        BlocListener<OfflineUxCubit, OfflineUxState>(
          listener: _handleOfflineUxState,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.bannerPosition == BannerPosition.top)
            const SyncStatusBanner(position: BannerPosition.top),
          Expanded(child: widget.child),
          if (widget.bannerPosition == BannerPosition.bottom)
            const SyncStatusBanner(position: BannerPosition.bottom),
        ],
      ),
    );
  }

  void _handleSyncManagerState(BuildContext context, SyncManagerState state) {
    if (!mounted) return;
    switch (state) {
      case ConflictDetected() when widget.showConflictSheet:
        _showConflictSheet(context, state);

      case SyncFailedState(:final failure) when widget.showErrorSnackBar:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${failure.diagnosticMessage ?? 'unknown error'}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () => context.read<SyncManagerCubit>().triggerSync(),
            ),
          ),
        );

      case SyncSuccess():
        context.read<OfflineUxCubit>().refresh();

      default:
        break;
    }
  }

  void _handleOfflineUxState(BuildContext context, OfflineUxState state) {
    // Nothing additional — SyncStatusBanner handles its own rendering.
  }

  void _showConflictSheet(BuildContext context, ConflictDetected conflict) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ConflictResolutionSheet(
        conflict: conflict,
        onResolve: (keepLocal) {
          Navigator.of(context).pop();
          context.read<SyncManagerCubit>().resetToIdle();
          if (keepLocal) {
            context.read<SyncManagerCubit>().triggerSync();
          }
        },
      ),
    );
  }
}

class _ConflictResolutionSheet extends StatelessWidget {
  const _ConflictResolutionSheet({
    required this.conflict,
    required this.onResolve,
  });

  final ConflictDetected conflict;
  final void Function(bool keepLocal) onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync_problem_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Text('Sync Conflict', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'A conflict was detected for ${conflict.entityName}.\n'
            'Choose how to resolve it:',
            style: theme.textTheme.bodyMedium,
          ),
          if (conflict.conflictFields.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Conflicting fields: ${conflict.conflictFields.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onResolve(false),
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('Keep Server Version'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onResolve(true),
                  icon: const Icon(Icons.phone_android_rounded),
                  label: const Text('Keep My Version'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
