import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';

part 'access_control_api_service.g.dart';

/// `/api/v1/authz/*`.
///
/// Every method returns `HttpResponse<dynamic>` and is unwrapped by the
/// repository, matching every other datasource here: the API's `status` is a
/// **bool**, and a generated `ApiResponse.fromJson` casts it to `String` and
/// throws on a request that succeeded.
@RestApi()
abstract class AccessControlApiService {
  factory AccessControlApiService(Dio dio) =>
      _AccessControlApiService(dio, baseUrl: Env.baseUrl);

  /// The caller's own resolved permissions. No permission required.
  @GET(ApiUrls.authzMe)
  Future<HttpResponse<dynamic>> myAbilities({
    @Query('include_declared') bool? includeDeclared,
  });

  /// Every permission the server declares. Requires `roles.view`.
  @GET(ApiUrls.authzCatalog)
  Future<HttpResponse<dynamic>> catalog();

  @GET(ApiUrls.authzRoles)
  Future<HttpResponse<dynamic>> roles({
    @Query('page') int page = 1,
    @Query('limit') int limit = 50,
  });

  @POST(ApiUrls.authzRoles)
  Future<HttpResponse<dynamic>> createRole(@Body() Map<String, dynamic> body);

  @PATCH('/authz/roles/{id}')
  Future<HttpResponse<dynamic>> renameRole(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  /// PUT, not PATCH — a checkbox screen knows the final state and nothing else.
  @PUT('/authz/roles/{id}/permissions')
  Future<HttpResponse<dynamic>> setRolePermissions(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/authz/roles/{id}/deactivate')
  Future<HttpResponse<dynamic>> deactivateRole(@Path('id') int id);

  @POST('/authz/roles/{id}/activate')
  Future<HttpResponse<dynamic>> activateRole(@Path('id') int id);

  @GET('/authz/users/{userId}/access')
  Future<HttpResponse<dynamic>> userAccess(@Path('userId') int userId);

  @PUT('/authz/users/{userId}/roles')
  Future<HttpResponse<dynamic>> setUserRoles(
    @Path('userId') int userId,
    @Body() Map<String, dynamic> body,
  );

  @PUT('/authz/users/{userId}/overrides')
  Future<HttpResponse<dynamic>> setUserOverrides(
    @Path('userId') int userId,
    @Body() Map<String, dynamic> body,
  );
}
