import 'package:flutter/foundation.dart';

abstract class AppSettings {
  static const bool enableLogging = !kReleaseMode;

  /// Keep Bloc observer logging off by default to avoid noisy output from
  /// normal state transitions such as splash/refresh cubits.
  static const bool enableBlocObserverLogger = false;
}
