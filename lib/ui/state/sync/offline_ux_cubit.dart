import 'dart:async';
import 'package:app_template/core/foundation/domain/safe_cubit.dart';

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/connectivity/network_state_monitor.dart';
import 'package:app_template/ui/error/ui_action.dart';
import 'package:app_template/ui/error/failure_ui_mapper.dart';
import 'package:injectable/injectable.dart';

import 'package:app_template/modules/sync/sync_plugin.dart';

part 'offline_ux_state.dart';

/// Drives the "offline banner" and "pending changes" UI indicators.
///
/// ## Lives in `ui/state/sync/`
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
class OfflineUxCubit extends SafeCubit<OfflineUxState> {
  OfflineUxCubit(this._networkMonitor, this._queueRepository)
    : super(const ConnectivityUnknownState());

  final NetworkStateMonitor _networkMonitor;
  final SyncQueueRepository _queueRepository;

  StreamSubscription? _sub;

  /// Start watching connectivity + pending count.
  ///
  /// The monitor's stream opens with its current state, which is `unknown`
  /// until its first check lands — read as offline, that flashes the offline
  /// banner on a connected device. The cubit stays [ConnectivityUnknownState]
  /// until a real answer arrives.
  Future<void> init() async {
    _sub = _networkMonitor.stateStream
        .where((state) => !state.isUnknown)
        .listen((state) => _updateState(isOnline: state.isOnline));
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
    final state = _networkMonitor.currentState;
    if (state.isUnknown) return;
    await _updateState(isOnline: state.isOnline);
  }

  /// Translate a failure from any sync operation into a [UiAction].
  UiAction translateFailure(Failure failure) =>
      FailureUiMapper.toAction(failure);
}
