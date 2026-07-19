/// Extracts a human-readable message from a raw server response body.
///
/// Tries common response envelope shapes:
/// - `{ errors: { field: ['message'] } }` — validation (Laravel, Rails, etc.)
/// - `{ message: '...' }` — most REST APIs
/// - `{ error: { message: '...' } }` — nested error object
/// - `{ error: '...' }` — flat error string
///
/// Returns [null] when no message can be found — callers fall back to a
/// localized generic string via [FailureUiMapper].
abstract final class ServerMessageExtractor {
  const ServerMessageExtractor._();

  static String? extract(dynamic data) {
    if (data is! Map) return null;

    final errors = data['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first?.toString().trim();
          if (first != null && first.isNotEmpty) return first;
        }
        if (value is String && value.isNotEmpty) return value;
      }
    }

    final message = data['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;

    final errorNode = data['error'];
    if (errorNode is Map) {
      final nested = errorNode['message']?.toString().trim();
      if (nested != null && nested.isNotEmpty) return nested;
    }

    final errorStr = data['error']?.toString().trim();
    if (errorStr != null && errorStr.isNotEmpty) return errorStr;

    return null;
  }
}
