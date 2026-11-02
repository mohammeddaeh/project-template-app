import 'package:app_template/features/auth/shared/entities/auth_user.dart';
import 'package:app_template/features/auth/shared/models/auth_user_model.dart';

/// Parses `data` on `GET /api/v1/account/me`.
///
/// ## There is no wrapper object
///
/// The server puts the account **at the root of `data`** — `toWireAccount(row)`
/// and nothing else. Reading a wrapper key such as `json['user']` would fail
/// every call: `null` cast to `Map<String, dynamic>` throws,
/// `HandleBodyResponse` maps it to a generic `Failure`, and the profile screen
/// shows an error against a `200 OK`.
///
/// Kept as a named function rather than calling [AuthUserModel.fromJson]
/// inline at the datasource, so that the day `/me` grows a sibling field
/// (`settings`, `unread_count`) there is one place that already owns the
/// unwrapping.
AuthUser currentUserFromJson(Map<String, dynamic> json) =>
    AuthUserModel.fromJson(json).toEntity();
