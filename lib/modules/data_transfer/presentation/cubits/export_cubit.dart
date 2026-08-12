import 'dart:io';

import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/modules/data_transfer/domain/data_transfer_repository.dart';
import 'package:app_template/modules/data_transfer/domain/transfer_resource.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';

part 'export_state.dart';

/// Drives the export screen for **any** resource.
///
/// It never names one. The resource arrives as a string, its columns arrive in
/// the descriptor, and the selection state is `Set<String>` — which is why this
/// class does not change when a new transferable feature ships.
class ExportCubit extends SafeCubit<ExportState> {
  ExportCubit(this._repository) : super(const ExportInitial());

  final DataTransferRepository _repository;

  /// Fetches the descriptor and preselects everything.
  ///
  /// Everything, rather than nothing: the common case is "give me my data", and
  /// a screen that opens with an empty selection and a disabled button makes
  /// the user do setup work to reach the default they wanted.
  Future<void> load(String resourceName) async {
    emit(const ExportLoading());

    final result = await _repository.resources();
    result.fold(_emitFailure, (resources) {
      final resource =
          resources.where((r) => r.name == resourceName).firstOrNull;

      if (resource == null) {
        // The server does not offer this resource. Saying so beats an empty
        // screen that looks like a slow network.
        emit(const ExportFailed(code: 'unknown_resource'));
        return;
      }
      if (resource.exportFormats.isEmpty) {
        emit(const ExportFailed(code: 'no_format'));
        return;
      }

      emit(
        ExportReady(
          resource: resource,
          selectedColumns: resource.columns.map((c) => c.key).toSet(),
          format: resource.exportFormats.first,
          filters: const {},
        ),
      );
    });
  }

  void toggleColumn(String key) {
    final current = state;
    if (current is! ExportReady) return;

    final next = Set<String>.from(current.selectedColumns);
    if (!next.remove(key)) next.add(key);

    // An empty selection is refused server-side with a 422. Blocking the last
    // removal here turns that into a checkbox that will not untick, which is
    // self-explanatory, instead of an error after a round trip.
    if (next.isEmpty) return;

    emit(current.copyWith(selectedColumns: next));
  }

  void selectFormat(TransferFormat format) {
    final current = state;
    if (current is! ExportReady) return;
    emit(current.copyWith(format: format));
  }

  /// Sets or clears one of the resource's own query filters.
  void setFilter(String key, String value) {
    final current = state;
    if (current is! ExportReady) return;

    final next = Map<String, String>.from(current.filters);
    if (value.trim().isEmpty) {
      next.remove(key);
    } else {
      next[key] = value.trim();
    }
    emit(current.copyWith(filters: next));
  }

  Future<void> run() async {
    final current = state;
    if (current is! ExportReady) return;

    emit(ExportRunning(ready: current));

    final result = await _repository.export(
      resource: current.resource.name,
      format: current.format,
      // Sent in the resource's own declaration order, not selection order —
      // the server re-orders anyway, and matching it keeps the two comparable.
      columns: current.resource.columns
          .map((c) => c.key)
          .where(current.selectedColumns.contains)
          .toList(),
      filters: current.filters,
    );

    result.fold(
      _emitFailure,
      (file) => emit(ExportDone(ready: current, file: file)),
    );
  }

  /// Returns to the form after a share or a failure, keeping the selection.
  void reset() {
    final current = state;
    final ready = switch (current) {
      ExportRunning(:final ready) => ready,
      ExportDone(:final ready) => ready,
      _ => null,
    };
    if (ready != null) emit(ready);
  }

  /// Resolves a [Failure] to displayable text here rather than in the widget,
  /// matching every other cubit in this project: translation is
  /// `FailureUiMapper`'s job, and a widget that mapped failures itself would
  /// have to re-implement the session-expiry branch below.
  void _emitFailure(Failure failure) {
    switch (FailureUiMapper.toAction(failure)) {
      case ShowError(:final message):
        emit(ExportFailed(message: message));
      // Session expiry is routed to login by the network layer on its own.
      // Painting an error over a screen already being torn down is noise.
      case NavigateToLogin():
      case Silent():
        break;
    }
  }
}
