import 'package:dio/dio.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:retrofit/retrofit.dart';

part 'me_api_service.g.dart';

@RestApi()
abstract class MeApiService {
  factory MeApiService(Dio dio) => _MeApiService(dio, baseUrl: Env.baseUrl);

  @GET(ApiUrls.me)
  Future<HttpResponse<dynamic>> getCurrentUser();
}
