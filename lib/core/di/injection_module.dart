// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:app_template/Features/auth/change_password/data/datasources/change_password_api_service.dart';
import 'package:app_template/Features/auth/verify_email/data/datasources/verify_email_api_service.dart';
import 'package:app_template/Features/auth/forgot_password/data/datasources/password_reset_api_service.dart';
import 'package:app_template/Features/auth/me/data/datasources/me_api_service.dart';
import 'package:app_template/Features/auth/logout/data/datasources/logout_api_service.dart';
import 'package:app_template/Features/auth/login/data/datasources/auth_api_service.dart';
import 'package:app_template/Features/auth/register/data/datasources/register_api_service.dart';
import 'package:app_template/Features/notes/data/datasources/notes_api_service.dart';
import 'package:app_template/core/foundation/contracts/auth_network_gateway.dart';
import 'package:app_template/core/foundation/contracts/unsynced_work_probe.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/core/foundation/contracts/token_refresh_gateway.dart';
import 'package:app_template/core/infra/network/interceptors/auth_interceptor.dart';
import 'package:app_template/core/infra/network/interceptors/internet_checker_interceptor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/notifications/adapters/disabled_notifications_adapter.dart';
import 'package:app_template/core/platform/notifications/adapters/fln_notifications_adapter.dart';
import 'package:app_template/core/platform/notifications/local_notifications_service.dart';
import 'package:app_template/core/infra/network/interceptors/request_cache_interceptor.dart';
import 'package:app_template/core/infra/network/interceptors/network_log_interceptor.dart';
import 'package:app_template/core/infra/network/interceptors/retry_interceptor.dart';
import 'package:app_template/core/infra/network/interceptors/token_refresh_interceptor.dart';
import 'package:app_template/core/platform/storage/adapters/aes_encryption_adapter.dart';
import 'package:app_template/core/platform/storage/adapters/flutter_secure_storage_adapter.dart';
import 'package:app_template/core/platform/storage/adapters/hive_storage_adapter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_template/core/platform/storage/encryption_service.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/presentation/feedback/adapters/motion_toast_adapter.dart';
import 'package:app_template/presentation/feedback/app_feedback_service.dart';
import 'package:app_template/routes/router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'injection.dart';

@module
abstract class InjectableModule {
  @lazySingleton
  InternetConnectionChecker get connectionChecker =>
      InternetConnectionChecker.instance;

  @lazySingleton
  Connectivity get connectivity => Connectivity();

  /// Opens the Hive box used by [StorageService] before DI wires up.
  /// Box name: 'app_storage' — isolated from any other Hive boxes.
  @preResolve
  @lazySingleton
  Future<Box<dynamic>> get appStorageBox =>
      Hive.openBox<dynamic>('app_storage');

  /// General key-value storage — non-sensitive data only (theme, locale, etc.).
  /// Current adapter: [HiveStorageAdapter] (reads are synchronous after open).
  /// To swap backend: replace the adapter here — no other code changes needed.
  @lazySingleton
  StorageService storageService(Box<dynamic> box) =>
      HiveStorageAdapter(box);

  /// Resolved before DI finishes, because the one thing that asks for it does so
  /// **synchronously**: `registerSyncCore` binds
  /// `SharedPrefsSyncSettingsStore(getIt())`, and `SyncSDK.initialize` resolves
  /// that store as its first act. Registered async without `@preResolve`, the
  /// synchronous `getIt<SharedPreferences>()` would throw "not ready yet"
  /// instead — the same failure one word further along.
  ///
  /// It was missing entirely until now, and the shape of that absence is worth
  /// keeping in mind: the binding is lazy, so nothing failed at registration.
  /// `SyncSDK.initialize` caught the throw, logged it, and disabled the module —
  /// so `AppFeatures.offlineSync = true` produced an app that ran fully online,
  /// with no crash, no red test and a clean `dart analyze`.
  ///
  /// This is a *second* persistence backend next to [StorageService]'s Hive box,
  /// used by the sync module alone. That duplication is recorded as ب١٢ in
  /// `lib/modules/sync/PLAN.md` and is deliberately not addressed here.
  @preResolve
  @lazySingleton
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  /// Secure encrypted storage — tokens and credentials only.
  /// Adapter: [FlutterSecureStorageAdapter] (Keychain / Keystore).
  /// NEVER store tokens in [StorageService].
  @lazySingleton
  SecureStorageService secureStorageService() => FlutterSecureStorageAdapter(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  /// Asked by anything destructive — signing out, switching accounts — before
  /// it acts.
  ///
  /// The default answers zero, which is the truth for an app with no offline
  /// queue. `registerSyncCore` replaces it with a queue-backed implementation
  /// when the sync module is switched on, so no caller ever has to ask whether
  /// it is — a question none of them should be able to answer.
  @lazySingleton
  UnsyncedWorkProbe get unsyncedWorkProbe => const NoUnsyncedWorkProbe();

  /// Symmetric encryption for sensitive data stored in [StorageService].
  /// Default adapter: [AesEncryptionAdapter] (AES-256-CBC + HMAC-SHA256,
  /// HKDF-derived keys — authenticated encryption).
  /// Swap algorithm: replace adapter here — no feature code changes needed.
  @lazySingleton
  EncryptionService get encryptionService => AesEncryptionAdapter();

  // ── Platform services (P6-P10) ─────────────────────────────────────────────
  // Registered conditionally via PlatformServicesRegistry (see injection.dart).
  // Enable/disable each service in AppFeatures — no changes needed here.

  @lazySingleton
  Dio get dioInstance {
    final dio = Dio(
      BaseOptions(
        headers: {'Accept': 'application/json'},
        contentType: 'application/json',
        connectTimeout: const Duration(minutes: 1),
        receiveTimeout: const Duration(minutes: 1),
        sendTimeout: const Duration(minutes: 1),
      ),
    );

    // Auth owns 401-driven session expiry ONLY when no refresh layer is wired.
    // With a TokenRefreshInterceptor present, that layer owns 401 recovery
    // (silent refresh + retry, and emits sessionExpired on refresh failure),
    // so Auth must not pre-empt it by clearing the session first.
    final hasRefresh = getIt.isRegistered<TokenRefreshGateway>();

    final authInterceptor = getIt<AuthInterceptor>();
    // Auth handles 401 expiry only when no refresh layer is wired.
    authInterceptor.handlesSessionExpiry = !hasRefresh;

    dio.interceptors.addAll([
      // 1. Response cache: serves opt-in GETs from local storage within TTL.
      //
      //    FIRST, ahead of the offline guard, and that order is the whole
      //    point of the module. Dio runs `onRequest` hooks in registration
      //    order, so with the guard in front an offline device was rejected
      //    before the cache was ever consulted — the cache went dark in
      //    precisely the situation it exists for. A cached list the user read
      //    a minute ago is a better answer than "no internet".
      RequestCacheInterceptor(getIt<StorageService>()),

      // 2. Network guard: blocks requests immediately when device is offline.
      //    Reached only for requests the cache could not answer.
      getIt<InternetCheckerInterceptor>(),

      // 3. Auth: injects Bearer token + Accept-Language header
      authInterceptor,

      // 4. Token refresh: silently refreshes on 401 + retries original request.
      //    Active only when the project registers a TokenRefreshGateway impl.
      //    Created here (not via GetIt) to avoid a circular Dio dependency.
      if (hasRefresh)
        TokenRefreshInterceptor(
          dio,
          getIt<TokenRefreshGateway>(),
          getIt<AuthNetworkGateway>(),
        ),

      // 5. Retry: exponential back-off on 5xx / connection errors (max 3 times)
      RetryInterceptor(dio),

      // 6. Dev-only logging, last so it sees the final outcome after auth,
      //    retry and cache have had their say. One line per success, the whole
      //    picture on failure — the previous full-dump logger printed hundreds
      //    of lines per launch and buried real errors in them. Flip `verbose`
      //    for a single debugging session when you need the firehose back.
      if (kDebugMode)
        NetworkLogInterceptor(verbose: AppFeatures.verboseNetworkLog),
    ]);

    return dio;
  }

  // ── Feature ApiServices ───────────────────────────────────────────────────
  // Registered here and not with `@injectable`, because a `@RestApi()` class is
  // abstract and generated — the annotation cannot be placed on it. Every new
  // feature adds one line in this block.

  @lazySingleton
  AuthApiService authApiService(Dio dio) => AuthApiService(dio);

  @lazySingleton
  RegisterApiService registerApiService(Dio dio) => RegisterApiService(dio);

  /// Reference feature — delete with `Features/notes/`.
  @lazySingleton
  NotesApiService notesApiService(Dio dio) => NotesApiService(dio);

  @lazySingleton
  MeApiService meApiService(Dio dio) => MeApiService(dio);

  @lazySingleton
  LogoutApiService logoutApiService(Dio dio) => LogoutApiService(dio);

  @lazySingleton
  PasswordResetApiService passwordResetApiService(Dio dio) =>
      PasswordResetApiService(dio);

  @lazySingleton
  ChangePasswordApiService changePasswordApiService(Dio dio) =>
      ChangePasswordApiService(dio);

  @lazySingleton
  VerifyEmailApiService verifyEmailApiService(Dio dio) =>
      VerifyEmailApiService(dio);

  @lazySingleton
  Uuid get uuid {
    return const Uuid();
  }

  @lazySingleton
  AppRouter get router => AppRouter();

  /// Registered only when [AppFeatures.localNotifications] is enabled.
  /// Adapter: [FlnNotificationsAdapter] (flutter_local_notifications).
  /// Swap adapter here — no other code changes needed.
  @lazySingleton
  LocalNotificationsService get localNotifications =>
      AppFeatures.localNotifications
      ? FlnNotificationsAdapter()
      : DisabledNotificationsAdapter();

  /// In-app feedback (toasts, snackbars).
  /// Default adapter: [MotionToastAdapter].
  /// Swap adapter here — no Feature or Cubit code needs to change.
  @lazySingleton
  AppFeedbackService get feedbackService => MotionToastAdapter();

  /// Expose [SessionRepository] under the [AuthNetworkGateway] abstract type
  /// so that [AuthInterceptor] can depend on the interface, not the concrete class.
  @lazySingleton
  AuthNetworkGateway authNetworkGateway(SessionRepository repo) => repo;
}
