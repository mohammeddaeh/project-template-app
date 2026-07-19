import 'package:flutter/widgets.dart';

/// App lifecycle state abstraction.
///
/// Wraps [WidgetsBindingObserver] so features can react to
/// foreground/background/inactive transitions without depending on the
/// binding directly.
///
/// ## Typical usage
/// ```dart
/// // In a cubit / service:
/// _lifecycle.stateStream.listen((state) {
///   if (state == AppLifecycleState.resumed) _startPolling();
///   if (state == AppLifecycleState.paused)  _stopPolling();
/// });
/// ```
///
/// Registered as `@lazySingleton` in `di/injection_module.dart`.
/// Call [dispose] on app exit (or let DI handle it).
abstract interface class AppLifecycleService {
  /// Emits every [AppLifecycleState] change.
  Stream<AppLifecycleState> get stateStream;

  /// The most recent [AppLifecycleState] — defaults to [AppLifecycleState.resumed].
  AppLifecycleState get currentState;

  /// Convenience: `true` when [currentState] is [AppLifecycleState.resumed].
  bool get isInForeground;

  /// Stops observing lifecycle events.  Must be called on dispose.
  void dispose();
}
