import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'package:app_template/core/foundation/contracts/account_scoped_store.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';

/// يخزّن **بصمة** رقم القفل لا الرقم نفسه — `SHA-256(salt + pin)` بملحٍ عشوائي
/// لكل تسجيل. لا حاجة لفكّ التشفير أبداً: التحقّق مقارنةُ بصمتين، لا قراءةُ
/// سرٍّ محفوظ. نفس مبدأ تخزين كلمات المرور، مطبَّقاً على رقمٍ محلّي.
///
/// ⚠️ **ولا يُخزَّن بـ`StorageService`** — ذاك نصٌّ عاديّ على قرص الجهاز.
/// [SecureStorageService] وحده (Keychain/Keystore) يناسب سرّاً يفتح الجلسة.
///
/// `implements AccountScopedStore` — فتُمحى بصمةُ الرقم تلقائياً مع أي خروجٍ
/// أو تبديل حساب عبر `AccountDataCleaner`، بلا أن يعرف ذاك المنظّف بوجود
/// هذا الموديول أصلاً. راجع توثيق `AccountScopedStore` لسبب هذا العقد.
class SessionGuardPinStore implements AccountScopedStore {
  SessionGuardPinStore(this._secureStorage);

  final SecureStorageService _secureStorage;

  static const _hashKey = 'session_guard_pin_hash';
  static const _saltKey = 'session_guard_pin_salt';

  Future<bool> hasPin() => _secureStorage.containsKey(_hashKey);

  /// يستبدل الرقم الحالي (إن وُجد) برقمٍ جديد.
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    await _secureStorage.write(_saltKey, salt);
    await _secureStorage.write(_hashKey, _hash(pin, salt));
  }

  /// `true` إن طابق [pin] المخزَّن. `false` كذلك إن لم يكن هناك رقمٌ مخزَّن
  /// أصلاً — لا استثناء يُربك المستدعي عند حالةٍ متوقَّعة.
  Future<bool> verify(String pin) async {
    final salt = await _secureStorage.read(_saltKey);
    final storedHash = await _secureStorage.read(_hashKey);
    if (salt == null || storedHash == null) return false;
    return _hash(pin, salt) == storedHash;
  }

  @override
  Future<void> clearForAccount() async {
    await _secureStorage.delete(_hashKey);
    await _secureStorage.delete(_saltKey);
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
