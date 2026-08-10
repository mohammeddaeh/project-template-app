import 'package:dio/dio.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/Features/auth/forgot_password/data/dtos/request_reset_dto.dart';
import 'package:app_template/Features/auth/forgot_password/data/dtos/reset_password_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'password_reset_api_service.g.dart';

/// Both steps of the reset journey live on one service because they are one
/// journey — splitting them would mean two DI registrations for a flow the user
/// experiences as a single task.
///
/// **Neither endpoint is authenticated**, by definition: the whole point is
/// that the caller cannot sign in.
@RestApi()
abstract class PasswordResetApiService {
  factory PasswordResetApiService(Dio dio) =>
      _PasswordResetApiService(dio, baseUrl: Env.baseUrl);

  @POST(ApiUrls.forgotPassword)
  Future<HttpResponse<dynamic>> requestReset(@Body() RequestResetDto body);

  @POST(ApiUrls.resetPassword)
  Future<HttpResponse<dynamic>> resetPassword(@Body() ResetPasswordDto body);
}
