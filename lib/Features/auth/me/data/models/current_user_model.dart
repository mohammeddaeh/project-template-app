import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/Features/auth/shared/models/auth_user_model.dart';

/// Parses `data` on `GET /api/v1/account/me`.
///
/// ## There is no wrapper object
///
/// The server puts the account **at the root of `data`** — `toWireAccount(row)`
/// and nothing else. This file used to read `json['user']`, a key no response
/// has ever carried, which made every call fail: `null` cast to
/// `Map<String, dynamic>` threw, `HandleBodyResponse` mapped it to a generic
/// `Failure`, and the profile screen showed an error against a `200 OK`.
///
/// Kept as a named function rather than calling [AuthUserModel.fromJson]
/// inline at the datasource, so that the day `/me` grows a sibling field
/// (`settings`, `unread_count`) there is one place that already owns the
/// unwrapping.
AuthUser currentUserFromJson(Map<String, dynamic> json) =>
    AuthUserModel.fromJson(json).toEntity();
