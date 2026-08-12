import 'package:dio/dio.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/Features/auth/register/data/dtos/register_request_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'register_api_service.g.dart';

@RestApi()
abstract class RegisterApiService {
  factory RegisterApiService(Dio dio) =>
      _RegisterApiService(dio, baseUrl: Env.baseUrl);

  @POST(ApiUrls.register)
  Future<HttpResponse<dynamic>> register(@Body() RegisterRequestDto body);
}
