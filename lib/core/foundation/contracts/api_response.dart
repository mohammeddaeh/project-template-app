import 'package:equatable/equatable.dart';

/// Lightweight error carrier used only inside [ApiResponse].
/// This is a data-layer DTO — it is NOT the domain [Failure].
/// Repositories map it to the appropriate [Failure] subclass.
class ApiError extends Equatable {
  const ApiError({this.code, this.message = ''});

  final int? code;
  final String message;

  @override
  List<Object?> get props => [code, message];
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
