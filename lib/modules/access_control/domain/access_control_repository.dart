import 'package:dartz/dartz.dart';

import 'package:app_template/core/foundation/errors/failure.dart';

import 'ability_set.dart';
import 'permission_catalog.dart';
import 'role.dart';

/// The module's whole boundary.
///
/// No method names a feature, a resource or a permission — every key is a
/// `String` argument and every screen is drawn from [catalog]. That is the
/// reason this interface does not grow when an application does.
abstract class AccessControlRepository {
  /// The signed-in account's own resolved permissions. Every account may call
  /// it; needing a permission to discover your permissions is a circle with no
  /// entry point.
  ///
  /// [includeDeclared] asks the server to list every key it declares — sent
  /// only by debug builds, so the module can shout about a key no server knows.
  Future<Either<Failure, AbilitySet>> myAbilities({bool includeDeclared = false});

  /// Every permission the server declares, grouped by resource. Requires
  /// `roles.view`; the roles screen is built entirely from it.
  Future<Either<Failure, PermissionCatalog>> catalog();

  Future<Either<Failure, List<Role>>> roles({int page = 1, int limit = 50});

  Future<Either<Failure, Role>> createRole({
    required String key,
    required String nameAr,
    required String nameEn,
  });

  Future<Either<Failure, Role>> renameRole({
    required int id,
    required String nameAr,
    required String nameEn,
  });

  /// Replaces the role's permission set wholesale — the screen knows the final
  /// state and nothing else, which is exactly what a PUT expresses.
  Future<Either<Failure, Role>> setRolePermissions({
    required int id,
    required List<String> permissions,
  });

  Future<Either<Failure, Role>> setRoleActive({
    required int id,
    required bool isActive,
  });

  Future<Either<Failure, UserAccess>> userAccess(int userId);

  Future<Either<Failure, UserAccess>> setUserRoles({
    required int userId,
    required List<int> roleIds,
  });

  Future<Either<Failure, UserAccess>> setUserOverrides({
    required int userId,
    required List<PermissionOverride> overrides,
  });
}
