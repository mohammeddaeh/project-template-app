import 'package:app_template/modules/access_control/domain/ability_set.dart';
import 'package:app_template/modules/access_control/domain/permission_catalog.dart';
import 'package:app_template/modules/access_control/domain/role.dart';

/// Wire shapes for `/api/v1/authz/*`, mirrored key for key against
/// `backend_template/src/core/authz/dtos/authz.dto.ts` and
/// `catalog.ts`.
///
/// **Verified by `test/wire_contract_test.dart` against fixtures byte-identical
/// to the server's own tests.** That matters more here than almost anywhere
/// else: a renamed key in a list payload produces an empty screen somebody
/// notices in a minute, while a renamed key in *this* payload produces an
/// ability set that parses to empty — and an empty ability set is
/// indistinguishable, in the app and in the code, from an account that is
/// genuinely allowed nothing.
///
/// One file rather than four, deliberately: these shapes are read together,
/// changed together, and none of them is more than a constructor.

LocalizedLabel _label(Object? raw) {
  final map = raw as Map<String, dynamic>? ?? const {};
  return LocalizedLabel(
    ar: map['ar'] as String? ?? '',
    en: map['en'] as String? ?? '',
  );
}

List<String> _stringList(Object? raw) =>
    (raw as List<dynamic>? ?? const []).whereType<String>().toList();

/// `GET /authz/me` → `data`.
AbilitySet abilitySetFromJson(Map<String, dynamic> json) {
  final declared = json['declared_keys'];
  return AbilitySet(
    permissions: _stringList(json['permissions']).toSet(),
    isSuperAdmin: json['is_super_admin'] == true,
    version: (json['version'] as num?)?.toInt() ?? 0,
    // Absent defaults to **true** — enforced. A payload missing this field is a
    // server older than the flag, and the safe reading of "I don't know" for a
    // client that has already decided to gate its UI is the strict one.
    enforced: json['enabled'] == null ? true : json['enabled'] == true,
    // Debug-only, and absent on every production response.
    declaredKeys: declared == null ? null : _stringList(declared).toSet(),
  );
}

/// Reverse of [abilitySetFromJson] — for the local cache that spares the user a
/// frame of missing controls at startup. Never sent to the server.
Map<String, dynamic> abilitySetToJson(AbilitySet set) => {
  'permissions': set.permissions.toList(),
  'is_super_admin': set.isSuperAdmin,
  'version': set.version,
  'enabled': set.enforced,
};

/// `GET /authz/catalog` → `data`.
PermissionCatalog catalogFromJson(Map<String, dynamic> json) => PermissionCatalog(
  enforced: json['enabled'] == true,
  groups: (json['groups'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(_groupFromJson)
      .toList(),
);

PermissionGroup _groupFromJson(Map<String, dynamic> json) => PermissionGroup(
  resource: json['resource'] as String? ?? '',
  label: _label(json['label']),
  labelInferred: json['label_inferred'] == true,
  permissions: (json['permissions'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(_permissionFromJson)
      .toList(),
);

PermissionDescriptor _permissionFromJson(Map<String, dynamic> json) =>
    PermissionDescriptor(
      key: json['key'] as String? ?? '',
      action: json['action'] as String? ?? '',
      label: _label(json['label']),
      labelInferred: json['label_inferred'] == true,
      implies: _stringList(json['implies']),
      synthetic: json['synthetic'] == true,
    );

Role roleFromJson(Map<String, dynamic> json) => Role(
  id: (json['id'] as num?)?.toInt() ?? 0,
  key: json['key'] as String? ?? '',
  name: _label(json['name']),
  isSystem: json['is_system'] == true,
  // Absent defaults to active: a server that stops sending the field must not
  // make every role render as deactivated.
  isActive: json['is_active'] == null ? true : json['is_active'] == true,
  permissions: _stringList(json['permissions']),
  stalePermissions: _stringList(json['stale_permissions']),
  usersCount: (json['users_count'] as num?)?.toInt() ?? 0,
);

UserAccess userAccessFromJson(Map<String, dynamic> json) => UserAccess(
  userId: (json['user_id'] as num?)?.toInt() ?? 0,
  roles: (json['roles'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(roleFromJson)
      .toList(),
  overrides: (json['overrides'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(_overrideFromJson)
      .whereType<PermissionOverride>()
      .toList(),
  effectivePermissions: _stringList(json['effective_permissions']).toSet(),
  isSuperAdmin: json['is_super_admin'] == true,
);

/// Returns null for an effect this client does not know — a new value added
/// server-side is dropped rather than guessed at. Guessing here would mean
/// silently reading an unfamiliar effect as `allow`.
PermissionOverride? _overrideFromJson(Map<String, dynamic> json) {
  final effect = OverrideEffect.fromWire(json['effect'] as String?);
  if (effect == null) return null;
  return PermissionOverride(
    key: json['key'] as String? ?? '',
    effect: effect,
    note: json['note'] as String?,
  );
}

Map<String, dynamic> overrideToJson(PermissionOverride override) => {
  'key': override.key,
  'effect': override.effect.wire,
  if (override.note != null) 'note': override.note,
};
