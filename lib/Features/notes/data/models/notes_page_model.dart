import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/Features/notes/data/models/note_model.dart';
import 'package:app_template/Features/notes/domain/entities/note.dart';

/// Parses the paginated envelope: `{items, page, limit, total, total_pages}`.
///
/// **This shape had never been parsed from a real response before this
/// feature existed.** `core/pagination/pagination.ts`, `PaginationCubit` and
/// `PaginationBuilderWdg` were all written against it and no endpoint produced
/// it — so the contract both halves were built to follow was, until now,
/// entirely theoretical. `test/wire_contract_test.dart` pins it.
class NotesPageModel {
  const NotesPageModel({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<NoteModel> items;
  final int page;
  final int totalPages;

  factory NotesPageModel.fromJson(Map<String, dynamic> json) => NotesPageModel(
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int? ?? 1,
        // Defaults to 1, not 0: `page >= totalPages` is what stops the infinite
        // scroll, and a 0 would mark every first page as the last one.
        totalPages: json['total_pages'] as int? ?? 1,
      );

  PaginationDataEntity<Note> toEntity() => PaginationDataEntity<Note>(
        data: items.map((m) => m.toEntity()).toList(),
        paginationInfo: PaginationInfo(
          isFirstPage: page <= 1,
          isLastPage: page >= totalPages,
        ),
      );
}
