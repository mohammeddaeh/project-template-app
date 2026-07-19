import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/connectivity/connectivity_service.dart';
import 'package:app_template/core/platform/connectivity/network_state_monitor.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:injectable/injectable.dart';

import '../../../modules/sync/domain/sync_queue_repository.dart';

part 'offline_ux_state.dart';

/// Drives the "offline banner" and "pending changes" UI indicators.
///
/// ## Lives in `presentation/shared/sync/`
/// Uses `NetworkStateMonitor` for the reactive connectivity stream.
/// Never calls `ConnectivityService` directly in a loop — subscribes once.
///
/// ## Usage
/// ```dart
/// BlocBuilder<OfflineUxCubit, OfflineUxState>(
///   builder: (ctx, state) => switch (state) {
///     OfflineState()           => const SyncStatusBanner(),
///     PendingChangesState(:final pendingCount) =>
///       PendingChangesChip(count: pendingCount),
///     OnlineState()            => const SizedBox.shrink(),
///     ConnectivityUnknownState() => const SizedBox.shrink(),
///   },
/// );
/// ```
@lazySingleton
class OfflineUxCubit extends Cubit<OfflineUxState> {
  OfflineUxCubit(
    this._networkMonitor,
    this._queueRepository,
  ) : super(const ConnectivityUnknownState());

  final NetworkStateMonitor _networkMonitor;
  final SyncQueueRepository _queueRepository;

  StreamSubscription? _sub;

  /// Start watching connectivity + pending count.
  Future<void> init() async {
    // Determine initial state.
    final online = await ConnectivityService.isOnline();
    await _updateState(isOnline: online);

    // Subscribe to changes.
    _sub = _networkMonitor.stateStream.listen((state) async {
      await _updateState(isOnline: state.isOnline);
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }

  Future<void> _updateState({required bool isOnline}) async {
    if (!isOnline) {
      emit(const OfflineState());
      return;
    }
    final pending = await _queueRepository.countPendingJobs();
    if (pending > 0) {
      emit(PendingChangesState(pendingCount: pending));
    } else {
      emit(const OnlineState());
    }
  }

  /// Call after a sync cycle completes to refresh the pending count.
  Future<void> refresh() async {
    final online = await ConnectivityService.isOnline();
    await _updateState(isOnline: online);
  }

  /// Translate a failure from any sync operation into a [UiAction].
  UiAction translateFailure(Failure failure) =>
      FailureUiMapper.toAction(failure);
}
