/// Answers one question that anything destructive has to ask first:
/// **is there work on this device that has not reached the server yet?**
///
/// ## Why this lives in `foundation/` and not in the sync module
///
/// The callers are the ones who destroy things — signing out, switching
/// accounts, clearing storage — and they live in `Features/` and `core/`, which
/// may not import `modules/`. The dependency has to point the other way: the
/// interface is declared here, and whatever module owns a queue implements it.
///
/// Same shape as [AuthNetworkGateway] and [TokenRefreshGateway], and for the
/// same reason.
///
/// ## The default is honest, not empty
///
/// [NoUnsyncedWorkProbe] is registered by `injection_module.dart` and answers
/// zero, because an app with no offline module genuinely has nothing pending.
/// `registerSyncCore` replaces it with an implementation backed by the real
/// queue. So a caller never has to ask whether sync is switched on — a question
/// it has no business knowing the answer to.
abstract interface class UnsyncedWorkProbe {
  /// Operations written on this device and not yet accepted by the server.
  ///
  /// `0` means the device holds nothing that would be lost. Anything above it
  /// is work that exists **only here**.
  Future<int> pendingOperations();
}

/// The answer for an app that has no offline queue: nothing is pending.
class NoUnsyncedWorkProbe implements UnsyncedWorkProbe {
  const NoUnsyncedWorkProbe();

  @override
  Future<int> pendingOperations() async => 0;
}
