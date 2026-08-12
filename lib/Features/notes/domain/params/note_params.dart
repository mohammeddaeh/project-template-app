import 'package:app_template/core/foundation/contracts/pagination_query.dart';
import 'package:app_template/core/foundation/domain/use_case_params.dart';

class ListNotesParams extends UseCaseParams {
  const ListNotesParams({required this.paginationQuery}) : super();
  final PaginationQuery paginationQuery;
}

/// Create and update share one params type for the same reason the DTO is
/// shared: `id == null` means create, and the form screen that produces it is
/// one screen for both. See `Features/CLAUDE.md` §CRUD-PATTERNS.
class SaveNoteParams extends UseCaseParams {
  const SaveNoteParams({this.id, required this.title, this.body}) : super();

  final int? id;
  final String title;
  final String? body;
}

class DeleteNoteParams extends UseCaseParams {
  const DeleteNoteParams({required this.id}) : super();
  final int id;
}
