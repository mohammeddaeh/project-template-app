import 'network_state.dart';

/// Abstract contract for reactive network-state monitoring.
///
/// Implemented by [NetworkStateMonitorImpl] (connectivity_plus).
/// Consumed by:
///   - [ConnectivityCubit]  → UI layer
///   - modules/sync         → SyncController reacts to link changes
///
/// Lifecycle: call [dispose] when no longer needed (typically never
/// for app-level singletons, but required in tests).
abstract interface class NetworkStateMonitor {
  /// The current known state. Starts as [NetworkState.unknown] until
  /// the first platform event arrives.
  NetworkState get currentState;

  /// Continuous stream of state transitions.
  /// Guaranteed to emit on subscription with the latest known state.
  Stream<NetworkState> get stateStream;

  /// Releases the underlying platform subscription.
  void dispose();
}
