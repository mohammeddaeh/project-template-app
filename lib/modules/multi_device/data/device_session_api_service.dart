import 'package:dio/dio.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:retrofit/retrofit.dart';

part 'device_session_api_service.g.dart';

/// Raw Retrofit service for device-session endpoints.
///
/// Notes on return types:
/// - [getDevices] returns [HttpResponse<dynamic>] — raw JSON, parsed in repository.
/// - Mutation endpoints return [void] — success is inferred from HTTP 200;
///   failures are thrown as [DioException] and caught by [HandleBodyResponse].
@RestApi()
abstract class DeviceSessionApiService {
  factory DeviceSessionApiService(Dio dio) =>
      _DeviceSessionApiService(dio, baseUrl: Env.baseUrl);

  /// Returns the list of active sessions for the authenticated user.
  @GET('/auth/devices')
  Future<HttpResponse<dynamic>> getDevices();

  /// Revokes a specific session. Only the primary device may call this.
  @DELETE('/auth/devices/{deviceSessionId}')
  Future<HttpResponse<dynamic>> revokeDevice(
    @Path('deviceSessionId') String deviceSessionId,
  );

  /// Revokes all sessions except the current one.
  @DELETE('/auth/devices/all-except-current')
  Future<void> revokeAllExceptCurrent();

  /// Logs out the current device — revokes this session only.
  @POST('/auth/logout')
  Future<void> logout();
}
