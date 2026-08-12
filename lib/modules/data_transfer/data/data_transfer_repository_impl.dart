import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/errors/failure_mapper_registry.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/modules/data_transfer/data/data_transfer_api_service.dart';
import 'package:app_template/modules/data_transfer/data/models/import_report_model.dart';
import 'package:app_template/modules/data_transfer/data/models/transfer_resource_model.dart';
import 'package:app_template/modules/data_transfer/data/transfer_file_downloader.dart';
import 'package:app_template/modules/data_transfer/domain/data_transfer_repository.dart';
import 'package:app_template/modules/data_transfer/domain/import_report.dart';
import 'package:app_template/modules/data_transfer/domain/transfer_resource.dart';

/// Two paths in one class, on purpose.
///
/// [resources], [validateImport] and [commitImport] go through
/// `handle()` → `HandleBodyResponse` like everything else in this app.
/// [export] and [template] go through [TransferFileDownloader] instead,
/// because their success is bytes and the envelope parser would report an
/// error over a valid file.
///
/// Keeping both here — rather than splitting the class — means the one comment
/// explaining the difference sits where someone adding a fifth method will read
/// it.
class DataTransferRepositoryImpl extends BaseRepository
    implements DataTransferRepository {
  DataTransferRepositoryImpl(
    this._api,
    this._downloader,
    HandleBodyResponse handler,
  ) : super(handler);

  final DataTransferApiService _api;
  final TransferFileDownloader _downloader;

  @override
  Future<Either<Failure, List<TransferResource>>> resources() =>
      handle(() async {
        final envelope = _read(await _api.resources());
        return envelope.map((data) {
          final list = (data as Map<String, dynamic>?)?['resources'];
          return (list as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(TransferResourceModel.fromJson)
              .toList();
        });
      });

  @override
  Future<Either<Failure, File>> export({
    required String resource,
    required TransferFormat format,
    List<String> columns = const [],
    Map<String, String> filters = const {},
  }) =>
      _downloadTo(
        path: ApiUrls.transferExport(resource),
        fileName: '$resource-${_stamp()}.${format.wire}',
        query: {
          'format': format.wire,
          // Omitted entirely when empty — sending `columns=` would be read as
          // "select no columns" and answered 422.
          if (columns.isNotEmpty) 'columns': columns.join(','),
          ...filters,
        },
      );

  @override
  Future<Either<Failure, File>> template({
    required String resource,
    required TransferFormat format,
  }) =>
      _downloadTo(
        path: ApiUrls.transferTemplate(resource),
        fileName: '$resource-template.${format.wire}',
        query: {'format': format.wire},
      );

  @override
  Future<Either<Failure, ImportReport>> validateImport({
    required String resource,
    required File file,
  }) =>
      handle(() async {
        final multipart = await MultipartFile.fromFile(
          file.path,
          // The **basename**, never the full path: the server decides the
          // format from this extension, and a Windows path would arrive with
          // separators in the filename.
          filename: p.basename(file.path),
        );
        final envelope = _read(await _api.validateImport(resource, multipart));
        return envelope.map(
          (data) => ImportReportModel.fromJson(data as Map<String, dynamic>),
        );
      });

  @override
  Future<Either<Failure, ImportResult>> commitImport({
    required String resource,
    required String token,
  }) =>
      handle(() async {
        final envelope =
            _read(await _api.commitImport(resource, {'token': token}));
        return envelope.map(
          (data) => ImportReportModel.resultFromJson(data as Map<String, dynamic>),
        );
      });

  // ── The bytes path ─────────────────────────────────────────────────────────

  /// Wraps [TransferFileDownloader] into the same `Either` the rest of the
  /// repository returns, so a caller cannot tell — and does not need to — which
  /// of the two transports ran.
  Future<Either<Failure, File>> _downloadTo({
    required String path,
    required String fileName,
    required Map<String, dynamic> query,
  }) async {
    try {
      return Right(
        await _downloader.download(path: path, fileName: fileName, query: query),
      );
    } on TransferDownloadException catch (e) {
      // The server refused, and said why. Carrying `serverMessage` through is
      // the whole reason the downloader decodes the error body: a 413 has to
      // reach the user as "42 000 rows — narrow the filter", not as a generic
      // failure they cannot act on.
      return Left(
        BusinessFailure(statusCode: e.statusCode, serverMessage: e.message),
      );
    } catch (e) {
      // Transport, storage, permissions. Mapped through the same registry as
      // every other failure so the UI branches on one closed set of types.
      return Left(FailureMapperRegistry.map(e, source: 'DATA_TRANSFER'));
    }
  }

  // ── Shared envelope reader ────────────────────────────────────────────────

  /// Unwraps `{status, message, data}` by hand.
  ///
  /// Not `ApiResponse.fromJson`, for the reason every datasource in this
  /// project avoids it: the API sends `status` as a **bool**, and `fromJson`
  /// casts it to `String` and throws — surfacing as "something went wrong" on a
  /// request that succeeded.
  Either<Failure, dynamic> _read(dynamic response) {
    final json = response.data as Map<String, dynamic>;
    final ok = json['status'] as bool? ?? false;
    final message = json['message'] as String? ?? '';

    if (!ok) {
      return Left(
        BusinessFailure(
          statusCode: json['code'] as int? ?? 400,
          serverMessage: message.isNotEmpty ? message : null,
        ),
      );
    }
    return Right(json['data']);
  }

  /// `2026-08-12` — dates the downloaded file so repeated exports do not
  /// overwrite one another in the temp directory.
  String _stamp() => DateTime.now().toIso8601String().substring(0, 10);
}
