import 'package:flutter/material.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/shared/widgets/states/empty_state_widget.dart';
import 'package:app_template/shared/widgets/states/error_state_widget.dart';
import 'package:app_template/shared/widgets/states/loading_widget.dart';
import 'package:app_template/presentation/shared/pagination/pagination_cubit.dart';

class PaginationBuilderWdg<C extends PaginationCubit<E>, E>
    extends StatefulWidget {
  const PaginationBuilderWdg({
    super.key,
    this.loadingItemsWidget,
    this.itemWdg,
    this.allItemWdg,
    this.separatorWidget,
    this.loadingItemWidget,
    this.notItemsMsg,
    this.emptyList,
    this.wantKeepAlive = false,
    this.contentPadding,
  });

  final Widget? loadingItemsWidget;
  final Widget? loadingItemWidget;
  final Widget Function(E)? itemWdg;
  final Widget Function(List<E>)? allItemWdg;
  final Widget? separatorWidget;
  final String? notItemsMsg;

  /// if no items found
  final Widget? emptyList;
  final bool wantKeepAlive;

  /// Override the default horizontal padding (24px) around the scroll content.
  /// Pass [EdgeInsets.zero] when the parent container already handles margins.
  final EdgeInsets? contentPadding;

  @override
  State<PaginationBuilderWdg<C, E>> createState() =>
      _PaginationBuilderWdgState<C, E>();
}

class _PaginationBuilderWdgState<C extends PaginationCubit<E>, E>
    extends State<PaginationBuilderWdg<C, E>>
    with AutomaticKeepAliveClientMixin {
  late final C paginationCubit;

  @override
  void initState() {
    super.initState();
    paginationCubit = context.read<C>();
    paginationCubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<C, PaginationState<E>>(
      builder: (context, paginationState) {
        return paginationState.when(
          loading: () => widget.loadingItemsWidget ?? const LoadingWidget(),
          initial: () => widget.loadingItemsWidget ?? const LoadingWidget(),
          error: (f) {
            if (f == null) return const SizedBox.shrink();
            final action = FailureUiMapper.toAction(f);
            if (action case ShowError(:final message)) {
              return ErrorStateWidget(
                messageKey: message,
                onRetry: paginationCubit.getPage,
              );
            }
            return const SizedBox.shrink();
          },
          success: (entity, loading, error) => Padding(
            padding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 24.0),
            child: RefreshIndicator(
              onRefresh: paginationCubit.refresh,
              child: CustomScrollView(
                controller: paginationCubit.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (widget.allItemWdg != null)
                    SliverToBoxAdapter(
                      child: widget.allItemWdg!(entity.data.cast<E>()),
                    )
                  else
                    SliverList.separated(
                      itemBuilder: (context, index) {
                        return widget.itemWdg!(entity.data[index]);
                      },
                      separatorBuilder: (context, index) {
                        return widget.separatorWidget ??
                            const SizedBox(height: 12);
                      },
                      itemCount: entity.data.length,
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SizeTransition(
                          sizeFactor: anim,
                          axisAlignment: -1,
                          child: child,
                        ),
                      ),
                      child: _buildNextPageStatus(loading, error),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
          ),
          emptyData: () =>
              widget.emptyList ??
              EmptyStateWidget(
                titleKey: widget.notItemsMsg ?? 'no Available Items',
                onAction: paginationCubit.getPage,
              ),
        );
      },
    );
  }

  Widget _buildNextPageStatus(bool loading, Failure? error) {
    if (loading) {
      return KeyedSubtree(
        key: const ValueKey('next_loading'),
        child: widget.loadingItemWidget ?? const LoadingWidget(),
      );
    }
    if (error != null) {
      final action = FailureUiMapper.toAction(error);
      if (action case ShowError(:final message)) {
        return KeyedSubtree(
          key: const ValueKey('next_error'),
          child: ErrorStateWidget(
            messageKey: message,
            onRetry: paginationCubit.getPage,
          ),
        );
      }
    }
    return const SizedBox.shrink(key: ValueKey('next_none'));
  }

  @override
  bool get wantKeepAlive => widget.wantKeepAlive;
}
