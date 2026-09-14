import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';
import 'package:app_template/modules/session_guard/data/session_guard_pin_store.dart';

/// خزنٌ في الذاكرة — بلا Keychain/Keystore حقيقيَّين بالاختبار.
class _FakeSecureStorage implements SecureStorageService {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<Map<String, String>> readAll() async => Map.of(_values);

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);
}

void main() {
  late _FakeSecureStorage storage;
  late SessionGuardPinStore store;

  setUp(() {
    storage = _FakeSecureStorage();
    store = SessionGuardPinStore(storage);
  });

  test('hasPin is false before any PIN is set', () async {
    expect(await store.hasPin(), isFalse);
  });

  test('a PIN verifies against itself after setPin', () async {
    await store.setPin('4271');
    expect(await store.hasPin(), isTrue);
    expect(await store.verify('4271'), isTrue);
  });

  test('a wrong PIN does not verify', () async {
    await store.setPin('4271');
    expect(await store.verify('0000'), isFalse);
  });

  test('verify before any setPin is false, not a throw', () async {
    expect(await store.verify('4271'), isFalse);
  });

  test('the raw PIN is never stored — only a salted hash', () async {
    await store.setPin('4271');
    final raw = await storage.readAll();
    expect(raw.values, isNot(contains('4271')));
  });

  test('setPin replaces a previous PIN entirely', () async {
    await store.setPin('1111');
    await store.setPin('2222');
    expect(await store.verify('1111'), isFalse);
    expect(await store.verify('2222'), isTrue);
  });

  test('two accounts choosing the same PIN get different stored hashes', () async {
    await store.setPin('4271');
    final firstHash = (await storage.readAll())['session_guard_pin_hash'];

    await store.clearForAccount();
    await store.setPin('4271');
    final secondHash = (await storage.readAll())['session_guard_pin_hash'];

    // ملحٌ عشوائي مختلف في كل مرة — نفس الرقم لا ينتج نفس البصمة، وإلا صارت
    // البصمة نفسها قابلة لهجوم قاموسٍ عبر الأجهزة.
    expect(firstHash, isNot(equals(secondHash)));
  });

  test('clearForAccount (AccountScopedStore) removes the PIN entirely', () async {
    await store.setPin('4271');
    await store.clearForAccount();
    expect(await store.hasPin(), isFalse);
    expect(await store.verify('4271'), isFalse);
  });
}
