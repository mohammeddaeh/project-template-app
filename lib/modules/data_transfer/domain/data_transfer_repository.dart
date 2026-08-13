import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:app_template/core/foundation/errors/failure.dart';

import 'import_report.dart';
import 'transfer_resource.dart';

/// The module's whole boundary. Four calls, no per-feature methods — a resource
/// is a `String` argument, which is the reason this module never grows when a
/// feature becomes transferable.
abstract class DataTransferRepository {
  /// What can be transferred. Everything the UI renders comes from here.
  Future<Either<Failure, List<TransferResource>>> resources();

  /// Downloads an export to a file on disk and returns it.
  ///
  /// **Not routed through the JSON envelope** — see
  /// `data/transfer_file_downloader.dart` for why that distinction is load
  /// bearing rather than an implementation detail.
  ///
  /// [columns] empty = every column. [filters] are the resource's own query
  /// parameters, taken verbatim from its descriptor.
  Future<Either<Failure, File>> export({
    required String resource,
    required TransferFormat format,
    List<String> columns = const [],
    Map<String, String> filters = const {},
  });

  /// Downloads an empty file with the importer's expected header.
  Future<Either<Failure, File>> template({
    required String resource,
    required TransferFormat format,
  });

  /// Phase one — uploads and validates. **Writes nothing.**
  Future<Either<Failure, ImportReport>> validateImport({
    required String resource,
    required File file,
  });

  /// Phase one again, on rows the user corrected in the app's grid.
  ///
  /// The same endpoint and the same rules as [validateImport] — the server runs
  /// one code path for both. That matters: a separate "re-check" route would be
  /// a second copy of the validation, and the copies would drift until the grid
  /// accepted rows the upload refused.
  ///
  /// Each call issues a **fresh token** and invalidates nothing else; the
  /// previous one simply expires unused.
  Future<Either<Failure, ImportReport>> revalidateRows({
    required String resource,
    required List<String> columns,
    required List<Map<String, String>> rows,
  });

  /// Phase two — spends [token] and writes, all rows or none.
  ///
  /// The token is single-use: a retry after a timeout must re-upload rather
  /// than re-send this, or the retry would answer "expired" for a token that
  /// did in fact commit.
  Future<Either<Failure, ImportResult>> commitImport({
    required String resource,
    required String token,
  });
}
