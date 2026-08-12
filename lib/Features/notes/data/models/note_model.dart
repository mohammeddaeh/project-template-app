import 'package:app_template/Features/notes/domain/entities/note.dart';

/// Wire shape of a note. Raw types only — dates stay `String` here and are
/// converted in [toEntity], so a malformed timestamp fails in one known place
/// rather than wherever the entity is first read.
class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? body;
  final String createdAt;
  final String updatedAt;

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        body: json['body'] as String?,
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  Note toEntity() => Note(
        id: id,
        title: title,
        body: body,
        // DateTime(2000) rather than a throw: one unreadable timestamp must not
        // blank a whole page of notes.
        createdAt: DateTime.tryParse(createdAt) ?? DateTime(2000),
        updatedAt: DateTime.tryParse(updatedAt) ?? DateTime(2000),
      );
}
