import 'package:dio/dio.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:retrofit/retrofit.dart';

part 'logout_api_service.g.dart';

@RestApi()
abstract class LogoutApiService {
  factory LogoutApiService(Dio dio) =>
      _LogoutApiService(dio, baseUrl: Env.baseUrl);

  @POST(ApiUrls.logout)
  Future<HttpResponse<dynamic>> logout();
}
