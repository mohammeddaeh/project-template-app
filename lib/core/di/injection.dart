import 'package:app_template/core/di/injection.config.dart';
import 'package:app_template/core/di/platform_services_registry.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt getIt = GetIt.instance;

@injectableInit
Future<void> configureInjection(String env) async {
  await getIt.init(environment: env);

  // Register optional platform services based on AppFeatures flags.
  // To enable/disable a service → change the flag in app_features.dart only.
  PlatformServicesRegistry.configure(getIt);
}
