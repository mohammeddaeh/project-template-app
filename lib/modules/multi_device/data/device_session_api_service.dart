import 'package:dio/dio.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:retrofit/retrofit.dart';

part 'device_session_api_service.g.dart';

/// Session endpoints, as the server actually serves them.
///
/// ## Retargeted 2026-08-11
///
/// This service used to point at `/auth/devices`,
/// `/auth/devices/{id}` and `/auth/devices/all-except-current` — paths that
/// **have never existed on the backend**. Enabling `AppFeatures.multiDevice`
/// would have produced a 404 on every call: a finished-looking screen wired to
/// nothing. It now targets the endpoints built and tested in
/// `qirtas_backend/src/features/auth/`.
///
/// `logout` is deliberately absent. It lives in `Features/auth/logout/` and is
/// reachable from every screen through `LogoutSection`; a second definition
/// here would be a second thing to keep correct.
@RestApi()
abstract class DeviceSessionApiService {
  factory DeviceSessionApiService(Dio dio) =>
      _DeviceSessionApiService(dio, baseUrl: Env.baseUrl);

  /// Live sessions for the calling account, most recently active first.
  @GET(ApiUrls.sessions)
  Future<HttpResponse<dynamic>> getSessions();

  /// Ends one session. A session that does not exist and one belonging to
  /// somebody else both answer 404, so iterating ids reveals nothing.
  @DELETE('${ApiUrls.sessions}/{id}')
  Future<HttpResponse<dynamic>> revokeSession(@Path('id') int id);

  /// Ends every other session, sparing the caller's own.
  @POST(ApiUrls.revokeOtherSessions)
  Future<HttpResponse<dynamic>> revokeOthers();
}
