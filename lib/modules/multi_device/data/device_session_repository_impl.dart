import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/modules/multi_device/data/device_session_api_service.dart';
import 'package:app_template/modules/multi_device/data/models/device_session_model.dart';
import 'package:app_template/modules/multi_device/domain/device_session.dart';
import 'package:app_template/modules/multi_device/domain/device_session_repository.dart';

class DeviceSessionRepositoryImpl extends BaseRepository
    implements DeviceSessionRepository {
  DeviceSessionRepositoryImpl(this._apiService, HandleBodyResponse handler)
      : super(handler);

  final DeviceSessionApiService _apiService;

  @override
  Future<Either<Failure, List<DeviceSession>>> getActiveSessions() =>
      handle(() async {
        final envelope = _read(await _apiService.getSessions());
        return envelope.map(
          (data) => (data as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()
              .map(DeviceSessionModel.fromJson)
              .map((m) => m.toDomain())
              .toList(),
        );
      });

  @override
  Future<Either<Failure, void>> revokeSession(int id) => handle(() async {
        final envelope = _read(await _apiService.revokeSession(id));
        return envelope.map((_) {});
      });

  @override
  Future<Either<Failure, int>> revokeOthers() => handle(() async {
        final envelope = _read(await _apiService.revokeOthers());
        return envelope.map((data) {
          final count = (data as Map<String, dynamic>?)?['sessions_revoked'];
          return count is int ? count : 0;
        });
      });

  /// Unwraps the shared envelope into either its `data` payload or a Failure.
  ///
  /// Read by hand rather than through `ApiResponse.fromJson` for the same
  /// reason as every other datasource in this project: the API sends `status`
  /// as a **bool**, and `fromJson` casts it to `String` and throws
  /// `ParseFailure` — surfacing as "something went wrong" on a request that
  /// actually succeeded.
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
}
