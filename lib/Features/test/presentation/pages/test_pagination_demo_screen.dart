import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:dartz/dartz.dart' as dz;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/presentation/shared/pagination/pagination_cubit.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum _LoadingStyle { shimmerList, shimmerGrid, skeleton, spinner }

enum _ViewMode { list, grid2, grid3 }

// ── Fake Data ─────────────────────────────────────────────────────────────────

class _FakeItem {
  const _FakeItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.colorIndex,
  });

  final String id;
  final String title;
  final String subtitle;
  final int colorIndex;
}

const _kColors = [
  Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800),
  Color(0xFF9C27B0), Color(0xFFE91E63), Color(0xFF00BCD4),
  Color(0xFFFF5722), Color(0xFF607D8B),
];

// ── Fake PaginationCubit ──────────────────────────────────────────────────────

class _FakePaginationCubit extends PaginationCubit<_FakeItem> {
  _FakePaginationCubit({
    required this.pageSize,
    required this.delayMs,
    required this.errorChance,
  });

  final int pageSize;
  final int delayMs;
  final double errorChance;

  bool _forceError = false;
  bool _forceEmpty = false;
  final _rng = Random();

  void triggerError() {
    _forceError = true;
    _forceEmpty = false;
    refresh();
  }

  void triggerEmpty() {
    _forceEmpty = true;
    _forceError = false;
    refresh();
  }

  @override
  Future<dz.Either<Failure, PaginationDataEntity<_FakeItem>>> call() async {
    await Future.delayed(Duration(milliseconds: delayMs));

    if (_forceError) {
      _forceError = false;
      return dz.Left(
        const ServerFailure(statusCode: 500, serverMessage: 'Simulated error'),
      );
    }

    if (_forceEmpty) {
      return const dz.Right(
        PaginationDataEntity(
          data: [],
          paginationInfo: PaginationInfo(isFirstPage: true, isLastPage: true),
        ),
      );
    }

    if (errorChance > 0 && _rng.nextDouble() < errorChance) {
      return dz.Left(
        const ServerFailure(statusCode: 500, serverMessage: 'Random error'),
      );
    }

    const totalPages = 4;
    final page = paginationQuery.page;
    if (page > totalPages) {
      return dz.Right(
        PaginationDataEntity(
          data: const [],
          paginationInfo:
              PaginationInfo(isFirstPage: page == 1, isLastPage: true),
        ),
      );
    }

    final items = List.generate(
      pageSize,
      (i) => _FakeItem(
        id: '${page}_$i',
        title: 'Item ${(page - 1) * pageSize + i + 1}',
        subtitle: 'Page $page · ${i + 1}',
        colorIndex: ((page - 1) * pageSize + i) % _kColors.length,
      ),
    );

    return dz.Right(
      PaginationDataEntity(
        data: items,
        paginationInfo: PaginationInfo(
          isFirstPage: page == 1,
          isLastPage: page >= totalPages,
        ),
      ),
    );
  }

  @override
  bool isMatchedTwoEntity(_FakeItem a, _FakeItem b) => a.id == b.id;
}

// ── Screen ────────────────────────────────────────────────────────────────────

@RoutePage()
class TestPaginationDemoScreen extends StatefulWidget {
  const TestPaginationDemoScreen({super.key});

  @override
  State<TestPaginationDemoScreen> createState() =>
      _TestPaginationDemoScreenState();
}

class _TestPaginationDemoScreenState extends State<TestPaginationDemoScreen> {
  _LoadingStyle _loadingStyle = _LoadingStyle.shimmerList;
  _ViewMode _viewMode = _ViewMode.list;
  PageLoadingStyle _pageLoadingStyle = PageLoadingStyle.spinner;
  int _pageSize = 8;
  int _delayMs = 800;
  double _errorChance = 0.0;
  int _cubitVersion = 0;

  void _rebuildCubit() => setState(() => _cubitVersion++);

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.testPaginationDemoTitle.tr()),
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Column(
        children: [
          // ── Settings Panel ───────────────────────────────────────────────
          _buildSettings(),
          const Divider(height: 1),

          // ── BLoC-scoped area ─────────────────────────────────────────────
          Expanded(
            child: BlocProvider<_FakePaginationCubit>(
              key: ValueKey(_cubitVersion),
              create: (_) => _FakePaginationCubit(
                pageSize: _pageSize,
                delayMs: _delayMs,
                errorChance: _errorChance,
              ),
              child: Builder(
                builder: (ctx) => Column(
                  children: [
                    _buildStatusBar(ctx),
                    _buildActionRow(ctx),
                    const Divider(height: 1),
                    Expanded(child: _buildList(ctx)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Widget _buildSettings() {
    final scheme = context.colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          LocaleKeys.testPaginationSubtitle.tr(),
          style: context.textTheme.bodySmall
              ?.copyWith(color: scheme.outline, fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loading Style
                _SelectorLabel(LocaleKeys.loadingStyle.tr()),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<_LoadingStyle>(
                    segments: [
                      ButtonSegment(
                          value: _LoadingStyle.shimmerList,
                          label: Text(LocaleKeys.shimmerList.tr())),
                      ButtonSegment(
                          value: _LoadingStyle.shimmerGrid,
                          label: Text(LocaleKeys.shimmerGrid.tr())),
                      ButtonSegment(
                          value: _LoadingStyle.skeleton,
                          label: Text(LocaleKeys.skeletonRows.tr())),
                      ButtonSegment(
                          value: _LoadingStyle.spinner,
                          label: Text(LocaleKeys.spinnerStyle.tr())),
                    ],
                    selected: {_loadingStyle},
                    onSelectionChanged: (s) {
                      _loadingStyle = s.first;
                      _rebuildCubit();
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Display Mode
                _SelectorLabel(LocaleKeys.displayMode.tr()),
                const SizedBox(height: 6),
                SegmentedButton<_ViewMode>(
                  segments: [
                    ButtonSegment(
                        value: _ViewMode.list,
                        icon: const Icon(Icons.view_list_rounded, size: 18),
                        label: Text(LocaleKeys.viewList.tr())),
                    ButtonSegment(
                        value: _ViewMode.grid2,
                        icon: const Icon(Icons.grid_view_rounded, size: 18),
                        label: Text(LocaleKeys.viewGrid2.tr())),
                    ButtonSegment(
                        value: _ViewMode.grid3,
                        icon: const Icon(Icons.apps_rounded, size: 18),
                        label: Text(LocaleKeys.viewGrid3.tr())),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (s) {
                    _viewMode = s.first;
                    _rebuildCubit();
                  },
                ),
                const SizedBox(height: 12),

                // Page Loading Indicator Style
                _SelectorLabel(LocaleKeys.pageLoadingStyle.tr()),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<PageLoadingStyle>(
                    segments: const [
                      ButtonSegment(
                          value: PageLoadingStyle.spinner,
                          label: Text('Spinner')),
                      ButtonSegment(
                          value: PageLoadingStyle.linearBar,
                          label: Text('Linear')),
                      ButtonSegment(
                          value: PageLoadingStyle.shimmerBar,
                          label: Text('Shimmer')),
                      ButtonSegment(
                          value: PageLoadingStyle.dotsWave,
                          label: Text('Wave')),
                      ButtonSegment(
                          value: PageLoadingStyle.textSpinner,
                          label: Text('Text')),
                      ButtonSegment(
                          value: PageLoadingStyle.pulseDots,
                          label: Text('Pulse')),
                    ],
                    selected: {_pageLoadingStyle},
                    onSelectionChanged: (s) =>
                        setState(() => _pageLoadingStyle = s.first),
                  ),
                ),
                const SizedBox(height: 6),
                // Live preview
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color:
                            scheme.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(8),
                    color: scheme.surface,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(_pageLoadingStyle),
                      child: PageLoadingIndicator(
                          style: _pageLoadingStyle),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sliders row
                Row(
                  children: [
                    Expanded(
                      child: _SliderRow(
                        label: '${LocaleKeys.pageSize.tr()}: $_pageSize',
                        value: _pageSize.toDouble(),
                        min: 4,
                        max: 20,
                        divisions: 16,
                        onChanged: (v) =>
                            setState(() => _pageSize = v.round()),
                        onChangeEnd: (_) => _rebuildCubit(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SliderRow(
                        label:
                            '${LocaleKeys.errorChance.tr()}: ${(_errorChance * 100).round()}%',
                        value: _errorChance,
                        min: 0,
                        max: 0.6,
                        divisions: 6,
                        onChanged: (v) => setState(() => _errorChance = v),
                        onChangeEnd: (_) => _rebuildCubit(),
                      ),
                    ),
                  ],
                ),

                // Delay slider
                _SliderRow(
                  label:
                      '${LocaleKeys.delayMs.tr()}: ${_delayMs}ms',
                  value: _delayMs.toDouble(),
                  min: 100,
                  max: 3000,
                  divisions: 29,
                  onChanged: (v) => setState(() => _delayMs = v.round()),
                  onChangeEnd: (_) => _rebuildCubit(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Bar ────────────────────────────────────────────────────────────

  Widget _buildStatusBar(BuildContext ctx) {
    return BlocBuilder<_FakePaginationCubit, PaginationState<_FakeItem>>(
      builder: (context, state) {
        final cubit = context.read<_FakePaginationCubit>();
        final count = cubit.data.length;
        final page = cubit.paginationQuery.page;
        final stateLabel = state.when(
          initial: () => 'initial',
          loading: () => 'loading…',
          success: (_, loading, error) =>
              loading ? 'loading p$page' : 'success',
          error: (_) => 'error',
          emptyData: () => 'empty',
        );

        return Container(
          color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _StatChip(LocaleKeys.page.tr(), '$page'),
              const SizedBox(width: 12),
              _StatChip(LocaleKeys.items.tr(), '$count'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: context.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  stateLabel,
                  style: context.textTheme.labelSmall
                      ?.copyWith(color: context.colorScheme.outline),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Action Row ────────────────────────────────────────────────────────────

  Widget _buildActionRow(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => ctx.read<_FakePaginationCubit>().triggerError(),
            style: OutlinedButton.styleFrom(
                foregroundColor: context.colorScheme.error,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
            icon: const Icon(Icons.error_outline, size: 16),
            label: Text(LocaleKeys.simulateError.tr(),
                style: context.textTheme.labelLarge),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => ctx.read<_FakePaginationCubit>().triggerEmpty(),
            style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
            icon: const Icon(Icons.inbox_outlined, size: 16),
            label: Text(LocaleKeys.simulateEmpty.tr(),
                style: context.textTheme.labelLarge),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => ctx.read<_FakePaginationCubit>().refresh(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: LocaleKeys.retry.tr(),
          ),
        ],
      ),
    );
  }

  // ── Pagination Content ────────────────────────────────────────────────────

  Widget _buildList(BuildContext ctx) {
    return PaginationBuilderWdg<_FakePaginationCubit, _FakeItem>(
      contentPadding: EdgeInsets.zero,
      loadingItemsWidget: _buildLoadingWidget(),
      loadingItemWidget: PageLoadingIndicator(style: _pageLoadingStyle),
      notItemsMsg: LocaleKeys.noItems.tr(),
      allItemWdg: _viewMode != _ViewMode.list ? _buildGrid : null,
      itemWdg: _viewMode == _ViewMode.list ? _buildListItem : null,
      separatorWidget: const Divider(height: 1),
    );
  }

  Widget _buildLoadingWidget() {
    return switch (_loadingStyle) {
      _LoadingStyle.shimmerList => const _ShimmerListLoading(),
      _LoadingStyle.shimmerGrid =>
        _ShimmerGridLoading(columns: _viewMode == _ViewMode.grid3 ? 3 : 2),
      _LoadingStyle.skeleton => const _SkeletonLoading(),
      _LoadingStyle.spinner => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _buildListItem(_FakeItem item) {
    final color = _kColors[item.colorIndex];
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(
          '#${item.title.split(' ').last}',
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(item.title, style: context.textTheme.bodyMedium),
      subtitle: Text(item.subtitle, style: context.textTheme.bodySmall),
      trailing: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  Widget _buildGrid(List<_FakeItem> items) {
    final columns = _viewMode == _ViewMode.grid3 ? 3 : 2;
    final ratio = _viewMode == _ViewMode.grid3 ? 0.82 : 1.0;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: ratio,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildGridCard(items[i]),
      ),
    );
  }

  Widget _buildGridCard(_FakeItem item) {
    final color = _kColors[item.colorIndex];
    final isSmall = _viewMode == _ViewMode.grid3;
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: isSmall ? 18 : 26,
            backgroundColor: color,
            child: Text(
              '#${item.title.split(' ').last}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 9 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: context.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          Text(
            item.subtitle,
            style: context.textTheme.labelSmall
                ?.copyWith(color: context.colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Loading Widgets ───────────────────────────────────────────────────────────

class _ShimmerListLoading extends StatelessWidget {
  const _ShimmerListLoading();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoadingWidget(
      child: Column(
        children: List.generate(
          6,
          (_) => Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 14,
                          width: double.infinity,
                          color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 120, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerGridLoading extends StatelessWidget {
  const _ShimmerGridLoading({required this.columns});
  final int columns;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoadingWidget(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: columns * 2,
          itemBuilder: (_, _) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonLoading extends StatelessWidget {
  const _SkeletonLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        7,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SkeletonWidget(width: 44, height: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonWidget(width: double.infinity, height: 14),
                    const SizedBox(height: 6),
                    SkeletonWidget(width: 100, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SelectorLabel extends StatelessWidget {
  const _SelectorLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.outline,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall
              ?.copyWith(color: context.colorScheme.outline),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(
        label,
        style: context.textTheme.labelSmall
            ?.copyWith(color: context.colorScheme.outline),
      ),
      const SizedBox(width: 4),
      Text(
        value,
        style: context.textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    ]);
  }
}
