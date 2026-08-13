import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/access_control/data/access_control_api_service.dart';
import 'package:app_template/modules/access_control/data/access_control_repository_impl.dart';
import 'package:app_template/modules/access_control/domain/access_control_repository.dart';
import 'package:app_template/modules/access_control/integration/abilities_store.dart';
import 'package:app_template/modules/access_control/presentation/cubits/role_editor_cubit.dart';
import 'package:app_template/modules/access_control/presentation/cubits/roles_cubit.dart';
import 'package:app_template/modules/access_control/presentation/cubits/user_access_cubit.dart';

/// Registers the module's dependencies. Called once from
/// [AccessControlPlugin.initialize].
///
/// Registration is manual rather than `@injectable` for the same reason as
/// every other module here: `injectable`'s generator scans all of `lib/`, so an
/// annotated module would be wired into `injection.config.dart` whether or not
/// its feature flag is on — and a module that ships disabled must cost nothing.
///
/// Every registration is guarded by `isRegistered`, so a hot restart that
/// re-runs bootstrap does not throw over an already-registered type.
Future<void> registerAccessControl(GetIt di) async {
  if (!di.isRegistered<AccessControlApiService>()) {
    di.registerLazySingleton<AccessControlApiService>(
      () => AccessControlApiService(di<Dio>()),
    );
  }

  if (!di.isRegistered<AccessControlRepository>()) {
    di.registerLazySingleton<AccessControlRepository>(
      () => AccessControlRepositoryImpl(
        di<AccessControlApiService>(),
        di<HandleBodyResponse>(),
      ),
    );
  }

  // A singleton, unlike the cubits below: every gate in the app reads this one
  // object, so there is a single answer to "what may this user do" and a single
  // place it changes.
  if (!di.isRegistered<AbilitiesStore>()) {
    di.registerLazySingleton<AbilitiesStore>(
      () => AbilitiesStore(
        di<AccessControlRepository>(),
        di<StorageService>(),
        di<SessionRepository>(),
      ),
    );
  }

  // Factories: each administration screen gets its own state machine, and a
  // shared role editor would carry a half-edited permission set between roles.
  if (!di.isRegistered<RolesCubit>()) {
    di.registerFactory<RolesCubit>(
      () => RolesCubit(di<AccessControlRepository>()),
    );
  }

  if (!di.isRegistered<RoleEditorCubit>()) {
    di.registerFactory<RoleEditorCubit>(
      () => RoleEditorCubit(di<AccessControlRepository>()),
    );
  }

  if (!di.isRegistered<UserAccessCubit>()) {
    di.registerFactory<UserAccessCubit>(
      () => UserAccessCubit(di<AccessControlRepository>()),
    );
  }
}
