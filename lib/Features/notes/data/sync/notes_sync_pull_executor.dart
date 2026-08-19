import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:app_template/Features/notes/data/datasources/notes_remote_datasource.dart';
import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/errors/failure_mapper_registry.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';

/// Downloads note changes from the server — the other direction from
/// [NotesSyncExecutor], and the reason a device that has never written anything
/// still ends up with data.
///
/// Optional by design: an entity with no pull executor is simply never pulled.
/// Notes register one because they are edited on more than one device.
@LazySingleton(as: SyncPullExecutor)
class NotesSyncPullExecutor implements SyncPullExecutor {
  const NotesSyncPullExecutor(this._dataSource);

  final NotesRemoteDataSource _dataSource;

  @override
  String get entityName => 'notes';

  @override
  Future<Either<Failure, SyncPullPage>> pull({
    required SyncCursor cursor,
    required bool includeDeleted,
    required int limit,
  }) async {
    final ApiResponse<Map<String, dynamic>> res;
    try {
      res = await _dataSource.delta(
        updatedSince: cursor.updatedSince,
        afterId: cursor.afterId,
        includeDeleted: includeDeleted,
        limit: limit,
      );
    } on DioException catch (e) {
      // Dio's default `validateStatus` accepts only 2xx, so a 401, 404 or 500
      // arrives as a throw rather than as the `res.error` envelope below. Left
      // to escape, it unwound past `_pullEntity` into the engine's per-entity
      // catch — which reached the same outcome by accident, while the `Left`
      // path this method was written around stayed unreachable.
      //
      // Returning the mapped failure puts every refusal on one path: the engine
      // logs the page as failed and **keeps the cursor**, so the next cycle
      // re-requests the same window and nothing is skipped.
      return Left(FailureMapperRegistry.map(e, source: 'notes_pull'));
    }

    if (res.error != null) {
      return Left(BusinessFailure(
        statusCode: res.error?.code ?? 400,
        serverMessage: res.message.isNotEmpty ? res.message : null,
      ));
    }

    final data = res.data;
    if (data == null) {
      return const Left(BusinessFailure(statusCode: 400));
    }

    final serverTime = data['server_time'] as String?;
    if (serverTime == null) {
      // Without the server's clock there is nothing safe to advance the cursor
      // to. Falling back to the device's own would skip every row written in
      // the gap between the two clocks — permanently, because a cursor only
      // moves forward — so the honest move is to fail the page and keep the
      // cursor exactly where it was.
      return const Left(BusinessFailure(statusCode: 502));
    }

    final rawCursor = data['next_cursor'] as Map<String, dynamic>?;

    return Right(
      SyncPullPage(
        records: (data['data'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>(),
        serverTime: serverTime,
        // `null` means caught up — and it, not an empty page, is what ends the
        // loop: a full page whose rows share one timestamp is not the end.
        nextCursor: rawCursor == null ? null : SyncCursor.fromJson(rawCursor),
      ),
    );
  }
}
