import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app_template/core/foundation/contracts/pagination_query.dart';
import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';

part 'pagination_cubit.freezed.dart';
part 'pagination_state.dart';

abstract class PaginationCubit<E> extends SafeCubit<PaginationState<E>> {
  final ScrollController scrollController = ScrollController();
  PaginationQuery paginationQuery = const PaginationQuery();

  // Add this flag to track when we've reached the end of data
  bool _reachedEnd = false;

  PaginationCubit() : super(PaginationState.initial()) {
    _bindScrollController();
  }

  void reset() {
    paginationQuery = paginationQuery.copyWith(page: 1);
    _reachedEnd = false; // Reset the end flag when resetting pagination
    emit(const PaginationState.initial());
  }

  Future<Either<Failure, PaginationDataEntity<E>>> call();

  Future<void> nextPage() async {
    final successState = getSuccessState;

    if (successState == null) return refresh();

    if (successState.isLoading || successState.error != null) return;

    // If we've already determined we're at the end, don't fetch more
    if (_reachedEnd) return;

    paginationQuery = paginationQuery.copyWith(page: paginationQuery.page + 1);
    return getPage();
  }

  Future<void> refresh() {
    paginationQuery = const PaginationQuery();
    _reachedEnd = false; // Reset the end flag when getting first page
    emit(PaginationState.loading());
    return getPage();
  }

  Future<void> getPage() async {
    final currentPaginationEntity = state is PaginationSuccessState<E>
        ? (state as PaginationSuccessState<E>).paginationEntity
        : null;

    /// emit loading
    if (currentPaginationEntity == null) {
      emit(PaginationState.loading());
    } else {
      emit(PaginationState.success(currentPaginationEntity, isLoading: true));
    }

    /// get page data
    final result = await call();

    /// fold the result
    result.fold(
      (failure) {
        // CancelledFailure is intentional — do not change state.
        if (failure is CancelledFailure) return;

        // Session expired: auth bus fires first at interceptor/mapper level;
        // re-emit here as a deduplicated safety-net (no state change needed).
        if (failure is UnauthorizedFailure) {
          AuthEventBus.instance.emit(AuthEvent.sessionExpired);
          return;
        }

        // All other failures → surface an error state for the UI to render.
        if (currentPaginationEntity == null) {
          emit(PaginationState.error(failure));
        } else {
          emit(
            PaginationState.success(currentPaginationEntity, error: failure),
          );
        }
      },
      (r) {
        final data = List<E>.from(
          currentPaginationEntity == null ? [] : currentPaginationEntity.data,
        );

        // Check if we received empty data or fewer items than requested
        // This is critical to prevent infinite loading
        if (r.data.isEmpty || r.data.length < paginationQuery.perPage) {
          _reachedEnd = true;
        }

        final updatedPaginationEntity = r.copyWith(
          data: data..addAll(List<E>.from(r.data)),
        );

        if (updatedPaginationEntity.data.isEmpty) {
          emit(PaginationState.emptyData());
        } else {
          emit(PaginationState.success(updatedPaginationEntity));
        }
      },
    );
  }

  bool get isFirstPage {
    final successState = getSuccessState;
    if (successState == null) return true;
    if (successState.paginationEntity.paginationInfo.isFirstPage == true) {
      return true;
    }
    return false;
  }

  PaginationSuccessState<E>? get getSuccessState {
    if (state is! PaginationSuccessState) return null;
    return state as PaginationSuccessState<E>;
  }

  List<E> get data {
    if (state is! PaginationSuccessState<E>) return [];
    final PaginationSuccessState<E> successState =
        state as PaginationSuccessState<E>;
    return successState.paginationEntity.data;
  }

  bool isMatchedTwoEntity(E entity1, E entity2);

  void replaceEntityItem(E entity) {
    if (state is! PaginationSuccessState<E>) return;

    final PaginationSuccessState<E> successState =
        state as PaginationSuccessState<E>;

    final originData = List<E>.from(data);

    final int itemIndex = originData.indexWhere((element) {
      return isMatchedTwoEntity(entity, element);
    }, -1);

    if (itemIndex < 0) return;

    originData.replaceRange(itemIndex, itemIndex + 1, [entity]);
    final updatedState = successState.copyWith(
      paginationEntity: successState.paginationEntity.copyWith(
        data: originData,
      ),
    );
    emit(updatedState);
  }

  /// Removes every item matching [test] from the current page set.
  ///
  /// Call BEFORE the delete `await` for optimistic UI; call [restoreItems]
  /// with the pre-removal snapshot if the request fails.
  void removeItemWhere(bool Function(E) test) {
    if (state is! PaginationSuccessState<E>) return;

    final PaginationSuccessState<E> successState =
        state as PaginationSuccessState<E>;

    final updated = List<E>.from(data)..removeWhere(test);

    emit(
      successState.copyWith(
        paginationEntity: successState.paginationEntity.copyWith(
          data: updated,
        ),
      ),
    );
  }

  /// Restores a previously-saved snapshot — call on rollback after a failed
  /// optimistic [removeItemWhere] / [replaceEntityItem].
  void restoreItems(List<E> backup) {
    if (state is! PaginationSuccessState<E>) return;

    final PaginationSuccessState<E> successState =
        state as PaginationSuccessState<E>;

    emit(
      successState.copyWith(
        paginationEntity: successState.paginationEntity.copyWith(
          data: backup,
        ),
      ),
    );
  }

  /// Prepends a newly-created entity to the top of the list (e.g. after a
  /// create-form returns the server's canonical entity via `pop(entity)`).
  ///
  /// **Assumes the backend orders newest-first.** Without an explicit
  /// `ORDER BY`, Postgres returns rows in unspecified physical order, so the
  /// item lands at the top here and somewhere else after the next `refresh()`
  /// — which reads as a bug in this method rather than in the query. See #17.
  void prependItem(E entity) {
    if (state is! PaginationSuccessState<E>) return;

    final PaginationSuccessState<E> successState =
        state as PaginationSuccessState<E>;

    final updated = [entity, ...data];

    emit(
      successState.copyWith(
        paginationEntity: successState.paginationEntity.copyWith(
          data: updated,
        ),
      ),
    );
  }

  void _bindScrollController() {
    scrollController.addListener(() {
      if (state is! PaginationSuccessState<E>) return;
      final successState = state as PaginationSuccessState<E>;

      // Check both the isLastPage flag from API AND our own _reachedEnd flag
      final bool isLastPage =
          successState.paginationEntity.paginationInfo.isLastPage ||
          _reachedEnd;

      if (isLastPage) return;

      final scrollDir = scrollController.position.userScrollDirection;
      if (scrollDir == ScrollDirection.reverse &&
          scrollController.position.extentAfter < 100) {
        nextPage();
      }
    });
  }

  // The `emit` override that used to live here (`if (isClosed) return;`) is now
  // [SafeCubit]'s job — and that is the point of the move, not a tidy-up: the
  // guard existed HERE ONLY, so paginated lists survived a late response while
  // every other cubit in the app crashed on one. A protection that correct in
  // one file and absent in twenty is an accident waiting for the next screen.

  @override
  void onChange(Change<PaginationState<E>> change) {
    super.onChange(change);
  }
}
