import 'use_case_params.dart';

/// The single entry point of a unit of business logic.
///
/// A use case wraps exactly one repository call, takes a [UseCaseParams]
/// subclass, and returns `Either<Failure, Result>`. That is the whole contract
/// — anything more belongs in the repository or the cubit.
///
/// ## Why there is no `cancel()` here
///
/// This class used to carry a cancellation API: a `BaseCancelToken` field,
/// `resetCancelToken`, and a `cancel()` that every paginated cubit was told to
/// call from `close()`. It was **inert for the whole life of the template**:
/// `resetCancelToken` had not one call site in `lib/`, so the token was always
/// `null` and every `cancel()` was a no-op. Deleted rather than fixed, for two
/// reasons.
///
/// First, it was documented as the guard against
/// `Bad state: Cannot emit new states after calling close` — so a real crash
/// had a written mitigation that did nothing, which is worse than having none:
/// nobody looks for a second cause once the first is "handled".
///
/// Second, even a *working* version would not have been enough. A response can
/// arrive between "parse the body" and "close the cubit" no matter how promptly
/// it is cancelled. The guard has to be at the `emit`, and it is:
/// [SafeCubit] (`foundation/domain/safe_cubit.dart`), which is unconditional
/// and covers every cubit rather than the ones whose author remembered.
///
/// A project that genuinely needs to abort in-flight requests passes Dio's own
/// `CancelToken` through `Options` at the call site, where it actually reaches
/// the request. [CancelledFailure] already maps that outcome.
abstract class BaseUseCase<Result, Params extends UseCaseParams> {
  Future<Result> call(Params params);
}
