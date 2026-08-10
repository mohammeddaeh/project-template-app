/// The three things a write can come back as.
enum MutationKind {
  saved,
  failed,

  /// The server refused with something the reader is allowed to overrule —
  /// a question, not a verdict. Kept apart from [failed] so a screen can offer
  /// "do it anyway" instead of showing a refusal.
  needsConfirmation,
}

/// What came of a mutation, **and what to tell the reader**.
///
/// ## Why the message is returned and never emitted
///
/// The natural-looking alternative is a `saveFailed` state (or a `saveFailed`
/// flag) that a `BlocListener` watches. Both shipped in a real project built on
/// this template, and both broke — differently, and neither loudly:
///
/// - **As a state**: every mutation on the screen opened with
///   `if (state is! ...Loaded) return`, so the first failure parked the cubit
///   somewhere the next press bounced off. All five writes on that screen went
///   dead until it reloaded, silently. And a repeat of the same failure builds
///   an *equal* state, which Cubit drops — so the message showed once however
///   often you pressed.
/// - **As a flag** (`bool saveFailed` on the state): it was sticky. Starting the
///   next save carried the old `true` forward, so the error toast fired again
///   the instant you retried, before the request had even left.
///
/// A one-shot message is not state. It has no duration, and both designs gave
/// it one. The mutation hands it back; the caller says it and forgets it.
///
/// ```dart
/// final result = await cubit.save(...);
/// if (result.isSaved) {
///   context.feedback.success(LocaleKeys.saved.tr());
/// } else if (result.message != null) {
///   context.feedback.error(result.message!);
/// }
/// ```
///
/// The inverse rule matters too: a value that *does* have a duration belongs in
/// state. A "saving…" spinner, a hold-for-950ms success tick — those have a
/// beginning and an end, and a controller can own them. Ask which kind you have
/// before choosing where to put it.
class MutationResult {
  const MutationResult._(this.kind, this.message);

  const MutationResult.saved() : this._(MutationKind.saved, null);

  const MutationResult.failed(String? message)
    : this._(MutationKind.failed, message);

  const MutationResult.needsConfirmation()
    : this._(MutationKind.needsConfirmation, null);

  final MutationKind kind;

  /// Null when there is nothing to say — a success, or a failure the global
  /// handler already owns (an expired session navigates to login by itself, and
  /// a toast on the way out is noise over a screen that is already leaving).
  final String? message;

  bool get isSaved => kind == MutationKind.saved;
}
