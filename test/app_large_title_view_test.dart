import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/foundation/contracts/pagination_data_entity.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/ui/state/pagination/pagination_cubit.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/layout/app_large_title_view.dart';
import 'package:app_template/ui/widgets/lists/list_item_appear.dart';
import 'package:app_template/ui/widgets/lists/pagination_builder.dart';

/// 60 rows, 15 a page — enough that reaching the tail needs page two.
class _Rows extends PaginationCubit<int> {
  int pagesFetched = 0;

  @override
  Future<Either<Failure, PaginationDataEntity<int>>> call() async {
    pagesFetched++;
    final start = (paginationQuery.page - 1) * paginationQuery.perPage;
    final end = (start + paginationQuery.perPage).clamp(0, 60);
    return Right(
      PaginationDataEntity(
        data: [for (var i = start; i < end; i++) i],
        paginationInfo: PaginationInfo(
          isFirstPage: paginationQuery.page == 1,
          isLastPage: end >= 60,
        ),
      ),
    );
  }

  @override
  bool isMatchedTwoEntity(int a, int b) => a == b;
}

Widget _host(Widget body) => MaterialApp(
  theme: AppThemeData.light(const Locale('en'), AppFonts.available.first),
  home: Scaffold(
    body: AppLargeTitleView(title: 'Title', body: body),
  ),
);

/// Where the list's viewport starts — the header's bottom edge. A row's own
/// position would move either way: the list scrolls whether or not the header
/// collapses.
double _headerBottom(WidgetTester tester, String row) => tester
    .getTopLeft(
      find
          .ancestor(of: find.text(row), matching: find.byType(Scrollable))
          .first,
    )
    .dy;

void main() {
  testWidgets('the title collapses as the list scrolls under it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ListView.builder(
          itemCount: 50,
          itemBuilder: (_, i) => SizedBox(height: 60, child: Text('row $i')),
        ),
      ),
    );
    final before = _headerBottom(tester, 'row 0');

    await tester.drag(find.text('row 0'), const Offset(0, -80));
    await tester.pumpAndSettle();

    expect(_headerBottom(tester, 'row 2'), lessThan(before - 40));
  });

  testWidgets('a PaginationBuilder inside collapses it and still pages', (
    tester,
  ) async {
    final cubit = _Rows();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      _host(
        BlocProvider<_Rows>.value(
          value: cubit,
          child: PaginationBuilder<_Rows, int>(
            itemAppear: ListItemAppear.none,
            itemBuilder: (i) => SizedBox(height: 60, child: Text('item $i')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(cubit.pagesFetched, 1);
    final before = _headerBottom(tester, 'item 0');

    await tester.drag(find.text('item 0'), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(_headerBottom(tester, 'item 2'), lessThan(before - 40));

    // Toward the tail of page one: the next page is asked for from the
    // scroll notifications, not from the cubit's own controller.
    await tester.drag(find.text('item 3'), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(cubit.pagesFetched, greaterThan(1));
  });
}
