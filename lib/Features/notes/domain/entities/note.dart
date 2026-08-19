import 'package:equatable/equatable.dart';

/// A note, as the app holds it. Mirrors `WireNote` in
/// `backend_template/src/features/notes/dtos/notes.dto.ts`.
class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    this.body,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isDeleted = false,
  });

  /// A uuid — the client generates it when the note is written offline, the
  /// server when it is not. See [NoteModel.id] for why it cannot be a sequence.
  final String id;
  final String title;

  /// Null when the note is a title only — **not** `''`. The column is nullable
  /// server-side, and collapsing the two would make "cleared deliberately" and
  /// "never written" indistinguishable on the way back up.
  final String? body;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// What the server says this row is at. Carried so an edit can be sent as
  /// conditional — without it the client has nothing to be conditional *on*,
  /// and two devices editing offline silently overwrite each other.
  ///
  /// Defaults to 1 so a note built in a test or a form does not have to know
  /// about it.
  final int version;

  /// True only for a tombstone arriving through a delta pull. Nothing the user
  /// browses ever carries it — the list and read endpoints filter tombstones
  /// out server-side.
  final bool isDeleted;

  Note copyWith({String? title, String? body, DateTime? updatedAt}) => Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        version: version,
        isDeleted: isDeleted,
      );

  @override
  List<Object?> get props => [id, title, body, createdAt, updatedAt, version, isDeleted];
}
