import 'package:flutter/material.dart';

class PaginatedListView extends StatelessWidget {
  const PaginatedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onLoadMore,
    this.loadMoreThreshold = 3,
    this.loadingWidget,
    this.hasMore = true,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final VoidCallback? onLoadMore;
  final int loadMoreThreshold;
  final Widget? loadingWidget;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount + (hasMore && onLoadMore != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= itemCount) {
          if (hasMore && onLoadMore != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore!());
            return loadingWidget ??
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
          }
          return const SizedBox.shrink();
        }
        if (onLoadMore != null &&
            hasMore &&
            index >= itemCount - loadMoreThreshold) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore!());
        }
        return itemBuilder(context, index);
      },
    );
  }
}
