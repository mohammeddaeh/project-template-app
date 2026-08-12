import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// Downloads `/export` and `/template` — **the two endpoints in this API that
/// answer file bytes instead of `{status, message, data}`.**
///
/// ## Why this class exists at all
///
/// Every other call in this app goes through `BaseRepository.handle()` into
/// `HandleBodyResponse`, which parses the body as JSON. Pointing that at a CSV
/// produces a `FormatException`, which is caught, mapped to a `Failure`, and
/// shown to the user as "something went wrong" — **on a `200 OK` with a
/// perfectly good file attached**, with nothing in either repository's logs or
/// analyzers to say otherwise.
///
/// That is not a hypothetical. It is precisely the shape of the `data.user` /
/// `data.account` defect that kept sign-in broken for weeks with both CI
/// pipelines green (`readme/integration_audit.md`). So the byte path is a
/// separate, deliberately named class rather than a flag on the repository:
/// there is no way to reach it by accident and no way to reach the JSON path by
/// accident either.
///
/// ## What it still has to do
///
/// A **failure** on these routes *is* JSON — the server refuses (413 too many
/// rows, 422 unknown column) before writing the first byte. With
/// `ResponseType.bytes` those refusals arrive as bytes too, so [download]
/// decodes them back into a message rather than reporting "the download
/// failed", which tells the user nothing about the filter they need to narrow.
///
/// Uses the **injected, authenticated** `Dio` — the one carrying
/// `AuthInterceptor`. `FileService` in `core/platform/files/` cannot be used
/// here: it holds a plain Dio with no auth interceptors, by design, for public
/// downloads. These routes are private.
class TransferFileDownloader {
  const TransferFileDownloader(this._dio);

  final Dio _dio;

  static const String _tag = 'DATA_TRANSFER';

  /// Fetches [path] and writes it to the temporary directory as [fileName].
  ///
  /// Throws [TransferDownloadException] carrying the server's own message when
  /// the server refused.
  Future<File> download({
    required String path,
    required String fileName,
    Map<String, dynamic> query = const {},
  }) async {
    final Response<List<int>> response;
    try {
      response = await _dio.get<List<int>>(
        '${Env.baseUrl}$path',
        queryParameters: query,
        options: Options(
          responseType: ResponseType.bytes,
          // Take every status, so a refusal reaches the decoder below instead
          // of becoming a DioException whose payload nobody reads.
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      // Transport-level only — no response arrived at all.
      LogService.error('Transfer download failed: $e path=$path', tag: _tag);
      rethrow;
    }

    final status = response.statusCode ?? 0;
    final bytes = response.data ?? const <int>[];

    if (status < 200 || status >= 300) {
      throw TransferDownloadException(
        statusCode: status,
        message: _messageFromBytes(bytes),
      );
    }

    if (bytes.isEmpty) {
      throw const TransferDownloadException(
        statusCode: 200,
        message: 'The server returned an empty file',
      );
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    LogService.debug(
      'Transfer download ok: $fileName (${bytes.length} bytes)',
      tag: _tag,
    );
    return file;
  }

  /// Pulls the server's message out of an error body that arrived as bytes.
  ///
  /// Falls back rather than throwing: a refusal we cannot decode must still
  /// surface *as a refusal*, not as a second failure inside the error handler.
  String? _messageFromBytes(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is Map<String, dynamic>) {
        final message = json['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
      // Not JSON. Nothing to report beyond the status code.
    }
    return null;
  }
}

/// A refusal that arrived on a bytes-typed request.
///
/// Carries [statusCode] so `DataTransferRepositoryImpl` can map it onto the
/// project's ordinary `Failure` types, and [message] so a 413 says "42 000 rows
/// — the limit is 50 000" rather than "download failed".
class TransferDownloadException implements Exception {
  const TransferDownloadException({required this.statusCode, this.message});

  final int statusCode;
  final String? message;

  @override
  String toString() => 'TransferDownloadException($statusCode): $message';
}
