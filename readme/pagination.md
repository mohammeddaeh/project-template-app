# Pagination Guide

> **مرجع معماري:** [`core_architecture.md`](core_architecture.md)  
> **يُحدَّث هذا الملف** عند تغيير `presentation/shared/pagination/` أو نمط pagination في Features.

Reusable infinite-scroll pagination for REST-backed lists.

Reference implementation: **Users** feature.

## 1) Components

| Piece | Location |
|-------|----------|
| `PaginationQuery` | `core/foundation/contracts/pagination_query.dart` |
| `PaginationDataEntity` | `core/foundation/contracts/pagination_data_entity.dart` |
| `PaginationCubit` | `presentation/shared/pagination/pagination_cubit.dart` |
| `PaginationBuilderWdg` | `shared/widgets/lists/pagination_builder_wdg.dart` |
| Feature cubit | `Features/<name>/presentation/cubits/` |
| Feature page | `Features/<name>/presentation/pages/` |

## 2) What You Need Per Feature

1. Domain page entity (`UsersPage` — items + totalPages)
2. Cubit extending `PaginationCubit<T>`
3. Page using `PaginationBuilderWdg`

## 3) Data and Domain

API response should include items + paging metadata.

Reference:

- `lib/Features/users/data/models/users_response.dart`
- `lib/Features/users/domain/entities/users_page.dart`
- `lib/Features/users/domain/entities/user.dart`

## 4) Cubit Setup

Extend `PaginationCubit<T>` and implement:

- `call()` → `Either<Failure, PaginationDataEntity<T>>`
- `isMatchedTwoEntity()` → duplicate detection

Reference: `lib/Features/users/presentation/cubits/users_cubit.dart`

```dart
@injectable
class UsersCubit extends PaginationCubit<User> {
  UsersCubit(this._getUsers) : super();

  final GetUsers _getUsers;

  @override
  Future<Either<Failure, PaginationDataEntity<User>>> call() async {
    final res = await _getUsers(GetUsersParams(paginationQuery: paginationQuery));
    return res.fold(Left.new, (usersPage) {
      final isLastPage = paginationQuery.page >= usersPage.totalPages;
      return Right(PaginationDataEntity<User>(
        data: usersPage.items,
        paginationInfo: PaginationInfo(
          isFirstPage: paginationQuery.page == 1,
          isLastPage: isLastPage,
        ),
      ));
    });
  }

  @override
  bool isMatchedTwoEntity(User a, User b) => a.id == b.id;
}
```

## 5) Page Setup

```dart
BlocProvider(
  create: (_) => getIt<UsersCubit>(),
  child: PaginationBuilderWdg<UsersCubit, User>(
    loadingItemsWidget: _buildShimmerList(),
    itemWdg: (user) => _buildUserItem(user),
    separatorWidget: const SizedBox(height: 8),
    contentPadding: EdgeInsets.zero,
  ),
)
```

Reference: `lib/Features/users/presentation/pages/users_screen.dart`

## 6) Controls

```dart
final cubit = context.read<UsersCubit>();
cubit.refresh();
cubit.nextPage();
cubit.reset();
```

## 7) Error Handling

`PaginationBuilderWdg` uses `FailureUiMapper.toAction()` internally.
`PaginationCubit` handles `CancelledFailure` and `UnauthorizedFailure` at infrastructure level.

## 8) Page Loading Indicator (Next-Page Loader)

`PaginationBuilderWdg.loadingItemWidget` shows at the bottom of the list when fetching the next page.
It transitions in/out via `AnimatedSwitcher` (fade + size).

Use `PageLoadingIndicator` from `shared/widgets/widgets.dart` for 6 built-in styles:

| Style | Description |
|---|---|
| `PageLoadingStyle.spinner` | Circular spinner (default) |
| `PageLoadingStyle.linearBar` | Horizontal `LinearProgressIndicator` |
| `PageLoadingStyle.shimmerBar` | Shimmer strip |
| `PageLoadingStyle.dotsWave` | 3 bouncing dots |
| `PageLoadingStyle.textSpinner` | "Loading more…" + small spinner |
| `PageLoadingStyle.pulseDots` | 3 pulsing/scaling dots |

```dart
PaginationBuilderWdg<MyCubit, MyEntity>(
  loadingItemWidget: PageLoadingIndicator(
    style: PageLoadingStyle.dotsWave,
    loadingText: LocaleKeys.loadingMore.tr(), // optional override for textSpinner
  ),
  ...
)
```

> **Mirror Law:** Any new `PageLoadingStyle` value → add a segment in `TestPaginationDemoScreen` selector + live preview.

## 9) Common Mistakes

- Returning API models to UI instead of domain entities
- Missing `isMatchedTwoEntity()` → infinite duplicate loads
- Manual scroll listener while using `PaginationBuilderWdg`
- Putting `PaginationCubit` back in `core/` (it belongs in `presentation/shared/pagination/`)

## 9) Quick Checklist

- [ ] API returns items + page metadata
- [ ] Domain page entity created
- [ ] Cubit extends `PaginationCubit<T>` in `presentation/cubits/`
- [ ] `call()` returns `Either<Failure, PaginationDataEntity<T>>`
- [ ] Page uses `PaginationBuilderWdg`
- [ ] `dart analyze lib` passes

## 10) Related Docs

- [`core_architecture.md`](core_architecture.md) — architecture principles
- [`rest_api.md`](rest_api.md) — REST flow
- [`widgets.md`](widgets.md) — PaginationBuilderWdg placement

*Last updated: 2026-06-17*
