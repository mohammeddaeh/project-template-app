import 'package:get_it/get_it.dart';

import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

import 'integration/data_transfer_bootstrap.dart';

export 'domain/data_transfer_repository.dart' show DataTransferRepository;
export 'domain/import_report.dart'
    show ImportReport, ImportRowError, ImportResult;
export 'domain/transfer_resource.dart'
    show TransferResource, TransferColumn, TransferColumnType, TransferFormat;
export 'presentation/widgets/data_transfer_sheet.dart' show DataTransferSheet;

/// Entry point for the generic import/export module.
///
/// ## What it gives you
///
/// One line, anywhere, for any resource the backend declares:
///
/// ```dart
/// DataTransferSheet.show(context, resource: 'notes');
/// ```
///
/// No per-feature Dart. The sheet fetches
/// `GET /api/v1/data-transfer/resources`, and builds its column picker, format
/// choice, filters, import template and error table from that descriptor. A
/// backend that starts exporting invoices tomorrow gets a working invoices
/// screen from a build shipped today.
///
/// ## Activation
/// 1. Set `AppFeatures.dataTransfer = true` in `app_features.dart`.
/// 2. Nothing else — `ModulesBootstrap.initializeAll()` already calls this.
///
/// ## Deactivation
/// Set the flag to `false`. [initialize] returns immediately, nothing is
/// registered, and `DataTransferSheet.show` refuses rather than opening a
/// screen whose dependencies are absent — so the entry point can never appear
/// without the module behind it.
abstract final class DataTransferPlugin {
  static bool _initialized = false;

  static const String _tag = 'DATA_TRANSFER';

  static Future<void> initialize(GetIt di) async {
    if (_initialized) return;
    if (!AppFeatures.dataTransfer) {
      LogService.debug(
        'DataTransferPlugin disabled (AppFeatures.dataTransfer=false).',
        tag: _tag,
      );
      return;
    }

    LogService.debug('DataTransferPlugin initializing...', tag: _tag);
    await registerDataTransfer(di);

    _initialized = true;
    LogService.debug('DataTransferPlugin ready.', tag: _tag);
  }

  static void reset() => _initialized = false;
}
