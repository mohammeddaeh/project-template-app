import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/notes/domain/entities/note.dart';
import 'package:app_template/Features/notes/domain/params/note_params.dart';
import 'package:app_template/Features/notes/domain/usecases/notes_usecases.dart';
import 'package:app_template/presentation/shared/pagination/pagination_cubit.dart';

/// The paginated list — and the first `PaginationCubit` in this template with a
/// real endpoint behind it.
///
/// `@injectable` (factory, not singleton) like every list cubit: two screens
/// showing the same list must not share one scroll position and one page
/// counter. That is also why `getIt<NotesListCubit>()` inside a `build()` is a
/// bug — it constructs a fresh instance on every rebuild. See the trap
/// documented in `Features/CLAUDE.md`.
@injectable
class NotesListCubit extends PaginationCubit<Note> {
  NotesListCubit(this._listNotes, this._deleteNote);

  final ListNotesUseCase _listNotes;
  final DeleteNoteUseCase _deleteNote;

  @override
  Future<Either<Failure, PaginationDataEntity<Note>>> call() =>
      _listNotes(ListNotesParams(paginationQuery: paginationQuery));

  @override
  bool isMatchedTwoEntity(Note e1, Note e2) => e1.id == e2.id;

  /// Optimistic delete: the row leaves the list **before** the request, and
  /// comes back if the server refuses.
  ///
  /// The backup is the whole list rather than the single note because
  /// `restoreItems` restores a list — and re-inserting one item at the right
  /// index is exactly the fiddly part that gets it wrong after a concurrent
  /// refresh.
  Future<void> delete(int id) async {
    final backup = List<Note>.from(data);
    removeItemWhere((note) => note.id == id);

    final res = await _deleteNote(DeleteNoteParams(id: id));
    res.fold(
      (failure) => restoreItems(backup),
      (_) {},
    );
  }

  /// Called by the form screen's result: a created note goes to the top, an
  /// edited one replaces itself in place.
  ///
  /// `prependItem` rather than `refresh()` on create — the server orders by
  /// `created_at DESC`, so the new row genuinely belongs first, and refetching
  /// would throw away the page the user is looking at to learn something
  /// already known. That equivalence only holds because the server's ORDER BY
  /// is explicit; see `crud-helpers.ts`.
  void applySaved(Note note, {required bool isNew}) {
    if (isNew) {
      prependItem(note);
    } else {
      replaceEntityItem(note);
    }
  }

}
