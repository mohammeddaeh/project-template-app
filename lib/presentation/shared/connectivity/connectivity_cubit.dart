import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:app_template/core/platform/connectivity/network_state.dart';
import 'package:app_template/core/platform/connectivity/network_state_monitor.dart';

export 'package:app_template/core/platform/connectivity/network_state.dart';

/// Translates [NetworkStateMonitor] stream events into Bloc-friendly states.
///
/// Wrap your app (or any sub-tree) with a [BlocProvider] / [BlocListener]
/// to react to connectivity changes in the UI layer.
///
/// Usage in app.dart:
/// ```dart
/// BlocProvider(
///   create: (_) => getIt<ConnectivityCubit>(),
///   child: BlocListener<ConnectivityCubit, NetworkState>(
///     listener: (context, state) {
///       if (state.isOffline) context.showOfflineBanner();
///     },
///     child: child,
///   ),
/// )
/// ```
///
/// Usage in any Cubit for a one-shot check:
/// ```dart
/// if (!await ConnectivityService.isOnline()) return;
/// ```
@lazySingleton
class ConnectivityCubit extends Cubit<NetworkState> {
  ConnectivityCubit(this._monitor) : super(_monitor.currentState) {
    _sub = _monitor.stateStream.listen(emit);
  }

  final NetworkStateMonitor _monitor;
  late final StreamSubscription<NetworkState> _sub;

  bool get isOnline => state.isOnline;

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
