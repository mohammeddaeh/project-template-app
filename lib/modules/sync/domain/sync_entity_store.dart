import '../automation/sync_feature_contract.dart';
import 'sync_entity_record.dart';

/// Position of the last row a page returned — the cursor the next page resumes
/// from.
///
/// A **pair**, for the same reason the pull cursor is one: `updated_at` is not
/// unique, and a page boundary that lands inside a group of rows sharing a
/// millisecond either skips the rest of that group or repeats it forever.
class SyncPageCursor {
  const SyncPageCursor({required this.updatedAt, required this.localId});

  final int updatedAt;
  final String localId;
}

/// A typed page and the cursor that continues it.
///
/// The cursor comes back with the rows rather than being asked for separately,
/// because deriving it needs the raw records — and a caller that had to fetch
/// those too would run the same query twice to page once.
class SyncTypedPage<T> {
  const SyncTypedPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<T> items;

  /// A full page means "there may be more". Guessing wrong here costs one empty
  /// request; guessing wrong the other way truncates the user's own data.
  final bool hasMore;

  /// `null` when the page came back empty — there is nothing to resume from.
  ///
  /// Taken from the **last stored record**, not the last parsed item: a row
  /// that failed to parse is skipped from `items` but still occupies its place
  /// in the ordering, and a cursor that ignored it would serve it again on
  /// every page from here on.
  final SyncPageCursor? nextCursor;
}

abstract class SyncEntityStore {
  Future<void> upsertRecord(SyncEntityRecord record);

  /// [notify] exists to break one specific feedback loop.
  ///
  /// A repository that caches what it just read from the network calls this on
  /// every list refresh. If that announced a change, a screen listening for
  /// changes would refresh, which would read, which would cache, which would
  /// announce — a loop that never settles and looks like a network storm.
  ///
  /// So a **read-through cache passes `false`**, and every write that carries
  /// new information leaves it `true`.
  Future<void> upsertRecords(List<SyncEntityRecord> records, {bool notify = true});

  /// Fires whenever [entityName]'s local rows change — from a user write, a
  /// pull merge, or a push result.
  ///
  /// This is what turns the local store into a source a screen can *follow*
  /// rather than poll. Without it the only way to notice a sync was to re-read
  /// on a timer, which is either too slow to be useful or too frequent to be
  /// free.
  Stream<void> watch(String entityName);

  /// Page-numbered read. **Small sets only.**
  ///
  /// Uses `OFFSET`, so page N makes SQLite walk and discard the N-1 pages
  /// before it: the cost grows with depth, and the last pages — the ones a
  /// device with a long backlog reaches — are the slowest. Prefer
  /// [getRecordsAfter] for anything that pages more than a screen or two; the
  /// threshold gets a number in `RULES.md` §ب١ once P8 measures it.
  Future<List<SyncEntityRecord>> getRecordsByEntity({
    required String entityName,
    required int page,
    required int limit,
    bool includeDeleted = false,
  });

  /// Keyset read — constant cost at any depth.
  ///
  /// [cursor] is the last row of the previous page; `null` starts at the
  /// newest. Ordered `updated_at DESC, local_id DESC`, which is the order the
  /// cursor comparison assumes.
  Future<List<SyncEntityRecord>> getRecordsAfter({
    required String entityName,
    required int limit,
    SyncPageCursor? cursor,
    bool includeDeleted = false,
  });

  /// Reads rows already parsed into their entity type, using the contract's own
  /// [SyncFeatureContract.fromJson].
  ///
  /// The three typed members of `SyncFeatureContract` were declared when the
  /// module was written and called by **nothing** for its whole life: every
  /// feature was obliged to implement `toJson`/`fromJson`/`localIdOf`, and the
  /// engine passed `dataJson` around as raw text regardless. This is the read
  /// that finally uses them — so a repository stops hand-decoding rows the
  /// module already knows how to decode.
  ///
  /// A row whose JSON cannot be parsed is **skipped, not fatal**: one corrupt
  /// record must not blank a list.
  Future<SyncTypedPage<T>> readTyped<T>({
    required SyncFeatureContract<T> contract,
    required int limit,
    SyncPageCursor? cursor,
    bool includeDeleted = false,
  });

  /// Returns the single record matching [entityName] + [localId], or null.
  /// Used by conflict resolution to fetch the EXACT conflicting record.
  Future<SyncEntityRecord?> getRecordByLocalId({
    required String entityName,
    required String localId,
  });
  Future<int> countRecordsByEntity({
    required String entityName,
    bool includeDeleted = false,
  });
}
