import 'package:flutter/material.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/ui/error/failure_ui_mapper.dart';
import 'package:app_template/ui/error/ui_action.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_template/ui/widgets/states/empty_state_widget.dart';
import 'package:app_template/ui/widgets/states/error_state_widget.dart';
import 'package:app_template/ui/widgets/states/loading_widget.dart';
import 'package:app_template/ui/state/pagination/pagination_cubit.dart';
import 'package:app_template/ui/widgets/lists/list_appear_tracker.dart';
import 'package:app_template/ui/widgets/lists/list_item_appear.dart';

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
    this.itemAppear = ListItemAppear.fadeSlide,
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

  /// كيف يظهر كل صفٍّ **أوّل مرّة** — متتالياً داخل دفعته ([ListAppearTracker]).
  /// `ListItemAppear.none` لقائمةٍ كثيفة تكون الحركةُ فيها ضجيجاً.
  final ListItemAppear itemAppear;

  @override
  State<PaginationBuilderWdg<C, E>> createState() =>
      _PaginationBuilderWdgState<C, E>();
}

class _PaginationBuilderWdgState<C extends PaginationCubit<E>, E>
    extends State<PaginationBuilderWdg<C, E>>
    with AutomaticKeepAliveClientMixin {
  final _appear = ListAppearTracker();

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
            padding:
                widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 24.0),
            child: RefreshIndicator(
              onRefresh: () {
                _appear.reset();
                return paginationCubit.refresh();
              },
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
                        _appear.observeLength(entity.data.length);
                        final item = widget.itemWdg!(entity.data[index]);
                        final order = _appear.staggerFor(index);
                        if (order == null ||
                            widget.itemAppear == ListItemAppear.none) {
                          return item;
                        }
                        return ListItemAppearWdg(
                          animation: widget.itemAppear,
                          staggerIndex: order,
                          child: item,
                        );
                      },
                      separatorBuilder: (context, index) {
                        return widget.separatorWidget ??
                            const SizedBox(height: 12);
                      },
                      itemCount: entity.data.length,
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: _NextPageTail(
                      loading: loading,
                      error: error,
                      loadingItemWidget: widget.loadingItemWidget,
                      onRetry: paginationCubit.getPage,
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

  @override
  bool get wantKeepAlive => widget.wantKeepAlive;
}

/// ذيل القائمة: تحميل الصفحة التالية · فشلها · لا شيء.
class _NextPageTail extends StatelessWidget {
  const _NextPageTail({
    required this.loading,
    required this.error,
    required this.loadingItemWidget,
    required this.onRetry,
  });

  final bool loading;
  final Failure? error;
  final Widget? loadingItemWidget;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // الـswitcher يحرّك الانتقال بمفتاح ابنه المباشر — فيُبنى كلّ حالٍ هنا بمفتاحه.
    final failure = error;
    final action = loading || failure == null
        ? null
        : FailureUiMapper.toAction(failure);
    final Widget child;
    if (loading) {
      child = KeyedSubtree(
        key: const ValueKey('next_loading'),
        child: loadingItemWidget ?? const LoadingWidget(),
      );
    } else if (action case ShowError(:final message)) {
      child = KeyedSubtree(
        key: const ValueKey('next_error'),
        child: ErrorStateWidget(messageKey: message, onRetry: onRetry),
      );
    } else {
      child = const SizedBox.shrink(key: ValueKey('next_none'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SizeTransition(
          sizeFactor: anim,
          axisAlignment: -1,
          child: child,
        ),
      ),
      child: child,
    );
  }
}
