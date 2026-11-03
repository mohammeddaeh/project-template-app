import 'package:flutter/material.dart';

import 'package:app_template/ui/widgets/indicators/app_progress.dart';
import 'package:app_template/ui/widgets/lists/list_appear_tracker.dart';
import 'package:app_template/ui/widgets/lists/list_item_appear.dart';

class PaginatedListView extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onLoadMore,
    this.loadMoreThreshold = 3,
    this.loadingWidget,
    this.hasMore = true,
    this.itemAppear = ListItemAppear.fadeSlide,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final VoidCallback? onLoadMore;
  final int loadMoreThreshold;
  final Widget? loadingWidget;
  final bool hasMore;

  /// كيف يظهر كل صفٍّ **أوّل مرّة** — متتالياً داخل دفعته ([ListAppearTracker]).
  final ListItemAppear itemAppear;

  @override
  State<PaginatedListView> createState() => _PaginatedListViewState();
}

class _PaginatedListViewState extends State<PaginatedListView> {
  final _appear = ListAppearTracker();

  @override
  Widget build(BuildContext context) {
    final widget = this.widget;
    _appear.observeLength(widget.itemCount);
    return ListView.builder(
      itemCount:
          widget.itemCount +
          (widget.hasMore && widget.onLoadMore != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.itemCount) {
          if (widget.hasMore && widget.onLoadMore != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.onLoadMore!(),
            );
            return widget.loadingWidget ??
                const AppProgress.circular(
                  centered: true,
                  padding: EdgeInsets.all(16),
                );
          }
          return const SizedBox.shrink();
        }
        if (widget.onLoadMore != null &&
            widget.hasMore &&
            index >= widget.itemCount - widget.loadMoreThreshold) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onLoadMore!(),
          );
        }
        final item = widget.itemBuilder(context, index);
        final order = _appear.staggerFor(index);
        if (order == null || widget.itemAppear == ListItemAppear.none) {
          return item;
        }
        return ListItemEntrance(
          animation: widget.itemAppear,
          staggerIndex: order,
          child: item,
        );
      },
    );
  }
}
