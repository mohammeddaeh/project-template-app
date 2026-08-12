import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';

part 'data_transfer_api_service.g.dart';

/// The **JSON** half of the data-transfer API.
///
/// `/export` and `/template` are deliberately absent: they answer file bytes,
/// and putting them here would invite a caller to reach them through the same
/// envelope-parsing path as everything else, which reports an error over a
/// valid file. They live in `transfer_file_downloader.dart`.
@RestApi()
abstract class DataTransferApiService {
  factory DataTransferApiService(Dio dio) =>
      _DataTransferApiService(dio, baseUrl: Env.baseUrl);

  /// Everything this backend can import or export. Drives the entire UI.
  @GET(ApiUrls.transferResources)
  Future<HttpResponse<dynamic>> resources();

  /// Phase one — upload and validate. Writes nothing server-side.
  ///
  /// `@Part()` with a `MultipartFile`, not a raw body: the server reads the
  /// file from a multipart field literally named `file`.
  @POST('/data-transfer/{resource}/import')
  @MultiPart()
  Future<HttpResponse<dynamic>> validateImport(
    @Path('resource') String resource,
    @Part(name: 'file') MultipartFile file, {
    @Query('mode') String mode = 'validate',
  });

  /// Phase two — spend the token. All rows or none.
  @POST('/data-transfer/{resource}/import')
  Future<HttpResponse<dynamic>> commitImport(
    @Path('resource') String resource,
    @Body() Map<String, dynamic> body, {
    @Query('mode') String mode = 'commit',
  });
}
