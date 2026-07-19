import 'package:app_template/core/foundation/errors/failure.dart';

/// Contract for all failure mappers.
///
/// Every mapper converts a raw exception type into a typed [Failure].
/// Implementations must be pure and side-effect free.
abstract interface class FailureMapper {
  Failure map(Object error);
}
