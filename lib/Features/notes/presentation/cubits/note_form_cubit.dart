import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/Features/notes/domain/entities/note.dart';
import 'package:app_template/Features/notes/domain/params/note_params.dart';
import 'package:app_template/Features/notes/domain/usecases/notes_usecases.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'note_form_cubit.freezed.dart';
part 'note_form_state.dart';

/// One cubit for **create and edit**, deciding between them from `id`.
///
/// This is the template's documented CRUD shape (`Features/CLAUDE.md`
/// §CRUD-PATTERNS) built for real: the screen passes whatever it has, and
/// neither it nor this cubit constructs a URL or picks an HTTP verb. That
/// choice is made once, in `NotesRepositoryImpl.save`.
@injectable
class NoteFormCubit extends SafeCubit<NoteFormState> {
  NoteFormCubit(this._saveNote) : super(const NoteFormState.initial());

  final SaveNoteUseCase _saveNote;

  Future<void> submit({
    required int? id,
    required String title,
    String? body,
  }) async {
    emit(const NoteFormState.loading());

    final res = await _saveNote(
      SaveNoteParams(
        id: id,
        title: title.trim(),
        // Trimmed to null rather than kept as '': the server's column is
        // nullable and `''` would store a value that reads as content and
        // renders as a blank line.
        body: body == null || body.trim().isEmpty ? null : body.trim(),
      ),
    );

    res.fold(
      (failure) {
        switch (FailureUiMapper.toAction(failure)) {
          case ShowError(:final message):
            // Includes the 422 field map the server sends — so "title is
            // required" arrives in the server's own wording rather than being
            // guessed at here.
            emit(NoteFormState.error(errorMessage: message));
          case NavigateToLogin():
          case Silent():
            emit(const NoteFormState.initial());
        }
      },
      // `isNew` travels with the result so the list knows whether to prepend or
      // replace. Re-deriving it from `entity.createdAt` would work until two
      // notes shared a second.
      (note) => emit(NoteFormState.success(note: note, isNew: id == null)),
    );
  }
}
