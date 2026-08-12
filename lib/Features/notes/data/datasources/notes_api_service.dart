import 'package:dio/dio.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/Features/notes/data/dtos/note_request_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'notes_api_service.g.dart';

@RestApi()
abstract class NotesApiService {
  factory NotesApiService(Dio dio) => _NotesApiService(dio, baseUrl: Env.baseUrl);

  @GET(ApiUrls.notes)
  Future<HttpResponse<dynamic>> list(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST(ApiUrls.notes)
  Future<HttpResponse<dynamic>> create(@Body() NoteRequestDto body);

  @PATCH('${ApiUrls.notes}/{id}')
  Future<HttpResponse<dynamic>> update(
    @Path('id') int id,
    @Body() NoteRequestDto body,
  );

  @DELETE('${ApiUrls.notes}/{id}')
  Future<HttpResponse<dynamic>> delete(@Path('id') int id);
}
