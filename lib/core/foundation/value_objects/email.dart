import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';

/// Validated e-mail address value object.
///
/// Construction is only possible through [Email.validate], which returns
/// [Left<ValidationFailure>] on invalid input and [Right<Email>] on success.
/// This guarantees that any [Email] instance in the domain layer is valid.
///
/// Usage:
/// ```dart
/// final result = Email.validate(rawInput);
/// result.fold(
///   (failure) => emit(State.error(failure)),
///   (email)   => useCase(LoginParams(email: email)),
/// );
/// ```
final class Email {
  const Email._(this.value);

  /// The canonical (trimmed, lower-cased) e-mail string.
  final String value;

  static final _regex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates [input] and returns [Right<Email>] or [Left<ValidationFailure>].
  static Either<ValidationFailure, Email> validate(String input) {
    final trimmed = input.trim().toLowerCase();

    if (trimmed.isEmpty) {
      return Left(
        const ValidationFailure(fields: {'email': 'البريد الإلكتروني مطلوب'}),
      );
    }

    if (!_regex.hasMatch(trimmed)) {
      return Left(
        const ValidationFailure(
          fields: {'email': 'البريد الإلكتروني غير صالح'},
        ),
      );
    }

    return Right(Email._(trimmed));
  }

  @override
  bool operator ==(Object other) => other is Email && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
