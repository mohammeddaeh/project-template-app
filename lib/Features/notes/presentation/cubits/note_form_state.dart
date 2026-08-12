part of 'note_form_cubit.dart';

@freezed
abstract class NoteFormState with _$NoteFormState {
  const factory NoteFormState.initial() = NoteFormInitial;
  const factory NoteFormState.loading() = NoteFormLoading;

  /// Carries the saved note **and** whether it was new.
  ///
  /// The list needs both: a created note is prepended, an edited one replaces
  /// itself in place, and the two look identical from the entity alone.
  const factory NoteFormState.success({
    required Note note,
    required bool isNew,
  }) = NoteFormSuccess;

  const factory NoteFormState.error({required String errorMessage}) =
      NoteFormError;
}
