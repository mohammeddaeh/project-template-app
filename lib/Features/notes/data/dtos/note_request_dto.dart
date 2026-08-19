/// Body of `POST /api/v1/notes` and `PATCH /api/v1/notes/{id}`.
///
/// One DTO for both because the server accepts the same two fields either way;
/// what differs is which are required, and that is the server's rule
/// (`createNoteBodySchema` requires `title`, `updateNoteBodySchema` requires
/// at least one). Restating it here would be the client enforcing a policy it
/// does not own.
class NoteRequestDto {
  const NoteRequestDto({this.title, this.body, this.id, this.version});

  /// Client-generated identity, sent on create only.
  ///
  /// Absent for an online create — the server fills one in. Present for a
  /// queued one, because a note written with no network already exists on the
  /// device: it was displayed, maybe edited, possibly deleted, all before any
  /// server saw it.
  final String? id;

  /// The version this write believes it is editing. Absent means unconditional.
  ///
  /// Sent by the queue so a stale write is refused with a 409 carrying both
  /// sides, instead of overwriting an edit nobody saw.
  final int? version;

  final String? title;

  /// Distinguishes three cases on the wire, which is why it is not a plain
  /// `String`:
  /// - absent → leave the column alone (PATCH)
  /// - `null` → clear it
  /// - a value → set it
  final String? body;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (version != null) 'version': version,
      };
}
