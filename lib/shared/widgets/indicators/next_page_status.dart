import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/indicators/page_loading_indicator.dart';
import 'package:app_template/shared/widgets/states/failure_state_view.dart';

/// How a finished list announces that it is finished.
enum ListEndMarker {
  /// Nothing. For short lists where "that's all" is obvious from the fact that
  /// the screen did not fill.
  none,

  /// A short centred rule. Enough to end the list without narrating it.
  line,

  /// The rule plus a word. For long lists, where the difference between "the
  /// end" and "still loading" is a real question the reader is asking.
  label,
}

/// Everything that can be true at the bottom of a paginated list, in one place.
///
/// ## Why one widget rather than a line of code per list
///
/// The tail of a list has four possible states and every list in this app got a
/// different subset of them. Two sections rendered a bare `TextButton` that gave
/// **no feedback at all** when pressed — the request went out, the button stayed
/// exactly as it was, and a second press did nothing because the cubit guards
/// against it. The candidate picker rendered the word "loading" *outside* its
/// scroll box. None of them rendered a next-page failure, so losing the network
/// while scrolling left the list frozen with no message: `PaginationCubit` puts
/// the failure on the success state (`success(entity, error: …)`) and refuses
/// further pages until it clears, and nothing on screen was reading that field.
/// The list simply stopped growing, silently, forever.
///
/// The four states, in priority order:
///
/// | state | what the reader sees |
/// |---|---|
/// | fetching the next page | [PageLoadingIndicator], six styles |
/// | the next page failed | one row: why, plus retry — offline named as offline |
/// | more pages, no auto-scroll | the load-more button |
/// | no more pages | [ListEndMarker], or nothing |
class NextPageStatus extends StatelessWidget {
  const NextPageStatus({
    super.key,
    required this.isLoading,
    this.error,
    this.isLastPage = false,
    this.onRetry,
    this.onLoadMore,
    this.style = PageLoadingStyle.dotsWave,
    this.loadingWidget,
    this.loadingText,
    this.endMarker = ListEndMarker.none,
    this.showEndMarker = true,
  });

  /// A next page is in flight.
  final bool isLoading;

  /// The next page failed. Carried on `PaginationSuccessState.error` — the rows
  /// already loaded are still valid, so this is a tail state, not a screen
  /// state.
  final Failure? error;

  final bool isLastPage;

  /// Retries the failed page. Usually `cubit.getPage` — NOT `refresh`, which
  /// would discard every row already in hand to re-fetch page one.
  final VoidCallback? onRetry;

  /// Supplied only by lists that do **not** page on scroll (an embedded section
  /// inside a larger scrolling screen, where the list has no scroll extent of
  /// its own to reach the end of). When null, no button is drawn — the scroll
  /// controller is doing the asking.
  final VoidCallback? onLoadMore;

  final PageLoadingStyle style;

  /// Replaces the built-in [PageLoadingIndicator] entirely. Prefer [style].
  final Widget? loadingWidget;

  /// Text for [PageLoadingStyle.textSpinner]. Defaults to `loadingMore`.
  final String? loadingText;

  final ListEndMarker endMarker;

  /// Lets the caller suppress the marker for a list too short to have needed
  /// one — three rows followed by "end of list" states the obvious.
  final bool showEndMarker;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SizeTransition(
          sizeFactor: anim,
          axisAlignment: -1,
          child: child,
        ),
      ),
      child: _child(context),
    );
  }

  Widget _child(BuildContext context) {
    if (isLoading) {
      return KeyedSubtree(
        key: const ValueKey('next_loading'),
        child:
            loadingWidget ??
            PageLoadingIndicator(
              style: style,
              loadingText: loadingText ?? LocaleKeys.loadingMore.tr(),
            ),
      );
    }

    final failure = error;
    if (failure != null) {
      return KeyedSubtree(
        key: const ValueKey('next_error'),
        child: FailureStateView.compact(failure: failure, onRetry: onRetry),
      );
    }

    if (!isLastPage && onLoadMore != null) {
      return Padding(
        key: const ValueKey('next_more'),
        padding: const EdgeInsets.only(top: 4),
        child: Center(
          child: TextButton.icon(
            onPressed: onLoadMore,
            icon: const Icon(Icons.expand_more, size: 18),
            label: Text(LocaleKeys.loadMore.tr()),
          ),
        ),
      );
    }

    if (isLastPage && showEndMarker && endMarker != ListEndMarker.none) {
      return _EndMarker(key: const ValueKey('next_end'), marker: endMarker);
    }

    return const SizedBox.shrink(key: ValueKey('next_none'));
  }
}

class _EndMarker extends StatelessWidget {
  const _EndMarker({super.key, required this.marker});

  final ListEndMarker marker;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final line = Expanded(
      child: Divider(color: colors.textMuted.withValues(alpha: 0.25)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          line,
          if (marker == ListEndMarker.label) ...[
            const SizedBox(width: 12),
            Text(
              LocaleKeys.endOfList.tr(),
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
          ],
          line,
        ],
      ),
    );
  }
}
