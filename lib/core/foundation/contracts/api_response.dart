import 'package:equatable/equatable.dart';

/// Lightweight error carrier used only inside [ApiResponse].
/// This is a data-layer DTO — it is NOT the domain [Failure].
/// Repositories map it to the appropriate [Failure] subclass.
class ApiError extends Equatable {
  const ApiError({this.code, this.message = '', this.data});

  final int? code;
  final String message;

  /// The error payload beyond [message], when the API sends one.
  ///
  /// Some endpoints distinguish several refusal reasons **behind a single HTTP
  /// status** — a 403 that means "pending approval" vs "suspended" vs
  /// "disabled" — and put the discriminator in the body
  /// (`data.account_status`, `data.message_key`, …).
  ///
  /// Branch on this, never on [message]: the message is translated prose that
  /// changes the moment somebody rewords it, and matching against its text
  /// produces a bug that appears only in the language nobody tested.
  ///
  /// Turning the payload into a typed `Failure` stays the repository's job —
  /// this class carries the raw map and interprets nothing.
  ///
  /// Optional with a `null` default, so every existing
  /// `ApiError(code: …, message: …)` call site keeps compiling untouched.
  final Map<String, dynamic>? data;

  @override
  List<Object?> get props => [code, message, data];
}

class ApiResponse<T> extends Equatable {
  final String status;
  final T? data;
  final String message;
  final ApiError? error;

  const ApiResponse({
    required this.message,
    required this.data,
    required this.status,
    this.error,
  });

  const ApiResponse.data({required this.data})
    : status = "",
      error = null,
      message = "";

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      status: json["status"] ?? "",
      message: json["message"] ?? "",
      data: json["data"] != null ? fromJsonT(json["data"]) : null,
      error: json["status"] == "error"
          ? ApiError(
              code: json["statusCode"] as int?,
              message: json["message"] ?? "",
            )
          : null,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {
      "status": status,
      "message": message,
      "data": data != null ? toJsonT(data as T) : null,
      "error": error != null ? {"message": error?.message} : null,
    };
  }

  @override
  List<Object?> get props => [data, error, message];
}
