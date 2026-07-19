part of 'offline_ux_cubit.dart';

/// State emitted by [OfflineUxCubit].
sealed class OfflineUxState {
  const OfflineUxState();
}

/// Device is online and sync is available.
final class OnlineState extends OfflineUxState {
  const OnlineState();
}

/// Device has no connectivity — show offline banner.
final class OfflineState extends OfflineUxState {
  const OfflineState();
}

/// Connectivity state is being determined.
final class ConnectivityUnknownState extends OfflineUxState {
  const ConnectivityUnknownState();
}

/// There are unsynced local changes waiting to be pushed.
final class PendingChangesState extends OfflineUxState {
  const PendingChangesState({required this.pendingCount});
  final int pendingCount;
}
