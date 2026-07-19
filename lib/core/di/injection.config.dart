// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:app_template/core/di/injection_module.dart' as _i321;
import 'package:app_template/core/foundation/contracts/auth_network_gateway.dart'
    as _i188;
import 'package:app_template/core/foundation/contracts/locale_provider.dart'
    as _i702;
import 'package:app_template/core/infra/network/interceptors/auth_interceptor.dart'
    as _i275;
import 'package:app_template/core/infra/network/interceptors/internet_checker_interceptor.dart'
    as _i235;
import 'package:app_template/core/infra/network/rest/handle_body_response.dart'
    as _i148;
import 'package:app_template/core/infra/session/locale_provider_impl.dart'
    as _i259;
import 'package:app_template/core/infra/session/session_repository.dart'
    as _i512;
import 'package:app_template/core/platform/connectivity/network_state_monitor.dart'
    as _i979;
import 'package:app_template/core/platform/connectivity/network_state_monitor_impl.dart'
    as _i894;
import 'package:app_template/core/platform/launcher/url_launcher_service.dart'
    as _i888;
import 'package:app_template/core/platform/launcher/url_launcher_service_impl.dart'
    as _i866;
import 'package:app_template/core/platform/media/media_service.dart' as _i135;
import 'package:app_template/core/platform/media/media_service_impl.dart'
    as _i347;
import 'package:app_template/core/platform/notifications/local_notifications_service.dart'
    as _i279;
import 'package:app_template/core/platform/permissions/permissions_service.dart'
    as _i1021;
import 'package:app_template/core/platform/permissions/permissions_service_impl.dart'
    as _i252;
import 'package:app_template/core/platform/storage/encryption_service.dart'
    as _i434;
import 'package:app_template/core/platform/storage/secure_storage_service.dart'
    as _i455;
import 'package:app_template/core/platform/storage/storage_service.dart'
    as _i104;
import 'package:app_template/Features/home/presentation/cubits/navigation_cubit.dart'
    as _i921;
import 'package:app_template/modules/sync/domain/sync_queue_repository.dart'
    as _i652;
import 'package:app_template/modules/sync/integration/sync_controller.dart'
    as _i882;
import 'package:app_template/presentation/feedback/app_feedback_service.dart'
    as _i52;
import 'package:app_template/presentation/shared/connectivity/connectivity_cubit.dart'
    as _i493;
import 'package:app_template/presentation/shared/sync/offline_ux_cubit.dart'
    as _i644;
import 'package:app_template/presentation/shared/sync/sync_manager_cubit.dart'
    as _i442;
import 'package:app_template/presentation/theme/app_theme.dart' as _i988;
import 'package:app_template/routes/router.dart' as _i168;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive_flutter/hive_flutter.dart' as _i986;
import 'package:injectable/injectable.dart' as _i526;
import 'package:internet_connection_checker/internet_connection_checker.dart'
    as _i973;
import 'package:uuid/uuid.dart' as _i706;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final injectableModule = _$InjectableModule();
    gh.lazySingleton<_i973.InternetConnectionChecker>(
      () => injectableModule.connectionChecker,
    );
    gh.lazySingleton<_i895.Connectivity>(() => injectableModule.connectivity);
    await gh.lazySingletonAsync<_i986.Box<dynamic>>(
      () => injectableModule.appStorageBox,
      preResolve: true,
    );
    gh.lazySingleton<_i434.EncryptionService>(
      () => injectableModule.encryptionService,
    );
    gh.lazySingleton<_i361.Dio>(() => injectableModule.dioInstance);
    gh.lazySingleton<_i706.Uuid>(() => injectableModule.uuid);
    gh.lazySingleton<_i168.AppRouter>(() => injectableModule.router);
    gh.lazySingleton<_i279.LocalNotificationsService>(
      () => injectableModule.localNotifications,
    );
    gh.lazySingleton<_i52.AppFeedbackService>(
      () => injectableModule.feedbackService,
    );
    gh.lazySingleton<_i455.SecureStorageService>(
      () => injectableModule.secureStorageService(),
    );
    gh.lazySingleton<_i148.HandleBodyResponse>(
      () => _i148.HandleBodyResponse(),
    );
    gh.lazySingleton<_i921.NavigationCubit>(() => _i921.NavigationCubit());
    gh.lazySingleton<_i988.AppTheme>(() => _i988.AppTheme());
    gh.lazySingleton<_i979.NetworkStateMonitor>(
      () => _i894.NetworkStateMonitorImpl(),
    );
    gh.lazySingleton<_i493.ConnectivityCubit>(
      () => _i493.ConnectivityCubit(gh<_i979.NetworkStateMonitor>()),
    );
    gh.lazySingleton<_i135.MediaService>(() => _i347.MediaServiceImpl());
    gh.lazySingleton<_i888.UrlLauncherService>(
      () => _i866.UrlLauncherServiceImpl(),
    );
    gh.lazySingleton<_i1021.PermissionsService>(
      () => _i252.PermissionsServiceImpl(),
    );
    gh.lazySingleton<_i702.LocaleProvider>(() => _i259.AppLocaleProvider());
    gh.lazySingleton<_i442.SyncManagerCubit>(
      () => _i442.SyncManagerCubit(
        gh<_i882.SyncController>(),
        gh<_i652.SyncQueueRepository>(),
      ),
    );
    gh.lazySingleton<_i235.InternetCheckerInterceptor>(
      () => _i235.InternetCheckerInterceptor(
        gh<_i973.InternetConnectionChecker>(),
        gh<_i895.Connectivity>(),
      ),
    );
    gh.singleton<_i512.SessionRepository>(
      () => _i512.SessionRepository(gh<_i455.SecureStorageService>()),
    );
    gh.lazySingleton<_i104.StorageService>(
      () => injectableModule.storageService(gh<_i986.Box<dynamic>>()),
    );
    gh.lazySingleton<_i644.OfflineUxCubit>(
      () => _i644.OfflineUxCubit(
        gh<_i979.NetworkStateMonitor>(),
        gh<_i652.SyncQueueRepository>(),
      ),
    );
    gh.lazySingleton<_i188.AuthNetworkGateway>(
      () => injectableModule.authNetworkGateway(gh<_i512.SessionRepository>()),
    );
    gh.lazySingleton<_i275.AuthInterceptor>(
      () => _i275.AuthInterceptor(
        gh<_i188.AuthNetworkGateway>(),
        gh<_i702.LocaleProvider>(),
      ),
    );
    return this;
  }
}

class _$InjectableModule extends _i321.InjectableModule {}
