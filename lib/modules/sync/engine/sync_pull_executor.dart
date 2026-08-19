import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';

/// Where a delta pull resumes from.
///
/// A **pair**, not a timestamp. `updated_at` alone is not unique: a page that
/// ends in the middle of a group of rows written in the same millisecond has no
/// way to continue — a `>` cursor skips the rest of that group forever, a `>=`
/// cursor re-sends it on every cycle. The `(timestamp, id)` pair is unique and
/// monotonic, so neither happens.
///
/// [updatedSince] is `null` on a device that has never synced this entity,
/// which means "send everything".
class SyncCursor {
  const SyncCursor({this.updatedSince, this.afterId});

  final String? updatedSince;
  final String? afterId;

  bool get isBeginning => updatedSince == null;

  Map<String, dynamic> toJson() => {
        if (updatedSince != null) 'updated_since': updatedSince,
        if (afterId != null) 'after_id': afterId,
      };

  factory SyncCursor.fromJson(Map<String, dynamic> json) => SyncCursor(
        updatedSince: json['updated_since'] as String?,
        afterId: json['after_id'] as String?,
      );
}

/// One page of server changes.
class SyncPullPage {
  const SyncPullPage({
    required this.records,
    required this.serverTime,
    this.nextCursor,
  });

  /// Raw entity JSON, exactly as the server sent it — tombstones included.
  ///
  /// Not deserialised here: the engine stores `dataJson` verbatim, and parsing
  /// it twice (once to inspect, once to store) is two chances for the copies to
  /// differ. Every record carries `id`, `updated_at`, `version` and
  /// `is_deleted` by the contract in `SETUP.md` §6.
  final List<Map<String, dynamic>> records;

  /// The server's clock, to be sent back as the next `updated_since`.
  ///
  /// **Never the device's own.** A phone running two minutes fast would skip
  /// every row written in those two minutes — permanently, because a cursor
  /// only moves forward — and both sides would report success.
  final String serverTime;

  /// `null` when the client has caught up.
  ///
  /// That, and not an empty [records], is what ends the loop: a full page whose
  /// rows all share one timestamp is not the end of the changes.
  final SyncCursor? nextCursor;
}

/// Fetches server changes for one entity. **The mirror of [SyncExecutor], and
/// deliberately a separate interface.**
///
/// `SyncExecutor` is documented as push-only — "NEVER call a GET inside an
/// executor" — because reads belong to the repository, which is the only thing
/// the UI talks to. Bolting `pull` onto it would contradict that in its own
/// contract, and would force every push-only entity to implement a method it
/// does not want.
///
/// Optional per entity: a feature that only ever uploads (an audit trail, a
/// crash report) registers no pull executor and the engine simply never pulls
/// it. Registration is `@LazySingleton(as: SyncPullExecutor)`.
abstract class SyncPullExecutor {
  String get entityName;

  /// Requests one page of changes after [cursor].
  ///
  /// [includeDeleted] is what carries a delete to a device that already has the
  /// row — a query cannot report an absence, so the tombstone is the only news
  /// that ever arrives.
  Future<Either<Failure, SyncPullPage>> pull({
    required SyncCursor cursor,
    required bool includeDeleted,
    required int limit,
  });
}
