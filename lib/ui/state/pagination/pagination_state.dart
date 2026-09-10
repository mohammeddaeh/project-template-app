part of 'pagination_cubit.dart';

@freezed
abstract class PaginationState<E> with _$PaginationState {
  const PaginationState._();

  const factory PaginationState.loading() = PaginationLoadingState;

  const factory PaginationState.error([Failure? error]) =
      PaginationErrorState;

  const factory PaginationState.initial() = PaginationInitState;

  const factory PaginationState.success(
    PaginationDataEntity<E> paginationEntity, {
    @Default(false) bool isLoading,
    Failure? error,
  }) = PaginationSuccessState;

  const factory PaginationState.emptyData() = PaginationEmptyState;
}
