part of 'import_cubit.dart';

/// Hand-written rather than `@freezed` — see the note on `ExportState`.
///
/// **The token lives only in [ImportReviewing].** That is the type system doing
/// the enforcing: there is no state from which a write can be authorised
/// without the report the user reviewed, so the two-phase promise cannot be
/// bypassed by a stray call from a widget.
sealed class ImportState {
  const ImportState();

  /// The resource once it is known, so error screens can still name what the
  /// user was importing. `null` only before the descriptor arrives.
  TransferResource? get resource => null;
}

class ImportInitial extends ImportState {
  const ImportInitial();
}

class ImportLoading extends ImportState {
  const ImportLoading();
}

/// Waiting for a file. The template can be downloaded from here.
class ImportReady extends ImportState {
  const ImportReady({required this.resource});

  @override
  final TransferResource resource;
}

class ImportTemplateLoading extends ImportState {
  const ImportTemplateLoading({required this.resource});

  @override
  final TransferResource resource;
}

class ImportTemplateReady extends ImportState {
  const ImportTemplateReady({required this.resource, required this.file});

  @override
  final TransferResource resource;
  final File file;
}

class ImportValidating extends ImportState {
  const ImportValidating({required this.resource, required this.file});

  @override
  final TransferResource resource;
  final File file;
}

/// Phase one is done and **nothing has been written**. The user decides here.
class ImportReviewing extends ImportState {
  const ImportReviewing({
    required this.resource,
    required this.file,
    required this.report,
  });

  @override
  final TransferResource resource;
  final File file;
  final ImportReport report;
}

class ImportCommitting extends ImportState {
  const ImportCommitting({required this.resource, required this.report});

  @override
  final TransferResource resource;
  final ImportReport report;
}

class ImportCommitted extends ImportState {
  const ImportCommitted({required this.resource, required this.result});

  @override
  final TransferResource resource;
  final ImportResult result;
}

class ImportFailed extends ImportState {
  const ImportFailed({this.message, this.code, this.resource});

  /// Already translated — `FailureUiMapper` ran in the cubit.
  final String? message;

  /// For the refusals that are not failures: `unknown_resource`,
  /// `import_unsupported`.
  final String? code;

  @override
  final TransferResource? resource;
}
