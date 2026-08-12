import 'dart:io';

import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/modules/data_transfer/domain/data_transfer_repository.dart';
import 'package:app_template/modules/data_transfer/domain/import_report.dart';
import 'package:app_template/modules/data_transfer/domain/transfer_resource.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';

part 'import_state.dart';

/// Drives the two-phase import for **any** resource.
///
/// The state machine is the contract, not a UI convenience:
///
/// ```
/// ImportReady ──pick+validate──▶ ImportReviewing ──confirm──▶ ImportCommitted
///      ▲                              │
///      └──────── startOver ───────────┘
/// ```
///
/// There is deliberately **no** path from [ImportReady] straight to a commit.
/// The token that authorises a write exists only inside [ImportReviewing], so
/// "upload and write in one step" is not something a caller can express — the
/// review the user gave consent on cannot be skipped by a stray call.
class ImportCubit extends SafeCubit<ImportState> {
  ImportCubit(this._repository) : super(const ImportInitial());

  final DataTransferRepository _repository;

  Future<void> load(String resourceName) async {
    emit(const ImportLoading());

    final result = await _repository.resources();
    result.fold(_emitFailure, (resources) {
      final resource =
          resources.where((r) => r.name == resourceName).firstOrNull;

      if (resource == null) {
        emit(const ImportFailed(code: 'unknown_resource'));
        return;
      }
      if (!resource.supportsImport) {
        // Read from the server's own flag rather than inferred from an empty
        // format list — the two are stated separately precisely so the client
        // cannot disagree with the server about it.
        emit(const ImportFailed(code: 'import_unsupported'));
        return;
      }

      emit(ImportReady(resource: resource));
    });
  }

  /// Downloads the empty template. Does not change phase — the user is still
  /// on the same screen, about to pick a file.
  Future<void> downloadTemplate(TransferFormat format) async {
    final resource = _resource;
    if (resource == null) return;

    emit(ImportTemplateLoading(resource: resource));

    final result = await _repository.template(
      resource: resource.name,
      format: format,
    );
    result.fold(
      _emitFailure,
      (file) => emit(ImportTemplateReady(resource: resource, file: file)),
    );
  }

  /// Phase one. Uploads [file] and shows what would happen. **Writes nothing.**
  Future<void> validate(File file) async {
    final resource = _resource;
    if (resource == null) return;

    emit(ImportValidating(resource: resource, file: file));

    final result = await _repository.validateImport(
      resource: resource.name,
      file: file,
    );
    result.fold(
      _emitFailure,
      (report) => emit(
        ImportReviewing(resource: resource, file: file, report: report),
      ),
    );
  }

  /// Phase two. Only reachable from [ImportReviewing], and only when the server
  /// issued a token — it withholds one when no row is valid.
  Future<void> confirm() async {
    final current = state;
    if (current is! ImportReviewing) return;

    final token = current.report.token;
    if (token == null) return;

    emit(ImportCommitting(resource: current.resource, report: current.report));

    final result = await _repository.commitImport(
      resource: current.resource.name,
      token: token,
    );
    result.fold(
      // A failed commit leaves nothing written — the server's transaction
      // guarantees it. The token is spent either way, which is why
      // `startOver` (re-upload), not a retry of `confirm`, is the way back.
      _emitFailure,
      (outcome) => emit(
        ImportCommitted(resource: current.resource, result: outcome),
      ),
    );
  }

  /// Back to the file picker, discarding any staged token.
  void startOver() {
    final resource = _resource;
    if (resource != null) emit(ImportReady(resource: resource));
  }

  TransferResource? get _resource => switch (state) {
        ImportReady(:final resource) => resource,
        ImportTemplateLoading(:final resource) => resource,
        ImportTemplateReady(:final resource) => resource,
        ImportValidating(:final resource) => resource,
        ImportReviewing(:final resource) => resource,
        ImportCommitting(:final resource) => resource,
        ImportCommitted(:final resource) => resource,
        ImportFailed(:final resource) => resource,
        _ => null,
      };

  /// Resolves a [Failure] to displayable text here rather than in the widget —
  /// see the identical note on `ExportCubit`.
  void _emitFailure(Failure failure) {
    switch (FailureUiMapper.toAction(failure)) {
      case ShowError(:final message):
        emit(ImportFailed(message: message, resource: _resource));
      // Session expiry is routed to login by the network layer on its own.
      case NavigateToLogin():
      case Silent():
        break;
    }
  }
}
