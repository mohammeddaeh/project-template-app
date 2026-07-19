import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:app_template/core/platform/lifecycle/app_lifecycle_service.dart';

/// [AppLifecycleService] implementation backed by [WidgetsBindingObserver].
///
/// No external package needed — uses Flutter's built-in binding.
/// Registered manually in `di/injection_module.dart`.
class AppLifecycleServiceImpl
    with WidgetsBindingObserver
    implements AppLifecycleService {
  AppLifecycleServiceImpl() {
    WidgetsBinding.instance.addObserver(this);
  }

  final _controller = StreamController<AppLifecycleState>.broadcast();

  AppLifecycleState _currentState = AppLifecycleState.resumed;

  @override
  Stream<AppLifecycleState> get stateStream => _controller.stream;

  @override
  AppLifecycleState get currentState => _currentState;

  @override
  bool get isInForeground => _currentState == AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentState = state;
    if (!_controller.isClosed) _controller.add(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.close();
  }
}
