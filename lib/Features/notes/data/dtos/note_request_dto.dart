/// Body of `POST /api/v1/notes` and `PATCH /api/v1/notes/{id}`.
///
/// One DTO for both because the server accepts the same two fields either way;
/// what differs is which are required, and that is the server's rule
/// (`createNoteBodySchema` requires `title`, `updateNoteBodySchema` requires
/// at least one). Restating it here would be the client enforcing a policy it
/// does not own.
class NoteRequestDto {
  const NoteRequestDto({this.title, this.body});

  final String? title;

  /// Distinguishes three cases on the wire, which is why it is not a plain
  /// `String`:
  /// - absent → leave the column alone (PATCH)
  /// - `null` → clear it
  /// - a value → set it
  final String? body;

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (body != null) 'body': body,
      };
}
