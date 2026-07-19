import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:app_template/core/platform/storage/encryption_service.dart';

/// [EncryptionService] adapter providing AUTHENTICATED encryption at rest.
///
/// ## Security design
/// - **Key derivation:** HKDF-SHA256 (RFC 5869). A random 16-byte salt per
///   message derives two independent sub-keys from [secretKey] — a 32-byte AES
///   key and a 32-byte HMAC key, domain-separated via distinct `info` labels.
///   This replaces the old zero-padding derivation, which leaked entropy for
///   short keys and truncated long ones.
/// - **Confidentiality:** AES-256-CBC with a random 16-byte IV per message.
/// - **Integrity & authenticity:** HMAC-SHA256 over (salt || iv || ciphertext)
///   — Encrypt-then-MAC. [decrypt] verifies the tag in constant time BEFORE
///   decrypting, defeating tampering and padding-oracle attacks.
///
/// NOTE: [secretKey] is expected to be high-entropy — use [generateKey] and
/// store the result in `SecureStorageService`. HKDF does not stretch
/// low-entropy passwords; if you must derive a key from a user password,
/// pre-stretch it with PBKDF2/Argon2 first.
///
/// ## Output format
/// `Base64( salt[16] || iv[16] || ciphertext[N] || tag[32] )`
///
/// NOT compatible with the previous (unauthenticated) format — values written
/// by the old adapter will fail authentication on decrypt.
///
/// Registered manually in `di/injection_module.dart` — NOT annotated with
/// `@injectable`.
class AesEncryptionAdapter implements EncryptionService {
  static const _saltLength = 16;
  static const _ivLength = 16; // AES block size
  static const _keyLength = 32; // AES-256
  static const _tagLength = 32; // HMAC-SHA256 output
  static const _minLength = _saltLength + _ivLength + _tagLength;

  static const _encInfo = 'app_template/aes-256-cbc/enc';
  static const _macInfo = 'app_template/hmac-sha256/mac';

  final Random _random = Random.secure();

  @override
  String encrypt(String plaintext, String secretKey) {
    final ikm = utf8.encode(secretKey);
    final salt = _randomBytes(_saltLength);
    final (encKey, macKey) = _deriveKeys(ikm, salt);

    final iv = IV(_randomBytes(_ivLength));
    final encrypter = Encrypter(AES(Key(encKey), mode: AESMode.cbc));
    final cipher = encrypter.encrypt(plaintext, iv: iv).bytes;

    // Encrypt-then-MAC over salt || iv || ciphertext.
    final authenticated = Uint8List.fromList([...salt, ...iv.bytes, ...cipher]);
    final tag = Hmac(sha256, macKey).convert(authenticated).bytes;

    return base64Encode(Uint8List.fromList([...authenticated, ...tag]));
  }

  @override
  String decrypt(String ciphertext, String secretKey) {
    final combined = base64Decode(ciphertext);
    if (combined.length < _minLength) {
      throw const FormatException('Ciphertext is too short / malformed.');
    }

    final salt = combined.sublist(0, _saltLength);
    final tag = combined.sublist(combined.length - _tagLength);
    final authenticated = combined.sublist(0, combined.length - _tagLength);

    final ikm = utf8.encode(secretKey);
    final (encKey, macKey) = _deriveKeys(ikm, salt);

    // Verify integrity BEFORE decrypting (constant-time compare).
    final expectedTag = Hmac(sha256, macKey).convert(authenticated).bytes;
    if (!_constantTimeEquals(tag, expectedTag)) {
      throw const FormatException(
        'Authentication failed — data was tampered with or the key is wrong.',
      );
    }

    final iv = IV(
      Uint8List.fromList(
        authenticated.sublist(_saltLength, _saltLength + _ivLength),
      ),
    );
    final cipher = authenticated.sublist(_saltLength + _ivLength);
    final encrypter = Encrypter(AES(Key(encKey), mode: AESMode.cbc));

    return encrypter.decrypt(Encrypted(Uint8List.fromList(cipher)), iv: iv);
  }

  @override
  String generateKey() => base64UrlEncode(_randomBytes(_keyLength));

  // ── Internal ──────────────────────────────────────────────────────────────

  Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  /// HKDF-SHA256 (RFC 5869): derives independent AES + HMAC keys from [ikm].
  ///
  /// Each sub-key is a single 32-byte HKDF-Expand block (counter `0x01`),
  /// separated by a distinct `info` label so the two keys are independent.
  (Uint8List encKey, Uint8List macKey) _deriveKeys(
    List<int> ikm,
    List<int> salt,
  ) {
    // Extract.
    final prk = Hmac(sha256, salt).convert(ikm).bytes;
    // Expand.
    final encKey = Hmac(
      sha256,
      prk,
    ).convert([...utf8.encode(_encInfo), 0x01]).bytes;
    final macKey = Hmac(
      sha256,
      prk,
    ).convert([...utf8.encode(_macInfo), 0x01]).bytes;
    return (Uint8List.fromList(encKey), Uint8List.fromList(macKey));
  }

  /// Constant-time byte comparison — avoids timing side-channels on the tag.
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
