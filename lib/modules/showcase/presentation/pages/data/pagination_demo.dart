import 'dart:async';

import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/state/pagination/pagination_cubit.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The template's pagination stack — the real [PaginationCubit] and
/// [PaginationBuilder] — fed by a source on the device instead of a server.
class PaginationDemo extends StatefulWidget {
  const PaginationDemo({super.key});

  @override
  State<PaginationDemo> createState() => _PaginationDemoState();
}

enum _Tail { loading, failed, more, end }

class _PaginationDemoState extends State<PaginationDemo> {
  final _delay = _Delays();
  late final _source = _FakeSource(_delay, onFailed: () => setState(() {}));
  int _run = 0;

  // `spinner` first: the dot styles start untracked `Future.delayed` timers.
  PageLoadingStyle _style = PageLoadingStyle.spinner;
  _Tail _tail = _Tail.more;
  ListEndMarker _marker = ListEndMarker.label;

  int _shown = 20;
  bool _loadingMore = false;

  Future<void> _loadMore() async {
    if (_loadingMore || _shown >= 60) return;
    _loadingMore = true;
    await _delay();
    if (!mounted) return;
    setState(() {
      _shown += 10;
      _loadingMore = false;
    });
  }

  Future<void> _refreshSimple() async {
    await _delay();
    if (!mounted) return;
    setState(() => _shown = 20);
  }

  @override
  void dispose() {
    _delay.cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code:
              'BlocProvider(create: …, child: PaginationBuilder<C, E>('
              'itemBuilder: …, loadingItemWidget: PageLoadingIndicator(…)))',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.showcasePaginationHint.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(LocaleKeys.showcasePaginationFailNext.tr()),
                value: _source.failNext,
                onChanged: (v) => setState(() => _source.failNext = v),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(LocaleKeys.showcasePaginationEmpty.tr()),
                value: _source.empty,
                // A new source shape is a new list: rebuild the provider so the
                // builder fetches page one again.
                onChanged: (v) => setState(() {
                  _source.empty = v;
                  _run++;
                }),
              ),
              8.heightBox,
              SizedBox(
                height: 360,
                child: BlocProvider(
                  key: ValueKey(_run),
                  create: (_) => _DemoPaginationCubit(_source),
                  child: PaginationBuilder<_DemoPaginationCubit, int>(
                    contentPadding: EdgeInsets.zero,
                    separatorWidget: const SizedBox.shrink(),
                    loadingItemWidget: PageLoadingIndicator(style: _style),
                    emptyList: EmptyStateWidget(
                      titleKey: LocaleKeys.showcasePaginationNoItems,
                    ),
                    itemBuilder: (n) => AppListTile(
                      titleText: LocaleKeys.showcaseItem.tr(args: ['$n']),
                      leadingIcon: Icons.notes_outlined,
                      dense: true,
                      showDivider: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'PageLoadingIndicator(style: PageLoadingStyle.…)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChipRow<PageLoadingStyle>(
                items: PageLoadingStyle.values,
                labelResolver: (s) => s.name,
                selectedValue: _style,
                onSelected: (s) => setState(() => _style = s ?? _style),
              ),
              PageLoadingIndicator(key: ValueKey(_style), style: _style),
            ],
          ),
        ),
        DemoBlock(
          code:
              'NextPageStatus(isLoading: …, error: …, isLastPage: …, '
              'onLoadMore: …, endMarker: ListEndMarker.…)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChipRow<_Tail>(
                items: _Tail.values,
                labelResolver: (t) => t.name,
                selectedValue: _tail,
                onSelected: (t) => setState(() => _tail = t ?? _tail),
              ),
              if (_tail == _Tail.end) ...[
                8.heightBox,
                ChipRow<ListEndMarker>(
                  items: ListEndMarker.values,
                  labelResolver: (m) => m.name,
                  selectedValue: _marker,
                  onSelected: (m) => setState(() => _marker = m ?? _marker),
                ),
              ],
              8.heightBox,
              NextPageStatus(
                isLoading: _tail == _Tail.loading,
                style: _style,
                error: _tail == _Tail.failed ? const NoInternetFailure() : null,
                isLastPage: _tail == _Tail.end,
                endMarker: _marker,
                onRetry: () => setState(() => _tail = _Tail.more),
                onLoadMore: () => setState(() => _tail = _Tail.loading),
              ),
            ],
          ),
        ),
        DemoBlock(
          code:
              'RefreshWrapper(onRefresh: …, child: PaginatedListView('
              'itemCount: …, onLoadMore: …, hasMore: …, '
              'loadingWidget: LoadMoreWidget()))',
          child: SizedBox(
            height: 260,
            child: RefreshWrapper(
              onRefresh: _refreshSimple,
              child: PaginatedListView(
                itemCount: _shown,
                hasMore: _shown < 60,
                onLoadMore: _loadMore,
                loadingWidget: const LoadMoreWidget(),
                itemBuilder: (context, i) => AppListTile(
                  titleText: LocaleKeys.showcaseItem.tr(args: ['${i + 1}']),
                  leadingIcon: Icons.circle_outlined,
                  dense: true,
                ),
              ),
            ),
          ),
        ),
        const DemoBlock(
          code:
              'ListAppearTracker()..observeLength(n); '
              'staggerFor(i) → ListItemEntrance(staggerIndex: …)',
          child: _AppearTrackerDemo(),
        ),
      ],
    );
  }
}

/// What both list builders do inside — shown on its own: each new batch
/// staggers from its own first row, rows already seen stay still, and
/// `reset()` plays the whole list again (what pull-to-refresh calls).
class _AppearTrackerDemo extends StatefulWidget {
  const _AppearTrackerDemo();

  @override
  State<_AppearTrackerDemo> createState() => _AppearTrackerDemoState();
}

class _AppearTrackerDemoState extends State<_AppearTrackerDemo> {
  final _appear = ListAppearTracker();
  int _count = 5;
  int _run = 0;

  @override
  Widget build(BuildContext context) {
    _appear.observeLength(_count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 220,
          child: ListView.builder(
            key: ValueKey(_run),
            itemCount: _count,
            itemBuilder: (context, i) {
              final row = AppListTile(
                titleText: LocaleKeys.showcaseItem.tr(args: ['${i + 1}']),
                leadingIcon: Icons.circle_outlined,
                dense: true,
              );
              final order = _appear.staggerFor(i);
              return order == null
                  ? row
                  : ListItemEntrance(staggerIndex: order, child: row);
            },
          ),
        ),
        8.heightBox,
        AppButton(
          text: '${LocaleKeys.showcaseAdd.tr()} +5',
          variant: AppButtonVariant.tonal,
          onTap: () => setState(() => _count += 5),
        ),
        AppButton(
          text: LocaleKeys.showcaseReplay.tr(),
          variant: AppButtonVariant.text,
          onTap: () => setState(() {
            _appear.reset();
            _count = 5;
            _run++;
          }),
        ),
      ],
    );
  }
}

/// A server that lives on the device: [total] rows, the cubit's page size,
/// a short delay — and a switch that makes the next page fail once.
/// The simulated network wait — cancelled with the page, so a request still
/// "in flight" when the reader leaves does not outlive it.
class _Delays {
  final _timers = <Timer>{};

  Future<void> call() {
    final done = Completer<void>();
    late final Timer timer;
    timer = Timer(const Duration(milliseconds: 600), () {
      _timers.remove(timer);
      done.complete();
    });
    _timers.add(timer);
    return done.future;
  }

  void cancelAll() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }
}

class _FakeSource {
  _FakeSource(this._delay, {required this.onFailed});

  final _Delays _delay;

  static const total = 57;

  final VoidCallback onFailed;
  bool failNext = false;
  bool empty = false;

  Future<Either<Failure, PaginationDataEntity<int>>> fetch(
    int page,
    int perPage,
  ) async {
    await _delay();
    if (failNext) {
      failNext = false;
      onFailed();
      return const Left(TimeoutFailure());
    }
    final count = empty ? 0 : total;
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
}

class _DemoPaginationCubit extends PaginationCubit<int> {
  _DemoPaginationCubit(this._source);

  final _FakeSource _source;

  @override
  Future<Either<Failure, PaginationDataEntity<int>>> call() =>
      _source.fetch(paginationQuery.page, paginationQuery.perPage);

  @override
  bool isMatchedTwoEntity(int a, int b) => a == b;

  @override
  Future<void> close() {
    scrollController.dispose();
    return super.close();
  }
}
