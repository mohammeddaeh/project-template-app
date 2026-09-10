// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:app_template/features/auth/change_password/presentation/pages/change_password_screen.dart'
    as _i1;
import 'package:app_template/features/auth/forgot_password/presentation/cubits/forgot_password_cubit.dart'
    as _i17;
import 'package:app_template/features/auth/forgot_password/presentation/pages/forgot_password_screen.dart'
    as _i3;
import 'package:app_template/features/auth/forgot_password/presentation/pages/reset_password_screen.dart'
    as _i8;
import 'package:app_template/features/auth/login/presentation/pages/login_screen.dart'
    as _i5;
import 'package:app_template/features/auth/register/presentation/pages/register_screen.dart'
    as _i7;
import 'package:app_template/features/auth/verify_email/presentation/pages/verify_email_screen.dart'
    as _i14;
import 'package:app_template/features/home/presentation/pages/home_screen.dart'
    as _i4;
import 'package:app_template/features/settings/presentation/pages/settings_screen.dart'
    as _i10;
import 'package:app_template/modules/access_control/presentation/pages/roles_screen.dart'
    as _i9;
import 'package:app_template/modules/access_control/presentation/pages/user_access_screen.dart'
    as _i13;
import 'package:app_template/modules/data_transfer/presentation/pages/transfer_export_screen.dart'
    as _i11;
import 'package:app_template/modules/data_transfer/presentation/pages/transfer_import_screen.dart'
    as _i12;
import 'package:app_template/routes/main_shell_page.dart' as _i6;
import 'package:app_template/ui/error/error_view.dart' as _i2;
import 'package:auto_route/auto_route.dart' as _i15;
import 'package:flutter/material.dart' as _i16;

/// generated route for
/// [_i1.ChangePasswordScreen]
class ChangePasswordRoute extends _i15.PageRouteInfo<void> {
  const ChangePasswordRoute({List<_i15.PageRouteInfo>? children})
    : super(ChangePasswordRoute.name, initialChildren: children);

  static const String name = 'ChangePasswordRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i1.ChangePasswordScreen();
    },
  );
}

/// generated route for
/// [_i2.ErrorView]
class ErrorRoute extends _i15.PageRouteInfo<ErrorRouteArgs> {
  ErrorRoute({
    _i16.Key? key,
    _i16.FlutterErrorDetails? errorDetails,
    String? message,
    List<_i15.PageRouteInfo>? children,
  }) : super(
         ErrorRoute.name,
         args: ErrorRouteArgs(
           key: key,
           errorDetails: errorDetails,
           message: message,
         ),
         initialChildren: children,
       );

  static const String name = 'ErrorRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ErrorRouteArgs>(
        orElse: () => const ErrorRouteArgs(),
      );
      return _i2.ErrorView(
        key: args.key,
        errorDetails: args.errorDetails,
        message: args.message,
      );
    },
  );
}

class ErrorRouteArgs {
  const ErrorRouteArgs({this.key, this.errorDetails, this.message});

  final _i16.Key? key;

  final _i16.FlutterErrorDetails? errorDetails;

  final String? message;

  @override
  String toString() {
    return 'ErrorRouteArgs{key: $key, errorDetails: $errorDetails, message: $message}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ErrorRouteArgs) return false;
    return key == other.key &&
        errorDetails == other.errorDetails &&
        message == other.message;
  }

  @override
  int get hashCode => key.hashCode ^ errorDetails.hashCode ^ message.hashCode;
}

/// generated route for
/// [_i3.ForgotPasswordScreen]
class ForgotPasswordRoute extends _i15.PageRouteInfo<void> {
  const ForgotPasswordRoute({List<_i15.PageRouteInfo>? children})
    : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i3.ForgotPasswordScreen();
    },
  );
}

/// generated route for
/// [_i4.HomeScreen]
class HomeRoute extends _i15.PageRouteInfo<void> {
  const HomeRoute({List<_i15.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i4.HomeScreen();
    },
  );
}

/// generated route for
/// [_i5.LoginScreen]
class LoginRoute extends _i15.PageRouteInfo<void> {
  const LoginRoute({List<_i15.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i5.LoginScreen();
    },
  );
}

/// generated route for
/// [_i6.MainShellPage]
class MainShellRoute extends _i15.PageRouteInfo<void> {
  const MainShellRoute({List<_i15.PageRouteInfo>? children})
    : super(MainShellRoute.name, initialChildren: children);

  static const String name = 'MainShellRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i6.MainShellPage();
    },
  );
}

/// generated route for
/// [_i7.RegisterScreen]
class RegisterRoute extends _i15.PageRouteInfo<void> {
  const RegisterRoute({List<_i15.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i7.RegisterScreen();
    },
  );
}

/// generated route for
/// [_i8.ResetPasswordScreen]
class ResetPasswordRoute extends _i15.PageRouteInfo<ResetPasswordRouteArgs> {
  ResetPasswordRoute({
    _i16.Key? key,
    required _i17.ForgotPasswordCubit cubit,
    List<_i15.PageRouteInfo>? children,
  }) : super(
         ResetPasswordRoute.name,
         args: ResetPasswordRouteArgs(key: key, cubit: cubit),
         initialChildren: children,
       );

  static const String name = 'ResetPasswordRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ResetPasswordRouteArgs>();
      return _i8.ResetPasswordScreen(key: args.key, cubit: args.cubit);
    },
  );
}

class ResetPasswordRouteArgs {
  const ResetPasswordRouteArgs({this.key, required this.cubit});

  final _i16.Key? key;

  final _i17.ForgotPasswordCubit cubit;

  @override
  String toString() {
    return 'ResetPasswordRouteArgs{key: $key, cubit: $cubit}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResetPasswordRouteArgs) return false;
    return key == other.key && cubit == other.cubit;
  }

  @override
  int get hashCode => key.hashCode ^ cubit.hashCode;
}

/// generated route for
/// [_i9.RolesScreen]
class RolesRoute extends _i15.PageRouteInfo<void> {
  const RolesRoute({List<_i15.PageRouteInfo>? children})
    : super(RolesRoute.name, initialChildren: children);

  static const String name = 'RolesRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i9.RolesScreen();
    },
  );
}

/// generated route for
/// [_i10.SettingsScreen]
class SettingsRoute extends _i15.PageRouteInfo<void> {
  const SettingsRoute({List<_i15.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i10.SettingsScreen();
    },
  );
}

/// generated route for
/// [_i11.TransferExportScreen]
class TransferExportRoute extends _i15.PageRouteInfo<TransferExportRouteArgs> {
  TransferExportRoute({
    required String resource,
    _i16.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
         TransferExportRoute.name,
         args: TransferExportRouteArgs(resource: resource, key: key),
         initialChildren: children,
       );

  static const String name = 'TransferExportRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TransferExportRouteArgs>();
      return _i11.TransferExportScreen(resource: args.resource, key: args.key);
    },
  );
}

class TransferExportRouteArgs {
  const TransferExportRouteArgs({required this.resource, this.key});

  final String resource;

  final _i16.Key? key;

  @override
  String toString() {
    return 'TransferExportRouteArgs{resource: $resource, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TransferExportRouteArgs) return false;
    return resource == other.resource && key == other.key;
  }

  @override
  int get hashCode => resource.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i12.TransferImportScreen]
class TransferImportRoute extends _i15.PageRouteInfo<TransferImportRouteArgs> {
  TransferImportRoute({
    required String resource,
    _i16.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
         TransferImportRoute.name,
         args: TransferImportRouteArgs(resource: resource, key: key),
         initialChildren: children,
       );

  static const String name = 'TransferImportRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TransferImportRouteArgs>();
      return _i12.TransferImportScreen(resource: args.resource, key: args.key);
    },
  );
}

class TransferImportRouteArgs {
  const TransferImportRouteArgs({required this.resource, this.key});

  final String resource;

  final _i16.Key? key;

  @override
  String toString() {
    return 'TransferImportRouteArgs{resource: $resource, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TransferImportRouteArgs) return false;
    return resource == other.resource && key == other.key;
  }

  @override
  int get hashCode => resource.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i13.UserAccessScreen]
class UserAccessRoute extends _i15.PageRouteInfo<UserAccessRouteArgs> {
  UserAccessRoute({
    required int userId,
    _i16.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
         UserAccessRoute.name,
         args: UserAccessRouteArgs(userId: userId, key: key),
         initialChildren: children,
       );

  static const String name = 'UserAccessRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UserAccessRouteArgs>();
      return _i13.UserAccessScreen(userId: args.userId, key: args.key);
    },
  );
}

class UserAccessRouteArgs {
  const UserAccessRouteArgs({required this.userId, this.key});

  final int userId;

  final _i16.Key? key;

  @override
  String toString() {
    return 'UserAccessRouteArgs{userId: $userId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserAccessRouteArgs) return false;
    return userId == other.userId && key == other.key;
  }

  @override
  int get hashCode => userId.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i14.VerifyEmailScreen]
class VerifyEmailRoute extends _i15.PageRouteInfo<VerifyEmailRouteArgs> {
  VerifyEmailRoute({
    _i16.Key? key,
    required String email,
    List<_i15.PageRouteInfo>? children,
  }) : super(
         VerifyEmailRoute.name,
         args: VerifyEmailRouteArgs(key: key, email: email),
         initialChildren: children,
       );

  static const String name = 'VerifyEmailRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<VerifyEmailRouteArgs>();
      return _i14.VerifyEmailScreen(key: args.key, email: args.email);
    },
  );
}

class VerifyEmailRouteArgs {
  const VerifyEmailRouteArgs({this.key, required this.email});

  final _i16.Key? key;

  final String email;

  @override
  String toString() {
    return 'VerifyEmailRouteArgs{key: $key, email: $email}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VerifyEmailRouteArgs) return false;
    return key == other.key && email == other.email;
  }

  @override
  int get hashCode => key.hashCode ^ email.hashCode;
}
