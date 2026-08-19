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

  /// `Idempotency-Key` is optional here and mandatory for the sync executor.
  ///
  /// An online caller pressing "save" once does not need it. A queued write
  /// does: the connection can die **after** the server committed and before the
  /// response arrives, and the queue has no way to tell that from a request
  /// that never landed — so its only correct move is to send it again. Without
  /// the key that second attempt is a second note.
  ///
  /// Null headers are dropped by the generated client, so the online path sends
  /// exactly what it always did.
  /// Everything that changed after the cursor — the pull half of sync.
  ///
  /// A **separate route** from the list, not `?updated_since=` on it: the list
  /// is `created_at DESC`, page-numbered and hides tombstones because it feeds
  /// a screen; the delta is `updated_at ASC`, keyset-cursored and must carry
  /// tombstones because it feeds a replica. One path with two orderings and two
  /// response shapes, chosen by whether a parameter happens to be present, is a
  /// contract the first reader gets wrong.
  @GET('${ApiUrls.notes}/delta')
  Future<HttpResponse<dynamic>> delta({
    @Query('updated_since') String? updatedSince,
    @Query('after_id') String? afterId,
    @Query('include_deleted') String? includeDeleted,
    @Query('limit') int? limit,
  });

  @POST(ApiUrls.notes)
  Future<HttpResponse<dynamic>> create(
    @Body() NoteRequestDto body, {
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  @PATCH('${ApiUrls.notes}/{id}')
  Future<HttpResponse<dynamic>> update(
    @Path('id') String id,
    @Body() NoteRequestDto body, {
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// `version` makes the delete conditional — the same optimistic check `PATCH`
  /// gets. Omitted by the online path, sent by the queue.
  @DELETE('${ApiUrls.notes}/{id}')
  Future<HttpResponse<dynamic>> delete(
    @Path('id') String id, {
    @Query('version') int? version,
    @Header('Idempotency-Key') String? idempotencyKey,
  });
}
