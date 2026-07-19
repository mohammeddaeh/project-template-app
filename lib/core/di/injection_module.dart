// ignore_for_file: deprecated_member_use

import 'package:awesome_dio_interceptor/awesome_dio_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:app_template/core/foundation/contracts/auth_network_gateway.dart';
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

  /// Secure encrypted storage — tokens and credentials only.
  /// Adapter: [FlutterSecureStorageAdapter] (Keychain / Keystore).
  /// NEVER store tokens in [StorageService].
  @lazySingleton
  SecureStorageService secureStorageService() => FlutterSecureStorageAdapter(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

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
      // 1. Network guard: blocks requests immediately when device is offline
      getIt<InternetCheckerInterceptor>(),

      // 2. Auth: injects Bearer token + Accept-Language header
      authInterceptor,

      // 3. Token refresh: silently refreshes on 401 + retries original request.
      //    Active only when the project registers a TokenRefreshGateway impl.
      //    Created here (not via GetIt) to avoid a circular Dio dependency.
      if (hasRefresh)
        TokenRefreshInterceptor(
          dio,
          getIt<TokenRefreshGateway>(),
          getIt<AuthNetworkGateway>(),
        ),

      // 4. Retry: exponential back-off on 5xx / connection errors (max 3 times)
      RetryInterceptor(dio),

      // 5. Response cache: serves GET responses from local storage within TTL
      RequestCacheInterceptor(getIt<StorageService>()),

      // 6. Dev-only: pretty-prints requests & responses to console (last = full picture)
      if (kDebugMode) AwesomeDioInterceptor(logger: debugPrint),
    ]);

    return dio;
  }

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
