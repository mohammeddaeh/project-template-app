import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/modules/data_transfer/data/data_transfer_api_service.dart';
import 'package:app_template/modules/data_transfer/data/data_transfer_repository_impl.dart';
import 'package:app_template/modules/data_transfer/data/transfer_file_downloader.dart';
import 'package:app_template/modules/data_transfer/domain/data_transfer_repository.dart';
import 'package:app_template/modules/data_transfer/presentation/cubits/export_cubit.dart';
import 'package:app_template/modules/data_transfer/presentation/cubits/import_cubit.dart';

/// Registers the module's dependencies. Called once from
/// [DataTransferPlugin.initialize].
///
/// Registration is manual rather than `@injectable` for the same reason as
/// every other module here: `injectable`'s generator scans all of `lib/`, so an
/// annotated module would be wired into `injection.config.dart` whether or not
/// its feature flag is on — and a module that ships disabled must cost nothing.
///
/// Every registration is guarded by `isRegistered`, so a hot restart that
/// re-runs bootstrap does not throw over an already-registered type.
Future<void> registerDataTransfer(GetIt di) async {
  if (!di.isRegistered<DataTransferApiService>()) {
    di.registerLazySingleton<DataTransferApiService>(
      () => DataTransferApiService(di<Dio>()),
    );
  }

  if (!di.isRegistered<TransferFileDownloader>()) {
    di.registerLazySingleton<TransferFileDownloader>(
      // The **injected** Dio — the one carrying AuthInterceptor. `FileService`
      // holds a separate, deliberately unauthenticated Dio for public
      // downloads, and these routes are private.
      () => TransferFileDownloader(di<Dio>()),
    );
  }

  if (!di.isRegistered<DataTransferRepository>()) {
    di.registerLazySingleton<DataTransferRepository>(
      () => DataTransferRepositoryImpl(
        di<DataTransferApiService>(),
        di<TransferFileDownloader>(),
        di<HandleBodyResponse>(),
      ),
    );
  }

  // Factories, not singletons: each screen gets its own state machine, and a
  // shared import cubit would carry a stale staging token between screens.
  if (!di.isRegistered<ExportCubit>()) {
    di.registerFactory<ExportCubit>(
      () => ExportCubit(di<DataTransferRepository>()),
    );
  }

  if (!di.isRegistered<ImportCubit>()) {
    di.registerFactory<ImportCubit>(
      () => ImportCubit(di<DataTransferRepository>()),
    );
  }
}
