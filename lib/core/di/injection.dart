import 'package:app_template/core/di/injection.config.dart';
import 'package:app_template/core/di/platform_services_registry.dart';
import 'package:app_template/core/infra/errors/failure_mapper_registry.dart';
import 'package:app_template/core/platform/connectivity/network_state_monitor.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt getIt = GetIt.instance;

@injectableInit
Future<void> configureInjection(String env) async {
  await getIt.init(environment: env);

  // Register optional platform services based on AppFeatures flags.
  // To enable/disable a service → change the flag in app_features.dart only.
  PlatformServicesRegistry.configure(getIt);

  // Lets the error layer tell "this device is offline" apart from "the server
  // is closed" — Dio reports both as the same exception, and answering "no
  // internet connection" to someone whose connection is fine sends them to
  // fight their router while the server is the thing that is down.
  //
  // Wired here because `FailureMapperRegistry` is static (reached from
  // repositories and interceptors that hold no container) while the monitor is
  // a DI singleton. Read lazily through the closure, never captured as a value:
  // the whole point is the state *at the moment the request failed*.
  FailureMapperRegistry.useNetworkStateProbe(
    () => getIt<NetworkStateMonitor>().currentState,
  );
}
