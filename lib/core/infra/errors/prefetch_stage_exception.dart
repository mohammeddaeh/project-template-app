/// Thrown during the application bootstrap / prefetch stage when a required
/// resource fails to load and the app cannot proceed.
///
/// Not retried automatically — the UI should offer a manual reload action.
class PrefetchStageException implements Exception {
  const PrefetchStageException(
    this.message, {
    this.cause,
    this.stageLabel,
  });

  final String message;
  final Object? cause;

  /// Label identifying which bootstrap stage failed (e.g. 'config', 'profile').
  final String? stageLabel;

  @override
  String toString() => message;
}
