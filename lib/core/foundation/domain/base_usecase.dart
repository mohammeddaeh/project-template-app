import 'use_case_params.dart';

/// The single entry point of a unit of business logic.
///
/// A use case wraps exactly one repository call, takes a [UseCaseParams]
/// subclass, and returns `Either<Failure, Result>`. That is the whole contract
/// — anything more belongs in the repository or the cubit.
///
/// ## Why there is no `cancel()` here
///
/// Cancelling is not the guard against
/// `Bad state: Cannot emit new states after calling close`: a response can
/// arrive between "parse the body" and "close the cubit" however promptly it is
/// cancelled. The guard is at the `emit` — [SafeCubit]
/// (`foundation/domain/safe_cubit.dart`), unconditional for every cubit.
///
/// A project that genuinely needs to abort in-flight requests passes Dio's own
/// `CancelToken` through `Options` at the call site, where it actually reaches
/// the request. [CancelledFailure] already maps that outcome.
abstract class BaseUseCase<Result, Params extends UseCaseParams> {
  Future<Result> call(Params params);
}
