/// The exhaustive set of UI actions that can result from a [Failure].
///
/// [FailureUiMapper.toAction] is the ONLY factory for these.
/// Consumers must handle every case via exhaustive `switch` — the compiler
/// enforces this, preventing a developer from silently ignoring error cases.
///
/// Design intent:
/// - [ShowError]       → display a toast / dialog / inline error widget.
/// - [Silent]          → swallow entirely (cancelled requests, etc.).
/// - [NavigateToLogin] → session expired; navigate to login screen.
///                       [AuthEventBus] fires at the network layer first;
///                       the cubit fires it again (deduplicated) as a safety net.
sealed class UiAction {
  const UiAction();
}

/// Display this error to the user.
final class ShowError extends UiAction {
  const ShowError({
    required this.title,
    required this.message,
    this.canRetry = false,
  });

  final String title;
  final String message;

  /// Whether the UI should offer a retry button / pull-to-refresh.
  final bool canRetry;
}

/// Swallow silently — no toast, no state change, no action.
final class Silent extends UiAction {
  const Silent();
}

/// Navigate to the login screen.
///
/// The cubit should call [AuthEventBus.instance.emit(AuthEvent.sessionExpired)]
/// to trigger navigation — the bus is deduplicated so firing it multiple times
/// is safe.
final class NavigateToLogin extends UiAction {
  const NavigateToLogin();
}
