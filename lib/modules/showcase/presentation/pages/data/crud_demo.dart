import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/error/failure_ui_mapper.dart';
import 'package:app_template/ui/error/ui_action.dart';
import 'package:app_template/ui/feedback/feedback.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Add, edit and delete on a local list — every change shows at once, before
/// the (simulated) server answers, and is undone when it refuses.
class CrudDemo extends StatelessWidget {
  const CrudDemo({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => _NotesCubit(),
    child: const DemoBlock(
      code:
          'SafeCubit · snapshot → emit(optimistic) → await → '
          'emit(snapshot) on Left · AppConfirmDialog · context.feedback',
      child: _CrudBody(),
    ),
  );
}

class _Note {
  const _Note(this.id, {this.title, this.pending = false});

  final int id;

  /// `null` ⇐ a seeded row, named by the translated "Item {}".
  final String? title;

  /// Shown before the server has answered.
  final bool pending;

  _Note copyWith({String? title, bool? pending}) =>
      _Note(id, title: title ?? this.title, pending: pending ?? this.pending);
}

class _NotesCubit extends SafeCubit<List<_Note>> {
  _NotesCubit() : super(const [_Note(1), _Note(2), _Note(3)]);

  bool failNext = false;
  int _nextId = 4;

  /// The server, simulated: a short wait, then yes — or no, once, when the
  /// switch is on.
  Future<Failure?> _save() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!failNext) return null;
    failNext = false;
    return const ServiceUnavailableFailure(statusCode: 503);
  }

  Future<Failure?> add(String title) async {
    final snapshot = state;
    final note = _Note(_nextId++, title: title, pending: true);
    emit([note, ...state]);
    final failure = await _save();
    if (failure != null) {
      emit(snapshot);
      return failure;
    }
    emit([
      for (final n in state) n.id == note.id ? n.copyWith(pending: false) : n,
    ]);
    return null;
  }

  Future<Failure?> edit(int id, String title) async {
    final snapshot = state;
    emit([
      for (final n in state)
        n.id == id ? n.copyWith(title: title, pending: true) : n,
    ]);
    final failure = await _save();
    if (failure != null) {
      emit(snapshot);
      return failure;
    }
    emit([for (final n in state) n.id == id ? n.copyWith(pending: false) : n]);
    return null;
  }

  Future<Failure?> delete(int id) async {
    final snapshot = state;
    emit([
      for (final n in state)
        if (n.id != id) n,
    ]);
    final failure = await _save();
    if (failure != null) emit(snapshot);
    return failure;
  }
}

class _CrudBody extends StatefulWidget {
  const _CrudBody();

  @override
  State<_CrudBody> createState() => _CrudBodyState();
}

class _CrudBodyState extends State<_CrudBody> {
  final _title = TextEditingController();
  int? _editing;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String _name(_Note n) =>
      n.title ?? LocaleKeys.showcaseItem.tr(args: ['${n.id}']);

  /// One place turns the answer into words: the mapper for a refusal, a
  /// short toast for a success.
  void _report(Failure? failure, String successKey) {
    if (!mounted) return;
    if (failure == null) {
      context.feedback.success(successKey.tr());
      return;
    }
    if (FailureUiMapper.toAction(failure) case ShowError(:final message)) {
      context.feedback.error(
        message,
        title: LocaleKeys.showcaseCrudRolledBack.tr(),
      );
    }
  }

  Future<void> _submit() async {
    final text = _title.text.trim();
    if (text.isEmpty) return;
    final cubit = context.read<_NotesCubit>();
    final editing = _editing;
    setState(() {
      _editing = null;
      _title.clear();
    });
    final failure = editing == null
        ? await cubit.add(text)
        : await cubit.edit(editing, text);
    _report(failure, LocaleKeys.showcaseCrudSaved);
  }

  Future<void> _delete(_Note note) async {
    final cubit = context.read<_NotesCubit>();
    final confirmed = await AppConfirmDialog.show(
      context,
      titleKey: LocaleKeys.showcaseCrudDeleteTitle,
      messageKey: LocaleKeys.showcaseCrudDeleteMessage,
      messageArgs: {'name': _name(note)},
      confirmKey: LocaleKeys.delete,
      isDestructive: true,
    );
    if (!confirmed) return;
    _report(await cubit.delete(note.id), LocaleKeys.showcaseCrudDeleted);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final cubit = context.read<_NotesCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKeys.showcaseCrudHint.tr(),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(LocaleKeys.showcaseCrudFailNext.tr()),
          value: cubit.failNext,
          onChanged: (v) => setState(() => cubit.failNext = v),
        ),
        CustomTextField(
          controller: _title,
          labelText: LocaleKeys.showcaseCrudTitle.tr(),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
        ),
        const ResponsiveGap(8),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text:
                    (_editing == null
                            ? LocaleKeys.showcaseAdd
                            : LocaleKeys.save)
                        .tr(),
                leadingIcon: _editing == null ? Icons.add : Icons.check,
                onTap: _submit,
              ),
            ),
            if (_editing != null) ...[
              const ResponsiveGap.horizontal(8),
              Expanded(
                child: AppButton(
                  text: LocaleKeys.cancel.tr(),
                  variant: AppButtonVariant.outlined,
                  onTap: () => setState(() {
                    _editing = null;
                    _title.clear();
                  }),
                ),
              ),
            ],
          ],
        ),
        const ResponsiveGap(12),
        BlocBuilder<_NotesCubit, List<_Note>>(
          builder: (context, notes) {
            if (notes.isEmpty) {
              return EmptyStateWidget(titleKey: LocaleKeys.noDataFound);
            }
            return Column(
              children: [
                for (final note in notes)
                  AnimatedOpacity(
                    key: ValueKey(note.id),
                    opacity: note.pending ? 0.5 : 1,
                    duration: AppMotion.of(context).base,
                    child: AppListTile(
                      titleText: _name(note),
                      leadingIcon: Icons.sticky_note_2_outlined,
                      dense: true,
                      onTap: note.pending
                          ? null
                          : () => setState(() {
                              _editing = note.id;
                              _title.text = _name(note);
                            }),
                      trailing: note.pending
                          ? const AppProgress.circular(size: AppProgressSize.sm)
                          : IconButton(
                              tooltip: LocaleKeys.delete.tr(),
                              icon: Icon(
                                Icons.delete_outline,
                                color: context.colors.error,
                              ),
                              onPressed: () => _delete(note),
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
