import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/Features/notes/data/datasources/notes_remote_datasource.dart';
import 'package:app_template/Features/notes/data/dtos/note_request_dto.dart';
import 'package:app_template/Features/notes/domain/entities/note.dart';
import 'package:app_template/Features/notes/domain/params/note_params.dart';
import 'package:app_template/Features/notes/domain/repositories/notes_repository.dart';

@LazySingleton(as: NotesRepository)
class NotesRepositoryImpl extends BaseRepository implements NotesRepository {
  NotesRepositoryImpl(this._dataSource, HandleBodyResponse handler)
      : super(handler);

  final NotesRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, PaginationDataEntity<Note>>> list(
    ListNotesParams params,
  ) => handle(() async {
        final res = await _dataSource.list(
          page: params.paginationQuery.page,
          limit: params.paginationQuery.perPage,
        );
        if (res.error != null) return Left(_business(res));
        if (res.data == null) return const Left(BusinessFailure(statusCode: 400));
        return Right(res.data!.toEntity());
      });

  @override
  Future<Either<Failure, Note>> save(SaveNoteParams params) => handle(() async {
        final dto = NoteRequestDto(title: params.title, body: params.body);
        // The one branch that decides create vs update, and it is here rather
        // than in the cubit so the screen never has to know which call it made.
        final res = params.id == null
            ? await _dataSource.create(dto)
            : await _dataSource.update(params.id!, dto);

        if (res.error != null) return Left(_business(res));
        if (res.data == null) return const Left(BusinessFailure(statusCode: 400));
        return Right(res.data!.toEntity());
      });

  @override
  Future<Either<Failure, void>> delete(DeleteNoteParams params) =>
      handle(() async {
        final res = await _dataSource.delete(params.id);
        if (res.error != null) return Left(_business(res));
        return const Right(null);
      });

  /// Nothing changes behind an online-only repository's back: every row it
  /// serves came from a request the caller made, and there is no local store
  /// for a background process to write into.
  @override
  Stream<void> watch() => const Stream<void>.empty();

  /// A 422 arrives with `errors: {field: [messages]}`, and `HandleBodyResponse`
  /// already turned that into the message carried here — so the form shows the
  /// server's own wording for "title is required" rather than a local guess at
  /// what the server checks.
  Failure _business(dynamic res) => BusinessFailure(
        statusCode: (res.error?.code as int?) ?? 400,
        serverMessage:
            (res.message as String).isNotEmpty ? res.message as String : null,
      );
}
