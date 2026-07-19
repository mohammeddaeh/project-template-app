import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:injectable/injectable.dart';

import '../../../modules/sync/domain/sync_queue_repository.dart';
import '../../../modules/sync/integration/sync_controller.dart';

part 'sync_manager_state.dart';

/// Presentation-layer orchestrator for the sync module.
///
/// Lives in `presentation/shared/sync/` — NOT in `modules/` — because it
/// depends on Flutter (flutter_bloc) which is outside the pure-Dart module boundary.
///
/// ## Responsibilities
/// - Triggers manual sync via [SyncController].
/// - Exposes sync running / success / failure states to the UI.
/// - Reports pending count so widgets can show "N changes pending" badges.
///
/// ## Usage in UI
/// ```dart
/// BlocBuilder<SyncManagerCubit, SyncManagerState>(
///   builder: (context, state) => switch (state) {
///     SyncRunning() => const CircularProgressIndicator(),
///     SyncSuccess(:final pendingCount) => PendingChangesChip(count: pendingCount),
///     SyncFailedState(:final failure) => _handleFailure(failure),
///     ConflictDetected() => ConflictResolutionSheet(state),
///     SyncIdle() => const SizedBox.shrink(),
///   },
/// );
/// ```
@lazySingleton
class SyncManagerCubit extends Cubit<SyncManagerState> {
  SyncManagerCubit(
    this._controller,
    this._queueRepository,
  ) : super(const SyncIdle());

  final SyncController _controller;
  final SyncQueueRepository _queueRepository;

  /// Triggers a manual sync push cycle and updates UI state.
  Future<void> triggerSync() async {
    if (state is SyncRunning) return;
    emit(const SyncRunning());
    try {
      await _controller.triggerManualSync();
      final pending = await _queueRepository.countPendingJobs();
      emit(SyncSuccess(
        pendingCount: pending,
        completedAt: DateTime.now(),
      ));
    } catch (e, st) {
      LogService.error('SyncManagerCubit error', tag: 'SYNC', error: e, stackTrace: st);
      emit(SyncFailedState(failure: UnknownFailure(message: e.toString())));
    }
  }

  /// Refreshes the pending count (e.g., after a local write).
  Future<void> refreshPendingCount() async {
    final pending = await _queueRepository.countPendingJobs();
    if (state is! SyncRunning) {
      emit(SyncSuccess(pendingCount: pending));
    }
  }

  /// Emits [ConflictDetected] when [SyncEngine] marks an entity as conflicted.
  /// Called externally from the sync engine event bus (or polling).
  void notifyConflict({
    required String entityName,
    required String entityId,
    required List<String> conflictFields,
    required Map<String, dynamic> serverSnapshot,
  }) {
    emit(ConflictDetected(
      entityName: entityName,
      entityId: entityId,
      conflictFields: conflictFields,
      serverSnapshot: serverSnapshot,
    ));
  }

  void resetToIdle() => emit(const SyncIdle());
}
