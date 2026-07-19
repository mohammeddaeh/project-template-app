import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/core/platform/config/app_settings.dart';

/// A singleton class for centralized Bloc event and state logging.
class BlocLogger {
  static final BlocLogger _instance = BlocLogger._internal();

  BlocLogger._internal();

  factory BlocLogger() => _instance;

  void logEvent(Bloc bloc, Object? event) => _log(
    message: '[EVENT] ${bloc.runtimeType} | Event: $event',
    level: _LogLevel.info,
  );

  void logChange(BlocBase bloc, Change change) => _log(
    message:
        '[CHANGE] ${bloc.runtimeType} | From: ${change.currentState} ➔ To: ${change.nextState}',
    level: _LogLevel.warning,
  );

  void logTransition(Bloc bloc, Transition transition) => _log(
    message:
        '[TRANSITION] ${bloc.runtimeType} | From: ${transition.currentState} | Event: ${transition.event} | To: ${transition.nextState}',
    level: _LogLevel.transition,
  );

  void logError(BlocBase bloc, Object error, StackTrace stackTrace) => _log(
    message:
        '[ERROR] ${bloc.runtimeType} | Error: $error | StackTrace: $stackTrace',
    level: _LogLevel.error,
  );

  void logCreation(BlocBase bloc) => _log(
    message: '[CREATED] ${bloc.runtimeType} was created.',
    level: _LogLevel.create,
  );

  void logClosure(BlocBase bloc) => _log(
    message: '[CLOSED] ${bloc.runtimeType} was closed.',
    level: _LogLevel.close,
  );

  void _log({required String message, required _LogLevel level}) {
    if (!AppSettings.enableBlocObserverLogger) return;
    dev.log('${level.emoji} $message', name: level.name);
  }
}

enum _LogLevel {
  info('Info', '🔵'),
  warning('Warning', '🟡'),
  transition('Transition', '🟠'),
  error('Error', '🔴'),
  create('Create', '🟢'),
  close('Close', '🔵');

  final String name;
  final String emoji;

  const _LogLevel(this.name, this.emoji);
}

/// Custom Bloc Observer that integrates the BlocLogger.
class CustomBlocObserver extends BlocObserver {
  final _logger = BlocLogger();

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    return _logger.logEvent(bloc, event);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    return _logger.logChange(bloc, change);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    return _logger.logTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    return _logger.logError(bloc, error, stackTrace);
  }

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    return _logger.logCreation(bloc);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    return _logger.logClosure(bloc);
  }
}

typedef AppBlocObserver = CustomBlocObserver;
