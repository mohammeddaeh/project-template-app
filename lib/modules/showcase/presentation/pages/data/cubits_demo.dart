import 'dart:async';

import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/app_feedback_service.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/state/mutation_result.dart';
import 'package:app_template/ui/state/pagination/pagination_cubit.dart';
import 'package:app_template/ui/state/refresh/refresh_cubit.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The template's state tools as live state machines: each section owns a
/// real cubit, drives it from buttons, and writes every emitted state — with
/// its time — into a log, so the transitions are seen rather than described.
///
/// Every cubit here is created by its section and closed in `dispose`.
class CubitsDemo extends StatelessWidget {
  const CubitsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SafeCubitSection(),
        _MutationSection(),
        _RefreshSection(),
        _PaginationSection(),
      ],
    );
  }
}

// ── The log ────────────────────────────────────────────────────────────────

enum _Tone { call, state, result, dropped, crash }

class _LogLine {
  _LogLine(this.text, this.tone) : at = DateTime.now();

  final DateTime at;
  final String text;
  final _Tone tone;

  String get time {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(at.hour)}:${two(at.minute)}:${two(at.second)}'
        '.${at.millisecond.toString().padLeft(3, '0')}';
  }
}

/// A section's log — owned by its State, appended to with [add].
mixin _Logs<T extends StatefulWidget> on State<T> {
  final List<_LogLine> lines = [];

  void add(String text, _Tone tone) {
    if (!mounted) return;
    setState(() => lines.add(_LogLine(text, tone)));
  }

  Widget log() => _StateLog(lines, onClear: () => setState(lines.clear));
}

class _StateLog extends StatelessWidget {
  const _StateLog(this.lines, {required this.onClear});

  final List<_LogLine> lines;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 18,
              color: colors.textMuted,
            ),
            8.widthBox,
            Expanded(
              child: Text(
                LocaleKeys.showcaseCubitsLog.tr(),
                style: context.textTheme.labelMedium,
              ),
            ),
            TextButton(
              onPressed: lines.isEmpty ? null : onClear,
              child: Text(LocaleKeys.showcaseCubitsClear.tr()),
            ),
          ],
        ),
        4.heightBox,
        Container(
          height: 168,
          decoration: BoxDecoration(
            color: colors.bgNeutral,
            borderRadius: AppRadius.smRadius,
          ),
          child: lines.isEmpty
              ? Center(
                  child: Padding(
                    padding: 12.allPadding,
                    child: Text(
                      LocaleKeys.showcaseCubitsLogEmpty.tr(),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                )
              // Newest first, read as code: left to right in either language.
              : Directionality(
                  textDirection: TextDirection.ltr,
                  child: ListView.builder(
                    primary: false,
                    padding: 8.allPadding,
                    itemCount: lines.length,
                    itemBuilder: (context, i) =>
                        _LogRow(lines[lines.length - 1 - i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow(this.line);

  final _LogLine line;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, tone) = switch (line.tone) {
      _Tone.call => (Icons.arrow_forward, colors.textSecondary),
      _Tone.state => (Icons.circle, colors.primary),
      _Tone.result => (Icons.reply, colors.statusSuccessFg),
      _Tone.dropped => (Icons.shield_outlined, colors.statusWarningFg),
      _Tone.crash => (Icons.error_outline, colors.error),
    };
    final style = context.textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line.time,
            style: style?.copyWith(
              color: colors.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          8.widthBox,
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: line.tone == _Tone.state ? 8 : 14,
              color: tone,
            ),
          ),
          8.widthBox,
          Expanded(
            child: Text(
              line.text,
              style: style?.copyWith(
                color: line.tone == _Tone.crash ? colors.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A muted line of explanation above a section's controls.
class _Intro extends StatelessWidget {
  const _Intro(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colors.textSecondary,
      ),
    ),
  );
}

/// "state: …" — the current state, as code.
class _Current extends StatelessWidget {
  const _Current(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Text(
          LocaleKeys.showcaseCubitsCurrent.tr(),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
        8.widthBox,
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              text,
              textAlign: Directionality.of(context) == TextDirection.rtl
                  ? TextAlign.right
                  : TextAlign.left,
              style: context.textTheme.labelLarge,
            ),
          ),
        ),
        if (trailing != null) ...[8.widthBox, trailing!],
      ],
    ),
  );
}

// ── 1. SafeCubit ───────────────────────────────────────────────────────────

class _Load {
  const _Load(this.label);

  final String label;

  @override
  String toString() => label;
}

enum _Base { safeCubit, cubit }

/// One fetch, written once for both bases so the only difference between
/// them is the class the cubit extends.
mixin _Loads on Cubit<_Load> {
  int _count = 0;
  void Function(String text, _Tone tone)? note;

  Future<void> load({required bool fail, required Duration delay}) async {
    emit(const _Load('loading'));
    await Future<void>.delayed(delay);
    final next = fail
        ? const _Load('failed(TimeoutFailure)')
        : _Load('loaded(${++_count})');
    if (isClosed) note?.call('emit($next)  ← after close()', _Tone.call);
    try {
      emit(next);
      if (isClosed) {
        note?.call(LocaleKeys.showcaseCubitsDropped.tr(), _Tone.dropped);
      }
    } on StateError catch (e) {
      note?.call(
        'StateError: ${e.message} — ${LocaleKeys.showcaseCubitsCrash.tr()}',
        _Tone.crash,
      );
    }
  }
}

class _SafeLoadCubit extends SafeCubit<_Load> with _Loads {
  _SafeLoadCubit() : super(const _Load('idle'));
}

class _PlainLoadCubit extends Cubit<_Load> with _Loads {
  _PlainLoadCubit() : super(const _Load('idle'));
}

class _SafeCubitSection extends StatefulWidget {
  const _SafeCubitSection();

  @override
  State<_SafeCubitSection> createState() => _SafeCubitSectionState();
}

class _SafeCubitSectionState extends State<_SafeCubitSection>
    with _Logs<_SafeCubitSection> {
  _Base _base = _Base.safeCubit;
  late _Loads _cubit;
  final _subs = <StreamSubscription<_Load>>[];

  @override
  void initState() {
    super.initState();
    _cubit = _create();
  }

  _Loads _create() {
    final cubit = switch (_base) {
      _Base.safeCubit => _SafeLoadCubit(),
      _Base.cubit => _PlainLoadCubit(),
    }..note = add;
    _subs.add(cubit.stream.listen((s) => add('$s', _Tone.state)));
    return cubit;
  }

  void _reopen() {
    add(
      '${_base == _Base.safeCubit ? '_SafeLoadCubit' : '_PlainLoadCubit'}()',
      _Tone.call,
    );
    setState(() => _cubit = _create());
  }

  void _load({required bool fail, required Duration delay}) {
    add('load()', _Tone.call);
    _cubit.load(fail: fail, delay: delay);
  }

  void _leave() {
    add('close()', _Tone.call);
    _cubit.close();
    setState(() {});
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    // A slow answer still in flight lands after this — the very case shown.
    _cubit.note = null;
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final closed = _cubit.isClosed;
    return DemoBlock(
      code: 'class MyCubit extends SafeCubit<MyState>',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Intro(LocaleKeys.showcaseCubitsSafeIntro.tr()),
          Directionality(
            textDirection: TextDirection.ltr,
            child: ChipRow<_Base>(
              items: _Base.values,
              labelResolver: (b) => switch (b) {
                _Base.safeCubit => 'extends SafeCubit',
                _Base.cubit => 'extends Cubit',
              },
              selectedValue: _base,
              scrollable: false,
              onSelected: (b) {
                if (b == null || b == _base) return;
                if (!_cubit.isClosed) _leave();
                _base = b;
                _reopen();
              },
            ),
          ),
          BlocBuilder<Cubit<_Load>, _Load>(
            bloc: _cubit,
            builder: (context, state) => _Current(
              '$state',
              trailing: StatusChip(
                labelText: closed
                    ? LocaleKeys.showcaseCubitsClosed.tr()
                    : LocaleKeys.showcaseCubitsOpen.tr(),
                tone: closed ? StatusTone.neutral : StatusTone.success,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                text: LocaleKeys.showcaseCubitsSucceed.tr(),
                size: AppButtonSize.small,
                isEnabled: !closed,
                onTap: () => _load(
                  fail: false,
                  delay: const Duration(milliseconds: 600),
                ),
              ),
              AppButton(
                text: LocaleKeys.showcaseCubitsFail.tr(),
                size: AppButtonSize.small,
                variant: AppButtonVariant.tonal,
                isEnabled: !closed,
                onTap: () =>
                    _load(fail: true, delay: const Duration(milliseconds: 600)),
              ),
              AppButton(
                text: LocaleKeys.showcaseCubitsSlow.tr(),
                size: AppButtonSize.small,
                variant: AppButtonVariant.tonal,
                isEnabled: !closed,
                onTap: () =>
                    _load(fail: false, delay: const Duration(seconds: 3)),
              ),
              closed
                  ? AppButton(
                      text: LocaleKeys.showcaseCubitsReopen.tr(),
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.outlined,
                      leadingIcon: Icons.refresh,
                      onTap: _reopen,
                    )
                  : AppButton(
                      text: LocaleKeys.showcaseCubitsLeave.tr(),
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.outlined,
                      leadingIcon: Icons.logout,
                      onTap: _leave,
                    ),
            ],
          ),
          8.heightBox,
          _Intro(LocaleKeys.showcaseCubitsLeaveHint.tr()),
          log(),
        ],
      ),
    );
  }
}

// ── 2. MutationResult ──────────────────────────────────────────────────────

/// `true` while a save is on the wire — a value with a duration, so state.
class _SaveCubit extends SafeCubit<bool> {
  _SaveCubit() : super(false);

  Future<MutationResult> save(MutationKind outcome) async {
    emit(true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    emit(false);
    return switch (outcome) {
      MutationKind.saved => const MutationResult.saved(),
      MutationKind.failed => MutationResult.failed(
        LocaleKeys.showcaseCubitsSaveRefused.tr(),
      ),
      MutationKind.needsConfirmation =>
        const MutationResult.needsConfirmation(),
    };
  }
}

class _MutationSection extends StatefulWidget {
  const _MutationSection();

  @override
  State<_MutationSection> createState() => _MutationSectionState();
}

class _MutationSectionState extends State<_MutationSection>
    with _Logs<_MutationSection> {
  final _cubit = _SaveCubit();
  late final StreamSubscription<bool> _sub;
  MutationKind _outcome = MutationKind.failed;
  bool _asking = false;
  int _said = 0;

  @override
  void initState() {
    super.initState();
    _sub = _cubit.stream.listen((s) => add('saving: $s', _Tone.state));
  }

  Future<void> _save(MutationKind outcome) async {
    add('await cubit.save()', _Tone.call);
    setState(() => _asking = false);
    final result = await _cubit.save(outcome);
    if (!mounted) return;
    final message = result.message;
    add(
      '→ MutationResult.${result.kind.name}'
      '(${message == null ? '' : '"$message"'})',
      _Tone.result,
    );
    final feedback = getIt.isRegistered<AppFeedbackService>();
    if (result.isSaved) {
      if (feedback) {
        context.feedback.success(LocaleKeys.showcaseFeedbackSaved.tr());
      }
    } else if (result.kind == MutationKind.needsConfirmation) {
      setState(() => _asking = true);
    } else if (message != null) {
      setState(() => _said++);
      if (feedback) context.feedback.error(message);
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoBlock(
    code:
        'final result = await cubit.save(…);\n'
        'if (result.isSaved) … else if (result.message != null) …',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Intro(LocaleKeys.showcaseCubitsMutationIntro.tr()),
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChipRow<MutationKind>(
            items: MutationKind.values,
            labelResolver: (k) => k.name,
            selectedValue: _outcome,
            scrollable: false,
            onSelected: (k) => setState(() => _outcome = k ?? _outcome),
          ),
        ),
        12.heightBox,
        BlocBuilder<_SaveCubit, bool>(
          bloc: _cubit,
          builder: (context, saving) => Row(
            children: [
              AppButton(
                text: LocaleKeys.save.tr(),
                leadingIcon: Icons.save_outlined,
                isLoading: saving,
                onTap: () => _save(_outcome),
              ),
              12.widthBox,
              Expanded(
                child: Text(
                  LocaleKeys.showcaseCubitsSaid.tr(args: ['$_said']),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_asking) ...[
          12.heightBox,
          Row(
            children: [
              Expanded(
                child: Text(
                  LocaleKeys.showcaseCubitsAskAnyway.tr(),
                  style: context.textTheme.bodyMedium,
                ),
              ),
              AppButton(
                text: LocaleKeys.showcaseCubitsSaveAnyway.tr(),
                size: AppButtonSize.small,
                variant: AppButtonVariant.tonal,
                onTap: () => _save(MutationKind.saved),
              ),
            ],
          ),
        ],
        12.heightBox,
        log(),
      ],
    ),
  );
}

// ── 3. RefreshCubit ────────────────────────────────────────────────────────

class _RefreshSection extends StatefulWidget {
  const _RefreshSection();

  @override
  State<_RefreshSection> createState() => _RefreshSectionState();
}

class _RefreshSectionState extends State<_RefreshSection>
    with _Logs<_RefreshSection> {
  final _cubit = RefreshCubit();
  late final StreamSubscription<RefreshState> _sub;
  int _rebuilds = 0;

  static String _name(RefreshState s) =>
      'RefreshState#${(identityHashCode(s) % 10000).toString().padLeft(4, '0')}';

  @override
  void initState() {
    super.initState();
    _sub = _cubit.stream.listen((s) {
      _rebuilds++;
      add(_name(s), _Tone.state);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoBlock(
    code:
        'final refresh = RefreshCubit();\n'
        'BlocBuilder<RefreshCubit, RefreshState>(bloc: refresh, …)',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Intro(LocaleKeys.showcaseCubitsRefreshIntro.tr()),
        BlocBuilder<RefreshCubit, RefreshState>(
          bloc: _cubit,
          builder: (context, state) => _Current(_name(state)),
        ),
        Row(
          children: [
            AppButton(
              text: 'refresh()',
              size: AppButtonSize.small,
              leadingIcon: Icons.refresh,
              onTap: () {
                add('refresh()', _Tone.call);
                _cubit.refresh();
              },
            ),
            12.widthBox,
            Expanded(
              child: Text(
                LocaleKeys.showcaseCubitsRebuilds.tr(args: ['$_rebuilds']),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        12.heightBox,
        log(),
      ],
    ),
  );
}

// ── 4. PaginationCubit ─────────────────────────────────────────────────────

class _PagingCubit extends PaginationCubit<int> {
  static const total = 40;

  bool failNext = false;
  bool empty = false;

  @override
  Future<Either<Failure, PaginationDataEntity<int>>> call() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (failNext) {
      failNext = false;
      return const Left(TimeoutFailure());
    }
    final count = empty ? 0 : total;
    final page = paginationQuery.page;
    final perPage = paginationQuery.perPage;
    final start = (page - 1) * perPage;
    final end = (start + perPage).clamp(0, count);
    return Right(
      PaginationDataEntity(
        data: [for (var i = start; i < end; i++) i + 1],
        paginationInfo: PaginationInfo(
          isFirstPage: page == 1,
          isLastPage: end >= count,
        ),
      ),
    );
  }

  @override
  bool isMatchedTwoEntity(int a, int b) => a == b;

  @override
  Future<void> close() {
    scrollController.dispose();
    return super.close();
  }
}

String _describe(PaginationState<int> s) => switch (s) {
  PaginationInitState() => 'initial()',
  PaginationLoadingState() => 'loading()',
  PaginationEmptyState() => 'emptyData()',
  PaginationErrorState(:final error) => 'error(${error.runtimeType})',
  PaginationSuccessState<int>(
    :final paginationEntity,
    :final isLoading,
    :final error,
  ) =>
    'success(${paginationEntity.data.length} items'
        '${isLoading ? ', isLoading: true' : ''}'
        '${error == null ? '' : ', error: ${error.runtimeType}'})',
  _ => '$s',
};

class _PaginationSection extends StatefulWidget {
  const _PaginationSection();

  @override
  State<_PaginationSection> createState() => _PaginationSectionState();
}

class _PaginationSectionState extends State<_PaginationSection>
    with _Logs<_PaginationSection> {
  final _cubit = _PagingCubit();
  late final StreamSubscription<PaginationState<int>> _sub;

  @override
  void initState() {
    super.initState();
    _sub = _cubit.stream.listen((s) => add(_describe(s), _Tone.state));
  }

  void _call(String code, VoidCallback run) {
    add(code, _Tone.call);
    run();
  }

  @override
  void dispose() {
    _sub.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoBlock(
    code: 'class MyListCubit extends PaginationCubit<Item>',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Intro(LocaleKeys.showcaseCubitsPagingIntro.tr()),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(LocaleKeys.showcaseCubitsFailNext.tr()),
          value: _cubit.failNext,
          onChanged: (v) => setState(() => _cubit.failNext = v),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(LocaleKeys.showcaseCubitsEmptySource.tr()),
          value: _cubit.empty,
          onChanged: (v) => setState(() => _cubit.empty = v),
        ),
        BlocBuilder<_PagingCubit, PaginationState<int>>(
          bloc: _cubit,
          builder: (context, state) => _Current(_describe(state)),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (code, run) in <(String, VoidCallback)>[
                ('refresh()', _cubit.refresh),
                ('nextPage()', _cubit.nextPage),
                ('reset()', _cubit.reset),
                ('prependItem(0)', () => _cubit.prependItem(0)),
                (
                  'removeItemWhere(isEven)',
                  () => _cubit.removeItemWhere((i) => i.isEven),
                ),
              ])
                AppButton(
                  text: code,
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.tonal,
                  onTap: () => _call(code, run),
                ),
            ],
          ),
        ),
        12.heightBox,
        log(),
      ],
    ),
  );
}
