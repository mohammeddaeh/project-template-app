import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/modules/multi_device/data/device_session_api_service.dart';
import 'package:app_template/modules/multi_device/data/models/device_session_model.dart';
import 'package:app_template/modules/multi_device/domain/device_session.dart';
import 'package:app_template/modules/multi_device/domain/device_session_repository.dart';
// DeviceNotFoundFailure and NotPrimaryDeviceFailure are defined in core failure.dart

class DeviceSessionRepositoryImpl extends BaseRepository
    implements DeviceSessionRepository {
  DeviceSessionRepositoryImpl(
    this._apiService,
    HandleBodyResponse handler,
  ) : super(handler);

  final DeviceSessionApiService _apiService;

  @override
  Future<Either<Failure, List<DeviceSession>>> getActiveSessions() =>
      handle(() async {
        final response = await _apiService.getDevices();
        final raw = response.data as Map<String, dynamic>;
        final list = (raw['devices'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(DeviceSessionModel.fromJson)
            .map((m) => m.toDomain())
            .toList();
        return Right(list);
      });

  @override
  Future<Either<Failure, void>> revokeSession(String deviceSessionId) =>
      handle(() async {
        final response = await _apiService.revokeDevice(deviceSessionId);
        final raw = response.data as Map<String, dynamic>?;

        final code = raw?['code'] as String?;
        if (code == 'DEVICE_NOT_FOUND') {
          return const Left(DeviceNotFoundFailure());
        }
        if (code == 'NOT_PRIMARY') {
          return const Left(NotPrimaryDeviceFailure());
        }
        return const Right(null);
      });

  @override
  Future<Either<Failure, void>> revokeAllExceptCurrent() =>
      handle(() async {
        await _apiService.revokeAllExceptCurrent();
        return const Right(null);
      });

  @override
  Future<Either<Failure, void>> logout() =>
      handle(() async {
        await _apiService.logout();
        return const Right(null);
      });
}
