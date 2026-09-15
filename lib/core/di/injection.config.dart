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
import 'package:app_template/core/foundation/contracts/local_data_wiper.dart'
    as _i675;
import 'package:app_template/core/foundation/contracts/locale_provider.dart'
    as _i702;
import 'package:app_template/core/foundation/contracts/token_refresh_gateway.dart'
    as _i371;
import 'package:app_template/core/foundation/contracts/unsynced_work_probe.dart'
    as _i428;
import 'package:app_template/core/infra/files/server_file_cache.dart' as _i394;
import 'package:app_template/core/infra/network/interceptors/auth_interceptor.dart'
    as _i275;
import 'package:app_template/core/infra/network/interceptors/internet_checker_interceptor.dart'
    as _i235;
import 'package:app_template/core/infra/network/rest/handle_body_response.dart'
    as _i148;
import 'package:app_template/core/infra/session/account_data_cleaner.dart'
    as _i231;
import 'package:app_template/core/infra/session/data_origin_guard.dart'
    as _i836;
import 'package:app_template/core/infra/session/locale_provider_impl.dart'
    as _i259;
import 'package:app_template/core/infra/session/session_guard_fresh_auth.dart'
    as _i34;
import 'package:app_template/core/infra/session/session_repository.dart'
    as _i512;
import 'package:app_template/core/infra/session/welcome_greeting.dart' as _i312;
import 'package:app_template/core/platform/connectivity/network_state_monitor.dart'
    as _i979;
import 'package:app_template/core/platform/connectivity/network_state_monitor_impl.dart'
    as _i894;
import 'package:app_template/core/platform/connectivity/server_reachability.dart'
    as _i933;
import 'package:app_template/core/platform/device/device_label_service.dart'
    as _i27;
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
import 'package:app_template/features/auth/change_password/data/datasources/change_password_api_service.dart'
    as _i910;
import 'package:app_template/features/auth/change_password/data/datasources/change_password_remote_datasource.dart'
    as _i335;
import 'package:app_template/features/auth/change_password/data/repositories/change_password_repository_impl.dart'
    as _i532;
import 'package:app_template/features/auth/change_password/domain/repositories/change_password_repository.dart'
    as _i932;
import 'package:app_template/features/auth/change_password/domain/usecases/change_password_usecase.dart'
    as _i53;
import 'package:app_template/features/auth/change_password/presentation/cubits/change_password_cubit.dart'
    as _i912;
import 'package:app_template/features/auth/forgot_password/data/datasources/password_reset_api_service.dart'
    as _i1022;
import 'package:app_template/features/auth/forgot_password/data/datasources/password_reset_remote_datasource.dart'
    as _i633;
import 'package:app_template/features/auth/forgot_password/data/repositories/password_reset_repository_impl.dart'
    as _i507;
import 'package:app_template/features/auth/forgot_password/domain/repositories/password_reset_repository.dart'
    as _i904;
import 'package:app_template/features/auth/forgot_password/domain/usecases/request_reset_usecase.dart'
    as _i211;
import 'package:app_template/features/auth/forgot_password/domain/usecases/reset_password_usecase.dart'
    as _i246;
import 'package:app_template/features/auth/forgot_password/presentation/cubits/forgot_password_cubit.dart'
    as _i249;
import 'package:app_template/features/auth/login/data/datasources/auth_api_service.dart'
    as _i472;
import 'package:app_template/features/auth/login/data/datasources/auth_remote_datasource.dart'
    as _i858;
import 'package:app_template/features/auth/login/data/repositories/login_repository_impl.dart'
    as _i662;
import 'package:app_template/features/auth/login/domain/repositories/login_repository.dart'
    as _i1031;
import 'package:app_template/features/auth/login/domain/usecases/login_usecase.dart'
    as _i662;
import 'package:app_template/features/auth/login/presentation/cubits/login_cubit.dart'
    as _i139;
import 'package:app_template/features/auth/logout/data/datasources/logout_api_service.dart'
    as _i48;
import 'package:app_template/features/auth/logout/data/datasources/logout_remote_datasource.dart'
    as _i476;
import 'package:app_template/features/auth/logout/data/repositories/logout_repository_impl.dart'
    as _i813;
import 'package:app_template/features/auth/logout/domain/repositories/logout_repository.dart'
    as _i524;
import 'package:app_template/features/auth/logout/domain/usecases/logout_usecase.dart'
    as _i1015;
import 'package:app_template/features/auth/logout/presentation/cubits/logout_cubit.dart'
    as _i679;
import 'package:app_template/features/auth/me/data/datasources/me_api_service.dart'
    as _i1;
import 'package:app_template/features/auth/me/data/datasources/me_remote_datasource.dart'
    as _i3;
import 'package:app_template/features/auth/me/data/repositories/me_repository_impl.dart'
    as _i408;
import 'package:app_template/features/auth/me/domain/repositories/me_repository.dart'
    as _i196;
import 'package:app_template/features/auth/me/domain/usecases/get_current_user_usecase.dart'
    as _i502;
import 'package:app_template/features/auth/register/data/datasources/register_api_service.dart'
    as _i408;
import 'package:app_template/features/auth/register/data/datasources/register_remote_datasource.dart'
    as _i1030;
import 'package:app_template/features/auth/register/data/repositories/register_repository_impl.dart'
    as _i734;
import 'package:app_template/features/auth/register/domain/repositories/register_repository.dart'
    as _i599;
import 'package:app_template/features/auth/register/domain/usecases/register_usecase.dart'
    as _i595;
import 'package:app_template/features/auth/register/presentation/cubits/register_cubit.dart'
    as _i498;
import 'package:app_template/features/auth/shared/current_user_repository.dart'
    as _i258;
import 'package:app_template/features/auth/shared/session_sync_service.dart'
    as _i35;
import 'package:app_template/features/auth/shared/token_refresh_gateway_impl.dart'
    as _i819;
import 'package:app_template/features/auth/verify_email/data/datasources/verify_email_api_service.dart'
    as _i1072;
import 'package:app_template/features/auth/verify_email/data/datasources/verify_email_remote_datasource.dart'
    as _i585;
import 'package:app_template/features/auth/verify_email/data/repositories/verify_email_repository_impl.dart'
    as _i866;
import 'package:app_template/features/auth/verify_email/domain/repositories/verify_email_repository.dart'
    as _i230;
import 'package:app_template/features/auth/verify_email/domain/usecases/resend_verification_usecase.dart'
    as _i1006;
import 'package:app_template/features/auth/verify_email/domain/usecases/verify_email_usecase.dart'
    as _i893;
import 'package:app_template/features/auth/verify_email/presentation/cubits/verify_email_cubit.dart'
    as _i730;
import 'package:app_template/features/home/presentation/cubits/navigation_cubit.dart'
    as _i793;
import 'package:app_template/modules/sync/sync_plugin.dart' as _i590;
import 'package:app_template/routes/router.dart' as _i168;
import 'package:app_template/ui/feedback/app_feedback_service.dart' as _i625;
import 'package:app_template/ui/state/connectivity/connectivity_cubit.dart'
    as _i880;
import 'package:app_template/ui/state/sync/offline_ux_cubit.dart' as _i822;
import 'package:app_template/ui/state/sync/sync_manager_cubit.dart' as _i492;
import 'package:app_template/ui/theme/app_theme.dart' as _i466;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive_flutter/hive_flutter.dart' as _i986;
import 'package:injectable/injectable.dart' as _i526;
import 'package:internet_connection_checker/internet_connection_checker.dart'
    as _i973;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
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
    await gh.lazySingletonAsync<_i460.SharedPreferences>(
      () => injectableModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i428.UnsyncedWorkProbe>(
      () => injectableModule.unsyncedWorkProbe,
    );
    gh.lazySingleton<_i675.LocalDataWiper>(
      () => injectableModule.localDataWiper,
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
    gh.lazySingleton<_i625.AppFeedbackService>(
      () => injectableModule.feedbackService,
    );
    gh.lazySingleton<_i455.SecureStorageService>(
      () => injectableModule.secureStorageService(),
    );
    gh.lazySingleton<_i148.HandleBodyResponse>(
      () => _i148.HandleBodyResponse(),
    );
    gh.lazySingleton<_i34.SessionGuardFreshAuth>(
      () => _i34.SessionGuardFreshAuth(),
    );
    gh.lazySingleton<_i312.WelcomeGreeting>(() => _i312.WelcomeGreeting());
    gh.lazySingleton<_i27.DeviceLabelService>(() => _i27.DeviceLabelService());
    gh.lazySingleton<_i793.NavigationCubit>(() => _i793.NavigationCubit());
    gh.lazySingleton<_i466.AppTheme>(() => _i466.AppTheme());
    gh.lazySingleton<_i979.NetworkStateMonitor>(
      () => _i894.NetworkStateMonitorImpl(),
    );
    gh.lazySingleton<_i880.ConnectivityCubit>(
      () => _i880.ConnectivityCubit(gh<_i979.NetworkStateMonitor>()),
    );
    gh.lazySingleton<_i135.MediaService>(() => _i347.MediaServiceImpl());
    gh.lazySingleton<_i888.UrlLauncherService>(
      () => _i866.UrlLauncherServiceImpl(),
    );
    gh.lazySingleton<_i1021.PermissionsService>(
      () => _i252.PermissionsServiceImpl(),
    );
    gh.lazySingleton<_i472.AuthApiService>(
      () => injectableModule.authApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i408.RegisterApiService>(
      () => injectableModule.registerApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i1.MeApiService>(
      () => injectableModule.meApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i48.LogoutApiService>(
      () => injectableModule.logoutApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i1022.PasswordResetApiService>(
      () => injectableModule.passwordResetApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i910.ChangePasswordApiService>(
      () => injectableModule.changePasswordApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i1072.VerifyEmailApiService>(
      () => injectableModule.verifyEmailApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i394.ServerFileCache>(
      () => _i394.ServerFileCache(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i702.LocaleProvider>(() => _i259.AppLocaleProvider());
    gh.lazySingleton<_i858.AuthRemoteDataSource>(
      () => _i858.AuthRemoteDataSource(
        gh<_i472.AuthApiService>(),
        gh<_i27.DeviceLabelService>(),
      ),
    );
    gh.lazySingleton<_i335.ChangePasswordRemoteDataSource>(
      () => _i335.ChangePasswordRemoteDataSource(
        gh<_i910.ChangePasswordApiService>(),
      ),
    );
    gh.lazySingleton<_i933.ServerReachability>(
      () => injectableModule.serverReachability(
        gh<_i973.InternetConnectionChecker>(),
        gh<_i895.Connectivity>(),
      ),
    );
    gh.lazySingleton<_i633.PasswordResetRemoteDataSource>(
      () => _i633.PasswordResetRemoteDataSource(
        gh<_i1022.PasswordResetApiService>(),
      ),
    );
    gh.lazySingleton<_i585.VerifyEmailRemoteDataSource>(
      () =>
          _i585.VerifyEmailRemoteDataSource(gh<_i1072.VerifyEmailApiService>()),
    );
    gh.lazySingleton<_i492.SyncManagerCubit>(
      () => _i492.SyncManagerCubit(
        gh<_i590.SyncController>(),
        gh<_i590.SyncQueueRepository>(),
      ),
    );
    gh.lazySingleton<_i1030.RegisterRemoteDataSource>(
      () => _i1030.RegisterRemoteDataSource(gh<_i408.RegisterApiService>()),
    );
    gh.singleton<_i512.SessionRepository>(
      () => _i512.SessionRepository(gh<_i455.SecureStorageService>()),
    );
    gh.lazySingleton<_i104.StorageService>(
      () => injectableModule.storageService(gh<_i986.Box<dynamic>>()),
    );
    gh.lazySingleton<_i235.InternetCheckerInterceptor>(
      () => _i235.InternetCheckerInterceptor(
        gh<_i933.ServerReachability>(),
        gh<_i895.Connectivity>(),
      ),
    );
    gh.lazySingleton<_i822.OfflineUxCubit>(
      () => _i822.OfflineUxCubit(
        gh<_i979.NetworkStateMonitor>(),
        gh<_i590.SyncQueueRepository>(),
      ),
    );
    gh.lazySingleton<_i231.AccountDataCleaner>(
      () => _i231.AccountDataCleaner(
        gh<_i104.StorageService>(),
        gh<_i675.LocalDataWiper>(),
      ),
    );
    gh.lazySingleton<_i932.ChangePasswordRepository>(
      () => _i532.ChangePasswordRepositoryImpl(
        gh<_i335.ChangePasswordRemoteDataSource>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.lazySingleton<_i3.MeRemoteDataSource>(
      () => _i3.MeRemoteDataSource(gh<_i1.MeApiService>()),
    );
    gh.lazySingleton<_i836.DataOriginGuard>(
      () => _i836.DataOriginGuard(
        gh<_i104.StorageService>(),
        gh<_i512.SessionRepository>(),
        gh<_i231.AccountDataCleaner>(),
      ),
    );
    gh.factory<_i53.ChangePasswordUseCase>(
      () => _i53.ChangePasswordUseCase(gh<_i932.ChangePasswordRepository>()),
    );
    gh.lazySingleton<_i476.LogoutRemoteDataSource>(
      () => _i476.LogoutRemoteDataSource(gh<_i48.LogoutApiService>()),
    );
    gh.lazySingleton<_i904.PasswordResetRepository>(
      () => _i507.PasswordResetRepositoryImpl(
        gh<_i633.PasswordResetRemoteDataSource>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.lazySingleton<_i599.RegisterRepository>(
      () => _i734.RegisterRepositoryImpl(
        gh<_i1030.RegisterRemoteDataSource>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.factory<_i912.ChangePasswordCubit>(
      () => _i912.ChangePasswordCubit(gh<_i53.ChangePasswordUseCase>()),
    );
    gh.factory<_i211.RequestResetUseCase>(
      () => _i211.RequestResetUseCase(gh<_i904.PasswordResetRepository>()),
    );
    gh.factory<_i246.ResetPasswordUseCase>(
      () => _i246.ResetPasswordUseCase(gh<_i904.PasswordResetRepository>()),
    );
    gh.lazySingleton<_i188.AuthNetworkGateway>(
      () => injectableModule.authNetworkGateway(gh<_i512.SessionRepository>()),
    );
    gh.singleton<_i258.CurrentUserRepository>(
      () => _i258.CurrentUserRepository(gh<_i104.StorageService>()),
    );
    gh.lazySingleton<_i524.LogoutRepository>(
      () => _i813.LogoutRepositoryImpl(
        gh<_i476.LogoutRemoteDataSource>(),
        gh<_i512.SessionRepository>(),
        gh<_i258.CurrentUserRepository>(),
        gh<_i231.AccountDataCleaner>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.lazySingleton<_i275.AuthInterceptor>(
      () => _i275.AuthInterceptor(
        gh<_i188.AuthNetworkGateway>(),
        gh<_i702.LocaleProvider>(),
      ),
    );
    gh.lazySingleton<_i230.VerifyEmailRepository>(
      () => _i866.VerifyEmailRepositoryImpl(
        gh<_i585.VerifyEmailRemoteDataSource>(),
        gh<_i258.CurrentUserRepository>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.lazySingleton<_i1031.LoginRepository>(
      () => _i662.LoginRepositoryImpl(
        gh<_i858.AuthRemoteDataSource>(),
        gh<_i512.SessionRepository>(),
        gh<_i258.CurrentUserRepository>(),
        gh<_i231.AccountDataCleaner>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.factory<_i595.RegisterUseCase>(
      () => _i595.RegisterUseCase(gh<_i599.RegisterRepository>()),
    );
    gh.factory<_i249.ForgotPasswordCubit>(
      () => _i249.ForgotPasswordCubit(
        gh<_i211.RequestResetUseCase>(),
        gh<_i246.ResetPasswordUseCase>(),
      ),
    );
    gh.singleton<_i371.TokenRefreshGateway>(
      () => _i819.TokenRefreshGatewayImpl(
        gh<_i512.SessionRepository>(),
        gh<_i258.CurrentUserRepository>(),
      ),
    );
    gh.lazySingleton<_i196.MeRepository>(
      () => _i408.MeRepositoryImpl(
        gh<_i3.MeRemoteDataSource>(),
        gh<_i258.CurrentUserRepository>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.factory<_i662.LoginUseCase>(
      () => _i662.LoginUseCase(gh<_i1031.LoginRepository>()),
    );
    gh.factory<_i1015.LogoutUseCase>(
      () => _i1015.LogoutUseCase(gh<_i524.LogoutRepository>()),
    );
    gh.factory<_i502.GetCurrentUserUseCase>(
      () => _i502.GetCurrentUserUseCase(gh<_i196.MeRepository>()),
    );
    gh.factory<_i1006.ResendVerificationUseCase>(
      () => _i1006.ResendVerificationUseCase(gh<_i230.VerifyEmailRepository>()),
    );
    gh.factory<_i893.VerifyEmailUseCase>(
      () => _i893.VerifyEmailUseCase(gh<_i230.VerifyEmailRepository>()),
    );
    gh.factory<_i498.RegisterCubit>(
      () => _i498.RegisterCubit(gh<_i595.RegisterUseCase>()),
    );
    gh.factory<_i139.LoginCubit>(
      () => _i139.LoginCubit(
        gh<_i662.LoginUseCase>(),
        gh<_i34.SessionGuardFreshAuth>(),
      ),
    );
    gh.lazySingleton<_i35.SessionSyncService>(
      () => _i35.SessionSyncService(
        gh<_i512.SessionRepository>(),
        gh<_i502.GetCurrentUserUseCase>(),
      ),
    );
    gh.factory<_i730.VerifyEmailCubit>(
      () => _i730.VerifyEmailCubit(
        gh<_i893.VerifyEmailUseCase>(),
        gh<_i1006.ResendVerificationUseCase>(),
      ),
    );
    gh.factory<_i679.LogoutCubit>(
      () => _i679.LogoutCubit(
        gh<_i1015.LogoutUseCase>(),
        gh<_i428.UnsyncedWorkProbe>(),
      ),
    );
    return this;
  }
}

class _$InjectableModule extends _i321.InjectableModule {}
