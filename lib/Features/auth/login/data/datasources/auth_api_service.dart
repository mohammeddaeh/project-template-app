import 'package:dio/dio.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/Features/auth/login/data/dtos/login_request_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api_service.g.dart';

@RestApi()
abstract class AuthApiService {
  factory AuthApiService(Dio dio) => _AuthApiService(dio, baseUrl: Env.baseUrl);

  @POST(ApiUrls.login)
  Future<HttpResponse<dynamic>> login(@Body() LoginRequestDto body);
}
