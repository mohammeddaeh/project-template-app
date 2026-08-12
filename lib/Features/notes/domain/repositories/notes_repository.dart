import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/notes/domain/entities/note.dart';
import 'package:app_template/Features/notes/domain/params/note_params.dart';

abstract interface class NotesRepository {
  Future<Either<Failure, PaginationDataEntity<Note>>> list(
    ListNotesParams params,
  );

  /// Creates when `params.id` is null, updates otherwise. Returns the saved
  /// note so the list can insert or replace it without re-fetching the page.
  Future<Either<Failure, Note>> save(SaveNoteParams params);

  Future<Either<Failure, void>> delete(DeleteNoteParams params);
}
