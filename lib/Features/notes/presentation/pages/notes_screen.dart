import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/Features/notes/domain/entities/note.dart';
import 'package:app_template/Features/notes/presentation/cubits/notes_list_cubit.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// **The reference feature. Copy it, then delete it.**
///
/// A paginated list against a real endpoint, with optimistic delete and a form
/// screen that handles both create and edit. Every part of the stack it touches
/// existed before this screen did — `PaginationCubit`, `PaginationBuilderWdg`,
/// `paginatedSchema` on the server — and **none of them had ever run against
/// each other**, because no endpoint produced the paginated shape and no screen
/// consumed one. The template documented a contract neither half had tested.
///
/// ## The `Builder` is not decoration
///
/// `context.read<NotesListCubit>()` inside the `Scaffold` would throw: the
/// `context` a `build()` receives is the **parent** of the `BlocProvider` this
/// method creates, so it cannot see it. `Builder` makes a context below the
/// provider. Worse than the throw is the workaround people reach for —
/// `getIt<NotesListCubit>()` — which does not throw and is wrong: the cubit is
/// registered as a factory, so that builds a **second, empty** instance and
/// leaks one per rebuild. See `Features/CLAUDE.md`.
@RoutePage()
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return BlocProvider(
      create: (_) => getIt<NotesListCubit>(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(LocaleKeys.notes.tr())),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
            label: Text(LocaleKeys.addNote.tr()),
          ),
          body: PaginationBuilderWdg<NotesListCubit, Note>(
            notItemsMsg: LocaleKeys.noNotes.tr(),
            separatorWidget: const SizedBox(height: 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            itemWdg: (note) => _NoteCard(
              note: note,
              onTap: () => _openForm(context, note: note),
              onDelete: () => _confirmDelete(context, note),
            ),
          ),
        ),
      ),
    );
  }

  /// One entry point for both create and edit — `note == null` is the whole
  /// difference, and it stays that way all the way down to the repository.
  Future<void> _openForm(BuildContext context, {Note? note}) async {
    final cubit = context.read<NotesListCubit>();
    final saved = await context.router.push<Note?>(NoteFormRoute(note: note));
    if (saved == null) return;
    cubit.applySaved(saved, isNew: note == null);
  }

  Future<void> _confirmDelete(BuildContext context, Note note) async {
    final cubit = context.read<NotesListCubit>();
    await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.deleteConfirmTitle,
      messageKey: LocaleKeys.deleteConfirmMessage,
      isDestructive: true,
      // The row disappears immediately and returns if the server refuses —
      // see `NotesListCubit.delete`.
      onConfirm: () => cubit.delete(note.id),
    );
    if (!context.mounted) return;
    context.feedback.success(LocaleKeys.noteDeleted.tr());
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expanded, because a long title inside a Row overflows at runtime
          // with no compile-time warning — the rule in lib/CLAUDE.md.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineSmall,
                ),
                if (note.body != null && note.body!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note.body!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: context.colors.error),
            tooltip: LocaleKeys.delete.tr(),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
