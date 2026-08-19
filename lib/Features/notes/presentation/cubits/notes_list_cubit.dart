import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/notes/domain/entities/note.dart';
import 'package:app_template/Features/notes/domain/params/note_params.dart';
import 'package:app_template/Features/notes/domain/repositories/notes_repository.dart';
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
  NotesListCubit(this._listNotes, this._deleteNote, this._repository) {
    _bindToLocalChanges();
  }

  final ListNotesUseCase _listNotes;
  final DeleteNoteUseCase _deleteNote;
  final NotesRepository _repository;

  StreamSubscription<void>? _changes;

  /// Re-reads whenever the notes on this device change underneath the screen —
  /// a sync pulled an edit made elsewhere, or a queued write finally landed.
  ///
  /// ## This is what makes the local store a source rather than a snapshot
  ///
  /// Without it the only way to notice a sync was to re-read on a timer:
  /// either too slow to be useful, or frequent enough to cost battery for
  /// nothing. The list now updates itself and the user never pulls to refresh
  /// to find out whether something arrived.
  ///
  /// **Empty for an online-only build.** `NotesRepositoryImpl.watch()` returns
  /// an empty stream, so this subscribes to nothing and the screen behaves
  /// exactly as it did before — no branch here asking whether sync is on.
  ///
  /// `refresh()` and not a partial merge: the change signal carries no payload
  /// on purpose, because the store does not know which page or filter this
  /// screen is showing.
  void _bindToLocalChanges() {
    _changes = _repository.watch().listen((_) {
      // Guard against re-entry: `refresh()` triggers a read, a read caches, and
      // a caching write that announced itself would call this again. The cache
      // path passes `notify: false` for exactly that reason — this check is the
      // second line of defence, not the first.
      if (getSuccessState?.isLoading ?? false) return;
      refresh();
    });
  }

  @override
  Future<void> close() {
    _changes?.cancel();
    return super.close();
  }

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
  Future<void> delete(String id) async {
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
