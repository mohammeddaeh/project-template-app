import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

import '../data/device_session_api_service.dart';
import '../data/device_session_repository_impl.dart';
import '../domain/device_session_repository.dart';
import '../interceptor/multi_device_interceptor.dart';
import '../presentation/active_devices_cubit.dart';
import '../services/device_id_service.dart';
import '../services/device_notification_handler.dart';

/// Registers all Multi-Device module dependencies in [GetIt]
/// and inserts [MultiDeviceInterceptor] at the front of Dio's interceptor list.
///
/// Called once from [MultiDevicePlugin.initialize].
Future<void> registerMultiDeviceCore(GetIt di) async {
  if (!di.isRegistered<DeviceIdService>()) {
    di.registerSingleton<DeviceIdService>(
      DeviceIdService(di<StorageService>(), di<Uuid>()),
    );
  }

  if (!di.isRegistered<DeviceNotificationHandler>()) {
    di.registerLazySingleton<DeviceNotificationHandler>(
      () => DeviceNotificationHandler(di<DeviceIdService>()),
    );
  }

  if (!di.isRegistered<MultiDeviceInterceptor>()) {
    di.registerLazySingleton<MultiDeviceInterceptor>(
      () => MultiDeviceInterceptor(di<DeviceIdService>()),
    );
  }

  if (!di.isRegistered<DeviceSessionApiService>()) {
    di.registerLazySingleton<DeviceSessionApiService>(
      () => DeviceSessionApiService(di<Dio>()),
    );
  }

  if (!di.isRegistered<DeviceSessionRepository>()) {
    di.registerLazySingleton<DeviceSessionRepository>(
      () => DeviceSessionRepositoryImpl(
        di<DeviceSessionApiService>(),
        di<HandleBodyResponse>(),
      ),
    );
  }

  if (!di.isRegistered<ActiveDevicesCubit>()) {
    di.registerFactory<ActiveDevicesCubit>(
      () => ActiveDevicesCubit(di<DeviceSessionRepository>()),
    );
  }

  // Insert MultiDeviceInterceptor at position 0 so it runs before AuthInterceptor
  // and can intercept SESSION_REVOKED before the generic 401 handler.
  final dio = di<Dio>();
  final mdInterceptor = di<MultiDeviceInterceptor>();
  if (!dio.interceptors.any((i) => i is MultiDeviceInterceptor)) {
    dio.interceptors.insert(0, mdInterceptor);
  }
}
