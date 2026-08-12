part of 'export_cubit.dart';

/// Hand-written rather than `@freezed`, matching `ActiveDevicesState` and for
/// the same documented reason: `lib/modules/` ships disabled by default and
/// must not force a code-generation step on a project that never enables it.
/// States in `lib/Features/` stay freezed.
sealed class ExportState {
  const ExportState();
}

class ExportInitial extends ExportState {
  const ExportInitial();
}

class ExportLoading extends ExportState {
  const ExportLoading();
}

/// The form. Everything the screen draws comes from [resource] — this module
/// has no hardcoded knowledge of any feature's columns.
class ExportReady extends ExportState {
  const ExportReady({
    required this.resource,
    required this.selectedColumns,
    required this.format,
    required this.filters,
  });

  final TransferResource resource;
  final Set<String> selectedColumns;
  final TransferFormat format;

  /// The resource's own query parameters — `q` for notes. Sent verbatim.
  final Map<String, String> filters;

  ExportReady copyWith({
    Set<String>? selectedColumns,
    TransferFormat? format,
    Map<String, String>? filters,
  }) =>
      ExportReady(
        resource: resource,
        selectedColumns: selectedColumns ?? this.selectedColumns,
        format: format ?? this.format,
        filters: filters ?? this.filters,
      );
}

/// Downloading. Carries [ready] so the form stays on screen behind the spinner
/// rather than blanking — none of the user's choices changed.
class ExportRunning extends ExportState {
  const ExportRunning({required this.ready});

  final ExportReady ready;
}

class ExportDone extends ExportState {
  const ExportDone({required this.ready, required this.file});

  final ExportReady ready;
  final File file;
}

/// A refusal.
///
/// [message] is already translated — `FailureUiMapper` ran in the cubit.
/// [code] covers the two problems that are not failures at all: the server
/// does not offer this resource, or offers no format this build can write.
class ExportFailed extends ExportState {
  const ExportFailed({this.message, this.code});

  final String? message;
  final String? code;
}
