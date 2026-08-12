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
import 'package:app_template/core/foundation/contracts/token_refresh_gateway.dart'
    as _i371;
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
import 'package:app_template/Features/auth/change_password/data/datasources/change_password_api_service.dart'
    as _i400;
import 'package:app_template/Features/auth/change_password/data/datasources/change_password_remote_datasource.dart'
    as _i7;
import 'package:app_template/Features/auth/change_password/data/repositories/change_password_repository_impl.dart'
    as _i716;
import 'package:app_template/Features/auth/change_password/domain/repositories/change_password_repository.dart'
    as _i276;
import 'package:app_template/Features/auth/change_password/domain/usecases/change_password_usecase.dart'
    as _i26;
import 'package:app_template/Features/auth/change_password/presentation/cubits/change_password_cubit.dart'
    as _i245;
import 'package:app_template/Features/auth/forgot_password/data/datasources/password_reset_api_service.dart'
    as _i294;
import 'package:app_template/Features/auth/forgot_password/data/datasources/password_reset_remote_datasource.dart'
    as _i997;
import 'package:app_template/Features/auth/forgot_password/data/repositories/password_reset_repository_impl.dart'
    as _i602;
import 'package:app_template/Features/auth/forgot_password/domain/repositories/password_reset_repository.dart'
    as _i667;
import 'package:app_template/Features/auth/forgot_password/domain/usecases/request_reset_usecase.dart'
    as _i300;
import 'package:app_template/Features/auth/forgot_password/domain/usecases/reset_password_usecase.dart'
    as _i809;
import 'package:app_template/Features/auth/forgot_password/presentation/cubits/forgot_password_cubit.dart'
    as _i974;
import 'package:app_template/Features/auth/login/data/datasources/auth_api_service.dart'
    as _i895;
import 'package:app_template/Features/auth/login/data/datasources/auth_remote_datasource.dart'
    as _i71;
import 'package:app_template/Features/auth/login/data/repositories/login_repository_impl.dart'
    as _i631;
import 'package:app_template/Features/auth/login/domain/repositories/login_repository.dart'
    as _i337;
import 'package:app_template/Features/auth/login/domain/usecases/login_usecase.dart'
    as _i779;
import 'package:app_template/Features/auth/login/presentation/cubits/login_cubit.dart'
    as _i21;
import 'package:app_template/Features/auth/logout/data/datasources/logout_api_service.dart'
    as _i315;
import 'package:app_template/Features/auth/logout/data/datasources/logout_remote_datasource.dart'
    as _i16;
import 'package:app_template/Features/auth/logout/data/repositories/logout_repository_impl.dart'
    as _i805;
import 'package:app_template/Features/auth/logout/domain/repositories/logout_repository.dart'
    as _i694;
import 'package:app_template/Features/auth/logout/domain/usecases/logout_usecase.dart'
    as _i850;
import 'package:app_template/Features/auth/logout/presentation/cubits/logout_cubit.dart'
    as _i478;
import 'package:app_template/Features/auth/me/data/datasources/me_api_service.dart'
    as _i713;
import 'package:app_template/Features/auth/me/data/datasources/me_remote_datasource.dart'
    as _i414;
import 'package:app_template/Features/auth/me/data/repositories/me_repository_impl.dart'
    as _i555;
import 'package:app_template/Features/auth/me/domain/repositories/me_repository.dart'
    as _i475;
import 'package:app_template/Features/auth/me/domain/usecases/get_current_user_usecase.dart'
    as _i351;
import 'package:app_template/Features/auth/register/data/datasources/register_api_service.dart'
    as _i342;
import 'package:app_template/Features/auth/register/data/datasources/register_remote_datasource.dart'
    as _i615;
import 'package:app_template/Features/auth/register/data/repositories/register_repository_impl.dart'
    as _i278;
import 'package:app_template/Features/auth/register/domain/repositories/register_repository.dart'
    as _i382;
import 'package:app_template/Features/auth/register/domain/usecases/register_usecase.dart'
    as _i523;
import 'package:app_template/Features/auth/register/presentation/cubits/register_cubit.dart'
    as _i947;
import 'package:app_template/Features/auth/shared/current_user_repository.dart'
    as _i508;
import 'package:app_template/Features/auth/shared/session_sync_service.dart'
    as _i723;
import 'package:app_template/Features/auth/shared/token_refresh_gateway_impl.dart'
    as _i295;
import 'package:app_template/Features/auth/verify_email/data/datasources/verify_email_api_service.dart'
    as _i553;
import 'package:app_template/Features/auth/verify_email/data/datasources/verify_email_remote_datasource.dart'
    as _i77;
import 'package:app_template/Features/auth/verify_email/data/repositories/verify_email_repository_impl.dart'
    as _i625;
import 'package:app_template/Features/auth/verify_email/domain/repositories/verify_email_repository.dart'
    as _i784;
import 'package:app_template/Features/auth/verify_email/domain/usecases/resend_verification_usecase.dart'
    as _i848;
import 'package:app_template/Features/auth/verify_email/domain/usecases/verify_email_usecase.dart'
    as _i179;
import 'package:app_template/Features/auth/verify_email/presentation/cubits/verify_email_cubit.dart'
    as _i680;
import 'package:app_template/Features/home/presentation/cubits/navigation_cubit.dart'
    as _i921;
import 'package:app_template/Features/notes/data/datasources/notes_api_service.dart'
    as _i428;
import 'package:app_template/Features/notes/data/datasources/notes_remote_datasource.dart'
    as _i723;
import 'package:app_template/Features/notes/data/repositories/notes_repository_impl.dart'
    as _i6;
import 'package:app_template/Features/notes/domain/repositories/notes_repository.dart'
    as _i319;
import 'package:app_template/Features/notes/domain/usecases/notes_usecases.dart'
    as _i750;
import 'package:app_template/Features/notes/presentation/cubits/note_form_cubit.dart'
    as _i47;
import 'package:app_template/Features/notes/presentation/cubits/notes_list_cubit.dart'
    as _i1004;
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
    gh.lazySingleton<_i27.DeviceLabelService>(() => _i27.DeviceLabelService());
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
    gh.lazySingleton<_i895.AuthApiService>(
      () => injectableModule.authApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i342.RegisterApiService>(
      () => injectableModule.registerApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i428.NotesApiService>(
      () => injectableModule.notesApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i713.MeApiService>(
      () => injectableModule.meApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i315.LogoutApiService>(
      () => injectableModule.logoutApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i294.PasswordResetApiService>(
      () => injectableModule.passwordResetApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i400.ChangePasswordApiService>(
      () => injectableModule.changePasswordApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i553.VerifyEmailApiService>(
      () => injectableModule.verifyEmailApiService(gh<_i361.Dio>()),
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
    gh.lazySingleton<_i77.VerifyEmailRemoteDataSource>(
      () => _i77.VerifyEmailRemoteDataSource(gh<_i553.VerifyEmailApiService>()),
    );
    gh.lazySingleton<_i7.ChangePasswordRemoteDataSource>(
      () => _i7.ChangePasswordRemoteDataSource(
        gh<_i400.ChangePasswordApiService>(),
      ),
    );
    gh.lazySingleton<_i615.RegisterRemoteDataSource>(
      () => _i615.RegisterRemoteDataSource(gh<_i342.RegisterApiService>()),
    );
    gh.lazySingleton<_i414.MeRemoteDataSource>(
      () => _i414.MeRemoteDataSource(gh<_i713.MeApiService>()),
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
    gh.lazySingleton<_i997.PasswordResetRemoteDataSource>(
      () => _i997.PasswordResetRemoteDataSource(
        gh<_i294.PasswordResetApiService>(),
      ),
    );
    gh.lazySingleton<_i16.LogoutRemoteDataSource>(
      () => _i16.LogoutRemoteDataSource(gh<_i315.LogoutApiService>()),
    );
    gh.lazySingleton<_i723.NotesRemoteDataSource>(
      () => _i723.NotesRemoteDataSource(gh<_i428.NotesApiService>()),
    );
    gh.lazySingleton<_i71.AuthRemoteDataSource>(
      () => _i71.AuthRemoteDataSource(
        gh<_i895.AuthApiService>(),
        gh<_i27.DeviceLabelService>(),
      ),
    );
    gh.lazySingleton<_i382.RegisterRepository>(
      () => _i278.RegisterRepositoryImpl(
        gh<_i615.RegisterRemoteDataSource>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.lazySingleton<_i276.ChangePasswordRepository>(
      () => _i716.ChangePasswordRepositoryImpl(
        gh<_i7.ChangePasswordRemoteDataSource>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.lazySingleton<_i188.AuthNetworkGateway>(
      () => injectableModule.authNetworkGateway(gh<_i512.SessionRepository>()),
    );
    gh.singleton<_i508.CurrentUserRepository>(
      () => _i508.CurrentUserRepository(gh<_i104.StorageService>()),
    );
    gh.lazySingleton<_i667.PasswordResetRepository>(
      () => _i602.PasswordResetRepositoryImpl(
        gh<_i997.PasswordResetRemoteDataSource>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.factory<_i26.ChangePasswordUseCase>(
      () => _i26.ChangePasswordUseCase(gh<_i276.ChangePasswordRepository>()),
    );
    gh.lazySingleton<_i694.LogoutRepository>(
      () => _i805.LogoutRepositoryImpl(
        gh<_i16.LogoutRemoteDataSource>(),
        gh<_i512.SessionRepository>(),
        gh<_i508.CurrentUserRepository>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.lazySingleton<_i275.AuthInterceptor>(
      () => _i275.AuthInterceptor(
        gh<_i188.AuthNetworkGateway>(),
        gh<_i702.LocaleProvider>(),
      ),
    );
    gh.factory<_i245.ChangePasswordCubit>(
      () => _i245.ChangePasswordCubit(gh<_i26.ChangePasswordUseCase>()),
    );
    gh.lazySingleton<_i319.NotesRepository>(
      () => _i6.NotesRepositoryImpl(
        gh<_i723.NotesRemoteDataSource>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.lazySingleton<_i475.MeRepository>(
      () => _i555.MeRepositoryImpl(
        gh<_i414.MeRemoteDataSource>(),
        gh<_i508.CurrentUserRepository>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.factory<_i523.RegisterUseCase>(
      () => _i523.RegisterUseCase(gh<_i382.RegisterRepository>()),
    );
    gh.factory<_i947.RegisterCubit>(
      () => _i947.RegisterCubit(gh<_i523.RegisterUseCase>()),
    );
    gh.factory<_i300.RequestResetUseCase>(
      () => _i300.RequestResetUseCase(gh<_i667.PasswordResetRepository>()),
    );
    gh.factory<_i809.ResetPasswordUseCase>(
      () => _i809.ResetPasswordUseCase(gh<_i667.PasswordResetRepository>()),
    );
    gh.lazySingleton<_i784.VerifyEmailRepository>(
      () => _i625.VerifyEmailRepositoryImpl(
        gh<_i77.VerifyEmailRemoteDataSource>(),
        gh<_i508.CurrentUserRepository>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.lazySingleton<_i337.LoginRepository>(
      () => _i631.LoginRepositoryImpl(
        gh<_i71.AuthRemoteDataSource>(),
        gh<_i512.SessionRepository>(),
        gh<_i508.CurrentUserRepository>(),
        gh<_i148.HandleBodyResponse>(),
      ),
    );
    gh.factory<_i750.ListNotesUseCase>(
      () => _i750.ListNotesUseCase(gh<_i319.NotesRepository>()),
    );
    gh.factory<_i750.SaveNoteUseCase>(
      () => _i750.SaveNoteUseCase(gh<_i319.NotesRepository>()),
    );
    gh.factory<_i750.DeleteNoteUseCase>(
      () => _i750.DeleteNoteUseCase(gh<_i319.NotesRepository>()),
    );
    gh.singleton<_i371.TokenRefreshGateway>(
      () => _i295.TokenRefreshGatewayImpl(
        gh<_i512.SessionRepository>(),
        gh<_i508.CurrentUserRepository>(),
      ),
    );
    gh.factory<_i850.LogoutUseCase>(
      () => _i850.LogoutUseCase(gh<_i694.LogoutRepository>()),
    );
    gh.factory<_i974.ForgotPasswordCubit>(
      () => _i974.ForgotPasswordCubit(
        gh<_i300.RequestResetUseCase>(),
        gh<_i809.ResetPasswordUseCase>(),
      ),
    );
    gh.factory<_i848.ResendVerificationUseCase>(
      () => _i848.ResendVerificationUseCase(gh<_i784.VerifyEmailRepository>()),
    );
    gh.factory<_i179.VerifyEmailUseCase>(
      () => _i179.VerifyEmailUseCase(gh<_i784.VerifyEmailRepository>()),
    );
    gh.factory<_i478.LogoutCubit>(
      () => _i478.LogoutCubit(gh<_i850.LogoutUseCase>()),
    );
    gh.factory<_i351.GetCurrentUserUseCase>(
      () => _i351.GetCurrentUserUseCase(gh<_i475.MeRepository>()),
    );
    gh.factory<_i1004.NotesListCubit>(
      () => _i1004.NotesListCubit(
        gh<_i750.ListNotesUseCase>(),
        gh<_i750.DeleteNoteUseCase>(),
      ),
    );
    gh.factory<_i680.VerifyEmailCubit>(
      () => _i680.VerifyEmailCubit(
        gh<_i179.VerifyEmailUseCase>(),
        gh<_i848.ResendVerificationUseCase>(),
      ),
    );
    gh.factory<_i47.NoteFormCubit>(
      () => _i47.NoteFormCubit(gh<_i750.SaveNoteUseCase>()),
    );
    gh.factory<_i779.LoginUseCase>(
      () => _i779.LoginUseCase(gh<_i337.LoginRepository>()),
    );
    gh.lazySingleton<_i723.SessionSyncService>(
      () => _i723.SessionSyncService(
        gh<_i512.SessionRepository>(),
        gh<_i351.GetCurrentUserUseCase>(),
      ),
    );
    gh.factory<_i21.LoginCubit>(
      () => _i21.LoginCubit(gh<_i779.LoginUseCase>()),
    );
    return this;
  }
}

class _$InjectableModule extends _i321.InjectableModule {}
