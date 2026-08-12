import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/Features/notes/domain/entities/note.dart';
import 'package:app_template/Features/notes/presentation/cubits/note_form_cubit.dart';
import 'package:app_template/presentation/extensions/extensions.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/shared/refresh/refresh_cubit.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';

/// **One screen for create and edit** — `note == null` is the only difference.
///
/// That is the template's documented CRUD rule (`Features/CLAUDE.md`
/// §CRUD-PATTERNS), and this is the first place it is actually built. Two
/// screens for the same five fields drift within a month: a validator added to
/// one, a trim added to the other.
///
/// ## It pops the entity, not `true`
///
/// The list needs the server's version of the row — its id, and the
/// `updated_at` the server stamped. Popping a boolean would force a refetch of
/// a page the caller is already showing, to learn something the response
/// already carried.
@RoutePage()
class NoteFormScreen extends StatefulWidget {
  const NoteFormScreen({super.key, this.note});

  final Note? note;

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _refreshCubit = RefreshCubit();

  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final NoteFormCubit _cubit;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<NoteFormCubit>();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _cubit.close();
    _refreshCubit.close();
    super.dispose();
  }

  bool get _canSubmit => _titleController.text.trim().isNotEmpty;

  void _submit() {
    if (_cubit.state is NoteFormLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.unfocus();
    _cubit.submit(
      id: widget.note?.id,
      title: _titleController.text,
      body: _bodyController.text,
    );
  }

  void _onStateChanged(BuildContext context, NoteFormState state) {
    state.maybeWhen(
      success: (note, _) {
        context.feedback.success(LocaleKeys.noteSaved.tr());
        context.router.maybePop<Note>(note);
      },
      // The server's own message, including the 422 field map — so "title is
      // required" is worded once, on the side that enforces it.
      error: (message) => context.feedback.error(message),
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          (_isEditing ? LocaleKeys.editNote : LocaleKeys.addNote).tr(),
        ),
      ),
      body: BlocConsumer<NoteFormCubit, NoteFormState>(
        bloc: _cubit,
        listener: _onStateChanged,
        builder: (context, state) {
          final isLoading = state is NoteFormLoading;
          return KeyboardDismissWidget(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _titleController,
                      labelText: LocaleKeys.noteTitle.tr(),
                      hint: LocaleKeys.typeNoteTitle.tr(),
                      textInputAction: TextInputAction.next,
                      showRequired: true,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: _refreshCubit.refresh,
                      // Emptiness only. The 200-character ceiling is the
                      // server's `titleSchema`, and restating a limit here is
                      // how the two start disagreeing.
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? LocaleKeys.fieldRequired.tr()
                              : null,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _bodyController,
                      labelText: LocaleKeys.noteBody.tr(),
                      hint: LocaleKeys.typeNoteBody.tr(),
                      maxLines: 6,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 32),
                    BlocBuilder<RefreshCubit, RefreshState>(
                      bloc: _refreshCubit,
                      builder: (context, _) => SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          text: LocaleKeys.save.tr(),
                          isLoading: isLoading,
                          isEnabled: _canSubmit,
                          onTap: _submit,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
