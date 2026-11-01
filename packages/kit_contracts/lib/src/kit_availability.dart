/// Whether a kit's capability can run on this device right now.
///
/// Every kit contract answers with this before it acts, and never throws across
/// the boundary: the app maps the answer to its own UI and `Failure`, so a
/// platform exception never reaches a screen as raw text.
sealed class KitAvailability {
  const KitAvailability();
}

/// The capability can run.
final class KitReady extends KitAvailability {
  const KitReady();
}

/// The capability needs permissions the user has not granted — all of
/// [permissions], requested together (speech on iOS needs the microphone and
/// the recogniser at once).
///
/// The kit does not ask for them: the app asks through its own permission
/// service, so a permission has one path to the user whichever kit needs it.
final class KitNeedsPermission extends KitAvailability {
  const KitNeedsPermission(this.permissions);

  final List<KitPermission> permissions;
}

/// The device or platform cannot run the capability at all.
final class KitUnsupported extends KitAvailability {
  const KitUnsupported();
}

/// The permissions a kit may need, named as the app's permission flags are.
enum KitPermission { microphone, speechRecognition, camera }
