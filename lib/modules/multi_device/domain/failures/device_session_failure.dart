// Re-export core failures used by this module for convenience.
// The actual definitions live in failure.dart (sealed class requires same library).
export 'package:app_template/core/foundation/errors/failure.dart'
    show DeviceNotFoundFailure, NotPrimaryDeviceFailure;
