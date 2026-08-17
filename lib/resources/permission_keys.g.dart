// GENERATED — do not edit by hand.
// dart run scripts/sync_permission_keys.dart
//
// المصدر: permissions.lock.json (مُلتزَم به بـgit).
// استعمله بدل النصّ الخام:
//   Can(permission: PermKeys.notesUpdate, child: ...)
//
// مفتاحٌ حُذف من الباك يختفي من هنا فيكسر البناء عند كل استعمال
// له — وهذه هي الفائدة، لا إزعاجاً.

abstract final class PermKeys {
  const PermKeys._();

  /// `notes.create`
  static const String notesCreate = 'notes.create';

  /// `notes.delete`
  static const String notesDelete = 'notes.delete';

  /// `notes.manage`
  static const String notesManage = 'notes.manage';

  /// `notes.update`
  static const String notesUpdate = 'notes.update';

  /// `notes.view`
  static const String notesView = 'notes.view';

  /// `roles.create`
  static const String rolesCreate = 'roles.create';

  /// `roles.delete`
  static const String rolesDelete = 'roles.delete';

  /// `roles.manage`
  static const String rolesManage = 'roles.manage';

  /// `roles.restore`
  static const String rolesRestore = 'roles.restore';

  /// `roles.update`
  static const String rolesUpdate = 'roles.update';

  /// `roles.view`
  static const String rolesView = 'roles.view';

  /// `user_access.manage`
  static const String userAccessManage = 'user_access.manage';

  /// `user_access.update`
  static const String userAccessUpdate = 'user_access.update';

  /// `user_access.view`
  static const String userAccessView = 'user_access.view';

  /// كل المفاتيح — لشاشة تشخيص أو فحص.
  static const List<String> all = <String>[
    'notes.create',
    'notes.delete',
    'notes.manage',
    'notes.update',
    'notes.view',
    'roles.create',
    'roles.delete',
    'roles.manage',
    'roles.restore',
    'roles.update',
    'roles.view',
    'user_access.manage',
    'user_access.update',
    'user_access.view',
  ];
}
