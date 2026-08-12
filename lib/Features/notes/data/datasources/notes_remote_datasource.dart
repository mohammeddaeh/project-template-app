import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/Features/notes/data/datasources/notes_api_service.dart';
import 'package:app_template/Features/notes/data/dtos/note_request_dto.dart';
import 'package:app_template/Features/notes/data/models/note_model.dart';
import 'package:app_template/Features/notes/data/models/notes_page_model.dart';

@lazySingleton
class NotesRemoteDataSource {
  NotesRemoteDataSource(this._apiService);

  final NotesApiService _apiService;

  Future<ApiResponse<NotesPageModel>> list({
    required int page,
    required int limit,
  }) async {
    final response = await _apiService.list(page, limit);
    return _parse(response.data, NotesPageModel.fromJson);
  }

  Future<ApiResponse<NoteModel>> create(NoteRequestDto body) async {
    final response = await _apiService.create(body);
    return _parse(response.data, NoteModel.fromJson);
  }

  Future<ApiResponse<NoteModel>> update(int id, NoteRequestDto body) async {
    final response = await _apiService.update(id, body);
    return _parse(response.data, NoteModel.fromJson);
  }

  /// Delete answers `{status, message, data: null}` — there is nothing to
  /// parse, only a status to read.
  ///
  /// Typed `Object?` rather than `void` so the shared [_parse] can be reused:
  /// a `void`-returning callback cannot legally produce the `null` the generic
  /// signature needs. The repository ignores the value either way.
  Future<ApiResponse<Object?>> delete(int id) async {
    final response = await _apiService.delete(id);
    return _parse<Object?>(response.data, (_) => null);
  }

  /// One envelope reader for all four calls.
  ///
  /// `ApiResponse.fromJson` is deliberately not used: this server sends
  /// `status` as a **bool**, and that helper casts it to `String` and throws
  /// `ParseFailure` on every successful response. Every datasource in this
  /// template unpacks the envelope by hand for the same reason — see
  /// `core/CLAUDE.md` §API-GENERATOR.
  ApiResponse<T> _parse<T>(
    dynamic raw,
    T? Function(Map<String, dynamic>) fromJson,
  ) {
    final json = raw as Map<String, dynamic>;
    final statusBool = json['status'] as bool? ?? false;
    final message = json['message'] as String? ?? '';

    if (!statusBool) {
      return ApiResponse<T>(
        status: 'error',
        message: message,
        data: null,
        error: ApiError(
          code: json['code'] as int? ?? 400,
          message: message,
          data: json['data'] as Map<String, dynamic>?,
        ),
      );
    }

    final dataJson = json['data'] as Map<String, dynamic>?;
    return ApiResponse<T>(
      status: 'success',
      message: message,
      data: dataJson != null ? fromJson(dataJson) : null,
      error: null,
    );
  }
}
