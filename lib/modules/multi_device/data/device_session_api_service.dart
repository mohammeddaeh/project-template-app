import 'package:dio/dio.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/modules/multi_device/data/multi_device_urls.dart';
import 'package:retrofit/retrofit.dart';

part 'device_session_api_service.g.dart';

/// Session endpoints, as the server actually serves them.
///
/// ## Why these paths
///
/// The endpoints built and tested in `backend_template/src/features/auth/`
/// (`/auth/sessions`) — not `/auth/devices`, which has never existed on the
/// backend and would answer 404 on every call: a finished-looking screen wired
/// to nothing.
///
/// `logout` is deliberately absent. It lives in `Features/auth/logout/` and is
/// reachable from every screen through `LogoutSection`; a second definition
/// here would be a second thing to keep correct.
@RestApi()
abstract class DeviceSessionApiService {
  factory DeviceSessionApiService(Dio dio) =>
      _DeviceSessionApiService(dio, baseUrl: Env.baseUrl);

  /// Live sessions for the calling account, most recently active first.
  @GET(MultiDeviceUrls.sessions)
  Future<HttpResponse<dynamic>> getSessions();

  /// Ends one session. A session that does not exist and one belonging to
  /// somebody else both answer 404, so iterating ids reveals nothing.
  @DELETE('${MultiDeviceUrls.sessions}/{id}')
  Future<HttpResponse<dynamic>> revokeSession(@Path('id') int id);

  /// Ends every other session, sparing the caller's own.
  @POST(MultiDeviceUrls.revokeOtherSessions)
  Future<HttpResponse<dynamic>> revokeOthers();
}
