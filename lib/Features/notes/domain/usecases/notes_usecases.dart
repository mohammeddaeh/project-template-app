import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/notes/domain/entities/note.dart';
import 'package:app_template/Features/notes/domain/params/note_params.dart';
import 'package:app_template/Features/notes/domain/repositories/notes_repository.dart';

/// Three use cases in one file — they are three lines each and share a single
/// repository. Splitting them across three files would triple the imports
/// without separating anything.
@injectable
class ListNotesUseCase extends BaseUseCase<
    Either<Failure, PaginationDataEntity<Note>>, ListNotesParams> {
  ListNotesUseCase(this._repository);
  final NotesRepository _repository;

  @override
  Future<Either<Failure, PaginationDataEntity<Note>>> call(
    covariant ListNotesParams params,
  ) => _repository.list(params);
}

@injectable
class SaveNoteUseCase extends BaseUseCase<Either<Failure, Note>, SaveNoteParams> {
  SaveNoteUseCase(this._repository);
  final NotesRepository _repository;

  @override
  Future<Either<Failure, Note>> call(covariant SaveNoteParams params) =>
      _repository.save(params);
}

@injectable
class DeleteNoteUseCase
    extends BaseUseCase<Either<Failure, void>, DeleteNoteParams> {
  DeleteNoteUseCase(this._repository);
  final NotesRepository _repository;

  @override
  Future<Either<Failure, void>> call(covariant DeleteNoteParams params) =>
      _repository.delete(params);
}
