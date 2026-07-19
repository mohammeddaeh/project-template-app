import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';

/// Validated international phone number value object.
///
/// Accepts numbers in E.164 format (`+966501234567`) or local Gulf formats
/// that are normalised automatically:
/// - `05xxxxxxxx`  → `+96605xxxxxxxx` (Saudi Arabia default)
/// - `009665...`   → `+9665...`
///
/// To override the default country code, pass [defaultCountryCode]
/// (e.g. `+971` for UAE, `+973` for Bahrain).
///
/// Usage:
/// ```dart
/// final result = PhoneNumber.parse(rawInput);
/// result.fold(
///   (failure) => emit(State.error(failure)),
///   (phone)   => useCase(OtpParams(phone: phone)),
/// );
/// ```
final class PhoneNumber {
  const PhoneNumber._(this.value);

  /// The canonical E.164 phone number string (e.g. `+966501234567`).
  final String value;

  // Matches E.164: + followed by 7–15 digits
  static final _e164 = RegExp(r'^\+\d{7,15}$');

  /// Validates and normalises [input].
  ///
  /// [defaultCountryCode] is used when [input] looks like a local number
  /// (starts with `0` or contains only digits). Defaults to `+966` (Saudi).
  static Either<ValidationFailure, PhoneNumber> parse(
    String input, {
    String defaultCountryCode = '+966',
  }) {
    final digits = input.trim().replaceAll(RegExp(r'[\s\-()]'), '');

    if (digits.isEmpty) {
      return Left(
        const ValidationFailure(fields: {'phone': 'رقم الهاتف مطلوب'}),
      );
    }

    final normalised = _normalise(digits, defaultCountryCode);

    if (!_e164.hasMatch(normalised)) {
      return Left(
        const ValidationFailure(fields: {'phone': 'رقم الهاتف غير صالح'}),
      );
    }

    return Right(PhoneNumber._(normalised));
  }

  static String _normalise(String digits, String countryCode) {
    // 00966... → +966...
    if (digits.startsWith('00')) return '+${digits.substring(2)}';
    // 05xxxxxxxx → +96605xxxxxxxx (local Saudi format)
    if (digits.startsWith('0')) return '$countryCode$digits';
    // Already E.164
    if (digits.startsWith('+')) return digits;
    // Bare digits — assume local
    return '$countryCode$digits';
  }

  @override
  bool operator ==(Object other) =>
      other is PhoneNumber && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
