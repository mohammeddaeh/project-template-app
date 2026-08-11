part of 'active_devices_cubit.dart';

/// Hand-written rather than `@freezed` — a deliberate, documented exception to
/// the project rule.
///
/// `lib/modules/` is optional infrastructure that ships disabled by default, so
/// it must not force a code-generation step on a project that never turns it
/// on. Every other state in `lib/Features/` stays freezed.
sealed class ActiveDevicesState {
  const ActiveDevicesState();
}

class ActiveDevicesInitial extends ActiveDevicesState {
  const ActiveDevicesInitial();
}

class ActiveDevicesLoading extends ActiveDevicesState {
  const ActiveDevicesLoading();
}

class ActiveDevicesLoaded extends ActiveDevicesState {
  const ActiveDevicesLoaded({required this.sessions});

  final List<DeviceSession> sessions;

  /// How many sessions "sign out my other devices" would actually end.
  ///
  /// Computed here so the button can state the number and disable itself at
  /// zero — an action that is offered but does nothing reads as broken.
  int get otherCount => sessions.where((s) => !s.isCurrent).length;
}

/// One row is being revoked. Carries the id so only that row shows a spinner
/// instead of the whole list blanking — the rest of the list is still true.
class ActiveDevicesRevoking extends ActiveDevicesState {
  const ActiveDevicesRevoking({required this.sessions, required this.id});

  final List<DeviceSession> sessions;
  final int id;
}

class ActiveDevicesError extends ActiveDevicesState {
  const ActiveDevicesError({required this.message});

  final String message;
}
