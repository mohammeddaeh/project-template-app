import 'package:dartz/dartz.dart';

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/modules/access_control/data/access_control_api_service.dart';
import 'package:app_template/modules/access_control/data/models/access_control_models.dart';
import 'package:app_template/modules/access_control/domain/ability_set.dart';
import 'package:app_template/modules/access_control/domain/access_control_repository.dart';
import 'package:app_template/modules/access_control/domain/permission_catalog.dart';
import 'package:app_template/modules/access_control/domain/role.dart';

class AccessControlRepositoryImpl extends BaseRepository
    implements AccessControlRepository {
  AccessControlRepositoryImpl(this._api, HandleBodyResponse handler)
    : super(handler);

  final AccessControlApiService _api;

  @override
  Future<Either<Failure, AbilitySet>> myAbilities({
    bool includeDeclared = false,
  }) => handle(() async {
    final envelope = _read(
      // Omitted rather than sent as `false`: a production build should not
      // announce a debug-only capability on every session.
      await _api.myAbilities(includeDeclared: includeDeclared ? true : null),
    );
    return envelope.map(
      (data) => abilitySetFromJson(data as Map<String, dynamic>),
    );
  });

  @override
  Future<Either<Failure, PermissionCatalog>> catalog() => handle(() async {
    final envelope = _read(await _api.catalog());
    return envelope.map(
      (data) => catalogFromJson(data as Map<String, dynamic>),
    );
  });

  @override
  Future<Either<Failure, List<Role>>> roles({int page = 1, int limit = 50}) =>
      handle(() async {
        final envelope = _read(await _api.roles(page: page, limit: limit));
        return envelope.map((data) {
          final items = (data as Map<String, dynamic>?)?['items'];
          return (items as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(roleFromJson)
              .toList();
        });
      });

  @override
  Future<Either<Failure, Role>> createRole({
    required String key,
    required String nameAr,
    required String nameEn,
  }) => handle(() async {
    final envelope = _read(
      await _api.createRole({'key': key, 'name_ar': nameAr, 'name_en': nameEn}),
    );
    return envelope.map((data) => roleFromJson(data as Map<String, dynamic>));
  });

  @override
  Future<Either<Failure, Role>> renameRole({
    required int id,
    required String nameAr,
    required String nameEn,
  }) => handle(() async {
    final envelope = _read(
      await _api.renameRole(id, {'name_ar': nameAr, 'name_en': nameEn}),
    );
    return envelope.map((data) => roleFromJson(data as Map<String, dynamic>));
  });

  @override
  Future<Either<Failure, Role>> setRolePermissions({
    required int id,
    required List<String> permissions,
  }) => handle(() async {
    final envelope = _read(
      await _api.setRolePermissions(id, {'permissions': permissions}),
    );
    return envelope.map((data) => roleFromJson(data as Map<String, dynamic>));
  });

  @override
  Future<Either<Failure, Role>> setRoleActive({
    required int id,
    required bool isActive,
  }) => handle(() async {
    final envelope = _read(
      await (isActive ? _api.activateRole(id) : _api.deactivateRole(id)),
    );
    return envelope.map((data) => roleFromJson(data as Map<String, dynamic>));
  });

  @override
  Future<Either<Failure, UserAccess>> userAccess(int userId) =>
      handle(() async {
        final envelope = _read(await _api.userAccess(userId));
        return envelope.map(
          (data) => userAccessFromJson(data as Map<String, dynamic>),
        );
      });

  @override
  Future<Either<Failure, UserAccess>> setUserRoles({
    required int userId,
    required List<int> roleIds,
  }) => handle(() async {
    final envelope = _read(
      await _api.setUserRoles(userId, {'role_ids': roleIds}),
    );
    return envelope.map(
      (data) => userAccessFromJson(data as Map<String, dynamic>),
    );
  });

  @override
  Future<Either<Failure, UserAccess>> setUserOverrides({
    required int userId,
    required List<PermissionOverride> overrides,
  }) => handle(() async {
    final envelope = _read(
      await _api.setUserOverrides(userId, {
        'overrides': overrides.map(overrideToJson).toList(),
      }),
    );
    return envelope.map(
      (data) => userAccessFromJson(data as Map<String, dynamic>),
    );
  });

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
}
