/// Builds `updated_at` query filters for delta-sync API requests.
///
/// ## What is delta sync?
/// Instead of fetching all records on every request, delta sync fetches only
/// records that changed since a known timestamp — drastically reducing payload
/// size and server load.
///
/// ## Prerequisite
/// Your backend API must support an `updated_at` filter. If it doesn't, simply
/// do not use this utility — it has zero effect on the rest of the project.
///
/// ## Customisation
/// Field names (`updated_at`, `strategy`, `greater_than_or_equal`) are set as
/// constants at the top of the class. Rename them once to match your API
/// contract — all call sites update automatically.
///
/// ## Usage
///
/// ### As JSON body / query-params Map
/// ```dart
/// final filter = UpdatedAtFilter.since(lastSyncTime);
/// // → {'updated_at': {'strategy': 'gte', 'value': '2024-01-15T...'}}
/// await _api.getUsers(filter: filter);
/// ```
///
/// ### Appended to a URL string
/// ```dart
/// final url = UpdatedAtFilter.buildUrl('users/index', since: lastSyncTime);
/// // → 'users/index&filter[updated_at][strategy]=gte&...'
/// ```
///
/// ### Full fetch (no filter)
/// ```dart
/// final url = UpdatedAtFilter.buildUrl('users/index', since: null);
/// // → 'users/index'  (no filter appended)
/// ```
abstract final class UpdatedAtFilter {
  UpdatedAtFilter._();

  // ── Field names — adapt to your API contract ──────────────────────────────

  /// Top-level filter field name sent to the API.
  static const String _field = 'updated_at';

  /// Strategy key inside the filter object.
  static const String _strategyKey = 'strategy';

  /// Strategy value meaning "greater than or equal".
  static const String _strategyValue = 'greater_than_or_equal';

  /// Value key inside the filter object.
  static const String _valueKey = 'value';

  // ── JSON / Map form ───────────────────────────────────────────────────────

  /// Returns a [Map] suitable for use as query params or a request body filter.
  ///
  /// Example output:
  /// ```json
  /// {
  ///   "updated_at": {
  ///     "strategy": "greater_than_or_equal",
  ///     "value": "2024-01-15T08:30:00.000Z"
  ///   }
  /// }
  /// ```
  static Map<String, Map<String, String>> since(DateTime updatedAfter) {
    return {
      _field: {
        _strategyKey: _strategyValue,
        _valueKey: updatedAfter.toUtc().toIso8601String(),
      },
    };
  }

  // ── URL query-string form ─────────────────────────────────────────────────

  /// Appends the delta filter as URL query parameters to [buffer].
  ///
  /// Example appended fragment:
  /// `&filter[updated_at][strategy]=greater_than_or_equal&filter[updated_at][value]=2024-...`
  static void appendToUrl(StringBuffer buffer, DateTime updatedAfter) {
    final encoded = Uri.encodeQueryComponent(
      updatedAfter.toUtc().toIso8601String(),
    );
    buffer
      ..write('&filter[$_field][$_strategyKey]=$_strategyValue')
      ..write('&filter[$_field][$_valueKey]=$encoded');
  }

  /// Builds a complete URL, optionally appending a delta filter.
  ///
  /// - [since] == `null` → returns [baseUrl] unchanged (full fetch).
  /// - [since] != `null` → appends the `updated_at` filter.
  static String buildUrl(String baseUrl, {DateTime? since}) {
    if (since == null) return baseUrl;
    final buffer = StringBuffer(baseUrl);
    appendToUrl(buffer, since);
    return buffer.toString();
  }
}
