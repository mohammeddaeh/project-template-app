import 'package:dio/dio.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/Features/auth/verify_email/data/dtos/verify_email_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'verify_email_api_service.g.dart';

/// Both calls of the verification journey — spend a code, or ask for a new one.
///
/// **Both are authenticated**, which looks odd for a flow that gates account
/// setup and is the deliberate choice: a `pending_verification` account signs
/// in successfully and receives a real session precisely so it can reach these
/// two endpoints. The session unlocks nothing else — such an account holds no
/// role assignment, so its permission set is empty. Refusing the session
/// instead would leave anyone who reinstalls the app holding an account they
/// can neither use nor repair.
@RestApi()
abstract class VerifyEmailApiService {
  factory VerifyEmailApiService(Dio dio) =>
      _VerifyEmailApiService(dio, baseUrl: Env.baseUrl);

  @POST(ApiUrls.verifyEmail)
  Future<HttpResponse<dynamic>> verifyEmail(@Body() VerifyEmailDto body);

  @POST(ApiUrls.resendVerification)
  Future<HttpResponse<dynamic>> resendVerification();
}
