import 'dart:developer' as developer;

/// No exception crosses the kit's boundary, and none disappears either: the
/// app's log service is out of reach here, so the platform log carries it.
void kitLog(Object error, StackTrace stack) => developer.log(
  'kit_system',
  name: 'kit_system',
  error: error,
  stackTrace: stack,
);
