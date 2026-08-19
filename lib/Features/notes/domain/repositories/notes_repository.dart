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

  /// Fires when the notes this device holds change underneath the caller —
  /// a sync pulled an edit made elsewhere, or a queued write finished.
  ///
  /// **Empty for an online-only build**, and that is the honest answer: without
  /// a local store there is nothing that can change except by a request the
  /// caller already made. A list that subscribes therefore behaves exactly as
  /// it did before, and gains live updates the moment sync is switched on —
  /// with no branch at the call site asking whether it is.
  Stream<void> watch();
}
