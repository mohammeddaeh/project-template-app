import 'package:dio/dio.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/Features/auth/change_password/data/dtos/change_password_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'change_password_api_service.g.dart';

/// **Authenticated** — `AuthInterceptor` attaches the bearer token, so a 401
/// here means the session died mid-form and the central handler routes to
/// login. Nothing feature-level needs to react to that.
@RestApi()
abstract class ChangePasswordApiService {
  factory ChangePasswordApiService(Dio dio) =>
      _ChangePasswordApiService(dio, baseUrl: Env.baseUrl);

  @POST(ApiUrls.changePassword)
  Future<HttpResponse<dynamic>> changePassword(@Body() ChangePasswordDto body);
}
