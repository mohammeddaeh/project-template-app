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
  });

  final int id;
  final String title;

  /// Null when the note is a title only — **not** `''`. The column is nullable
  /// server-side, and collapsing the two would make "cleared deliberately" and
  /// "never written" indistinguishable on the way back up.
  final String? body;

  final DateTime createdAt;
  final DateTime updatedAt;

  Note copyWith({String? title, String? body, DateTime? updatedAt}) => Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [id, title, body, createdAt, updatedAt];
}
