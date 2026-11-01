import 'package:kit_contracts/kit_contracts.dart';

import 'app_permission.dart';
import 'permissions_service.dart';

/// What a screen does next with a device kit's capability.
enum KitReadiness {
  ready,

  /// The user said no this time — asking again later is fine.
  denied,

  /// The user said no for good; only the system settings can change it.
  blocked,

  /// The device cannot do it at all.
  unsupported,
}

AppPermission appPermissionOf(KitPermission permission) => switch (permission) {
  KitPermission.microphone => AppPermission.microphone,
  KitPermission.speechRecognition => AppPermission.speechRecognition,
  KitPermission.camera => AppPermission.camera,
};

/// Asks [check] whether the capability can run, requests what it lacks through
/// [permissions] — once, all together — and asks again.
///
/// The kit never prompts by itself: every permission reaches the user through
/// [PermissionsService], whichever kit needs it.
Future<KitReadiness> ensureKitReady(
  Future<KitAvailability> Function() check,
  PermissionsService permissions,
) async {
  final first = await check();
  switch (first) {
    case KitReady():
      return KitReadiness.ready;
    case KitUnsupported():
      return KitReadiness.unsupported;
    case KitNeedsPermission(permissions: final needed):
      final results = await permissions.requestMany([
        for (final p in needed.toSet()) appPermissionOf(p),
      ]);
      if (results.values.any((s) => s.needsSettings)) {
        return KitReadiness.blocked;
      }
      if (results.values.any((s) => !s.isGranted)) return KitReadiness.denied;
      return switch (await check()) {
        KitReady() => KitReadiness.ready,
        KitNeedsPermission() => KitReadiness.denied,
        KitUnsupported() => KitReadiness.unsupported,
      };
  }
}
