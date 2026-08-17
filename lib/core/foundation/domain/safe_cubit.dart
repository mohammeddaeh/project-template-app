import 'package:bloc/bloc.dart';

/// A [Cubit] whose late-arriving responses cannot crash the app.
///
/// Lives in `foundation` — pure Dart, no Flutter, no UI — precisely so every
/// layer may extend it. `modules/` is forbidden from importing `presentation/`,
/// and a guard against a crash is not something a bounded module should have to
/// re-implement to stay inside the dependency rules.
///
/// Every fetch outlives its own screen sooner or later: the user taps back,
/// pops a sheet, or lets a `ListView` dispose a section while the request is
/// still on the wire. When the response lands, the cubit is already closed and
/// `emit` throws:
///
/// ```
/// StateError (Bad state: Cannot emit new states after calling close)
/// ```
///
/// That is a **real crash, not a debug assertion** — it reaches release builds,
/// and it fires on nothing worse than leaving a screen quickly.
///
/// ## Why not cancel the request instead
///
/// This template used to *teach* that it did, and it did not. `core/CLAUDE.md`
/// prescribed `close() { _useCase.cancel(); }` as **mandatory** for every
/// paginated cubit, over a `BaseUseCase` cancellation API that had no caller
/// anywhere in `lib/` — the token was always null and every one of those calls
/// was a no-op. The dead API has since been deleted (see [BaseUseCase]); this
/// paragraph stays because the lesson outlives it.
///
/// It matters more in a template than in any single app: a template propagates
/// its beliefs to every project generated from it. A protection that reads as
/// present in review and is absent at runtime ships once per project, forever.
///
/// And cancellation was never the right guard anyway. A response can land in
/// the window between "body parsed" and "cubit closed" however promptly the
/// request was aborted, so the check has to be at the `emit` — here,
/// unconditionally, rather than in each cubit whose author remembered.
///
/// ## What this deliberately does NOT do
///
/// It does not make emit-after-close *correct*, only survivable. If a cubit
/// depends on a state it emits after closing, that state is dropped silently
/// here — and it was already unreachable, because nothing is listening to a
/// closed cubit.
abstract class SafeCubit<S> extends Cubit<S> {
  SafeCubit(super.initialState);

  @override
  void emit(S state) {
    if (isClosed) return;
    super.emit(state);
  }
}
