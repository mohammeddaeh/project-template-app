// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:app_template/Features/auth/change_password/presentation/pages/change_password_screen.dart'
    as _i1;
import 'package:app_template/Features/auth/forgot_password/presentation/cubits/forgot_password_cubit.dart'
    as _i32;
import 'package:app_template/Features/auth/forgot_password/presentation/pages/forgot_password_screen.dart'
    as _i3;
import 'package:app_template/Features/auth/forgot_password/presentation/pages/reset_password_screen.dart'
    as _i7;
import 'package:app_template/Features/auth/login/presentation/pages/login_screen.dart'
    as _i5;
import 'package:app_template/Features/auth/verify_email/presentation/pages/verify_email_screen.dart'
    as _i28;
import 'package:app_template/Features/home/presentation/pages/home_screen.dart'
    as _i4;
import 'package:app_template/Features/settings/presentation/pages/settings_screen.dart'
    as _i8;
import 'package:app_template/Features/splash/presentation/pages/splash_screen.dart'
    as _i9;
import 'package:app_template/Features/test/presentation/pages/test_api_simulator_screen.dart'
    as _i10;
import 'package:app_template/Features/test/presentation/pages/test_bloc_states_screen.dart'
    as _i11;
import 'package:app_template/Features/test/presentation/pages/test_connectivity_screen.dart'
    as _i12;
import 'package:app_template/Features/test/presentation/pages/test_crud_demo_screen.dart'
    as _i13;
import 'package:app_template/Features/test/presentation/pages/test_dashboard_screen.dart'
    as _i14;
import 'package:app_template/Features/test/presentation/pages/test_failure_demo_screen.dart'
    as _i15;
import 'package:app_template/Features/test/presentation/pages/test_feature_wizard_screen.dart'
    as _i16;
import 'package:app_template/Features/test/presentation/pages/test_form_validation_screen.dart'
    as _i17;
import 'package:app_template/Features/test/presentation/pages/test_forms_demo_screen.dart'
    as _i18;
import 'package:app_template/Features/test/presentation/pages/test_haptics_demo_screen.dart'
    as _i19;
import 'package:app_template/Features/test/presentation/pages/test_nav_stack_screen.dart'
    as _i20;
import 'package:app_template/Features/test/presentation/pages/test_pagination_demo_screen.dart'
    as _i21;
import 'package:app_template/Features/test/presentation/pages/test_platform_services_screen.dart'
    as _i22;
import 'package:app_template/Features/test/presentation/pages/test_predictive_back_demo_screen.dart'
    as _i23;
import 'package:app_template/Features/test/presentation/pages/test_settings_demo_screen.dart'
    as _i24;
import 'package:app_template/Features/test/presentation/pages/test_states_demo_screen.dart'
    as _i25;
import 'package:app_template/Features/test/presentation/pages/test_sync_queue_screen.dart'
    as _i26;
import 'package:app_template/Features/test/presentation/pages/test_theme_demo_screen.dart'
    as _i27;
import 'package:app_template/shared/screens/error_view.dart' as _i2;
import 'package:app_template/shared/screens/main_shell_page.dart' as _i6;
import 'package:app_template/shared/screens/widget_library_demo_screen.dart'
    as _i29;
import 'package:auto_route/auto_route.dart' as _i30;
import 'package:flutter/material.dart' as _i31;

/// generated route for
/// [_i1.ChangePasswordScreen]
class ChangePasswordRoute extends _i30.PageRouteInfo<void> {
  const ChangePasswordRoute({List<_i30.PageRouteInfo>? children})
    : super(ChangePasswordRoute.name, initialChildren: children);

  static const String name = 'ChangePasswordRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i1.ChangePasswordScreen();
    },
  );
}

/// generated route for
/// [_i2.ErrorView]
class ErrorRoute extends _i30.PageRouteInfo<ErrorRouteArgs> {
  ErrorRoute({
    _i31.Key? key,
    _i31.FlutterErrorDetails? errorDetails,
    String? message,
    List<_i30.PageRouteInfo>? children,
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

  static _i30.PageInfo page = _i30.PageInfo(
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

  final _i31.Key? key;

  final _i31.FlutterErrorDetails? errorDetails;

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
class ForgotPasswordRoute extends _i30.PageRouteInfo<void> {
  const ForgotPasswordRoute({List<_i30.PageRouteInfo>? children})
    : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i3.ForgotPasswordScreen();
    },
  );
}

/// generated route for
/// [_i4.HomeScreen]
class HomeRoute extends _i30.PageRouteInfo<void> {
  const HomeRoute({List<_i30.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i4.HomeScreen();
    },
  );
}

/// generated route for
/// [_i5.LoginScreen]
class LoginRoute extends _i30.PageRouteInfo<void> {
  const LoginRoute({List<_i30.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i5.LoginScreen();
    },
  );
}

/// generated route for
/// [_i6.MainShellPage]
class MainShellRoute extends _i30.PageRouteInfo<void> {
  const MainShellRoute({List<_i30.PageRouteInfo>? children})
    : super(MainShellRoute.name, initialChildren: children);

  static const String name = 'MainShellRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i6.MainShellPage();
    },
  );
}

/// generated route for
/// [_i7.ResetPasswordScreen]
class ResetPasswordRoute extends _i30.PageRouteInfo<ResetPasswordRouteArgs> {
  ResetPasswordRoute({
    _i31.Key? key,
    required _i32.ForgotPasswordCubit cubit,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         ResetPasswordRoute.name,
         args: ResetPasswordRouteArgs(key: key, cubit: cubit),
         initialChildren: children,
       );

  static const String name = 'ResetPasswordRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ResetPasswordRouteArgs>();
      return _i7.ResetPasswordScreen(key: args.key, cubit: args.cubit);
    },
  );
}

class ResetPasswordRouteArgs {
  const ResetPasswordRouteArgs({this.key, required this.cubit});

  final _i31.Key? key;

  final _i32.ForgotPasswordCubit cubit;

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
/// [_i8.SettingsScreen]
class SettingsRoute extends _i30.PageRouteInfo<void> {
  const SettingsRoute({List<_i30.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i8.SettingsScreen();
    },
  );
}

/// generated route for
/// [_i9.SplashScreen]
class SplashRoute extends _i30.PageRouteInfo<void> {
  const SplashRoute({List<_i30.PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i9.SplashScreen();
    },
  );
}

/// generated route for
/// [_i10.TestApiSimulatorScreen]
class TestApiSimulatorRoute extends _i30.PageRouteInfo<void> {
  const TestApiSimulatorRoute({List<_i30.PageRouteInfo>? children})
    : super(TestApiSimulatorRoute.name, initialChildren: children);

  static const String name = 'TestApiSimulatorRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i10.TestApiSimulatorScreen();
    },
  );
}

/// generated route for
/// [_i11.TestBlocStatesScreen]
class TestBlocStatesRoute extends _i30.PageRouteInfo<void> {
  const TestBlocStatesRoute({List<_i30.PageRouteInfo>? children})
    : super(TestBlocStatesRoute.name, initialChildren: children);

  static const String name = 'TestBlocStatesRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i11.TestBlocStatesScreen();
    },
  );
}

/// generated route for
/// [_i12.TestConnectivityScreen]
class TestConnectivityRoute extends _i30.PageRouteInfo<void> {
  const TestConnectivityRoute({List<_i30.PageRouteInfo>? children})
    : super(TestConnectivityRoute.name, initialChildren: children);

  static const String name = 'TestConnectivityRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i12.TestConnectivityScreen();
    },
  );
}

/// generated route for
/// [_i13.TestCrudDemoScreen]
class TestCrudDemoRoute extends _i30.PageRouteInfo<void> {
  const TestCrudDemoRoute({List<_i30.PageRouteInfo>? children})
    : super(TestCrudDemoRoute.name, initialChildren: children);

  static const String name = 'TestCrudDemoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i13.TestCrudDemoScreen();
    },
  );
}

/// generated route for
/// [_i14.TestDashboardScreen]
class TestDashboardRoute extends _i30.PageRouteInfo<void> {
  const TestDashboardRoute({List<_i30.PageRouteInfo>? children})
    : super(TestDashboardRoute.name, initialChildren: children);

  static const String name = 'TestDashboardRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i14.TestDashboardScreen();
    },
  );
}

/// generated route for
/// [_i15.TestFailureDemoScreen]
class TestFailureDemoRoute extends _i30.PageRouteInfo<void> {
  const TestFailureDemoRoute({List<_i30.PageRouteInfo>? children})
    : super(TestFailureDemoRoute.name, initialChildren: children);

  static const String name = 'TestFailureDemoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i15.TestFailureDemoScreen();
    },
  );
}

/// generated route for
/// [_i16.TestFeatureWizardScreen]
class TestFeatureWizardRoute extends _i30.PageRouteInfo<void> {
  const TestFeatureWizardRoute({List<_i30.PageRouteInfo>? children})
    : super(TestFeatureWizardRoute.name, initialChildren: children);

  static const String name = 'TestFeatureWizardRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i16.TestFeatureWizardScreen();
    },
  );
}

/// generated route for
/// [_i17.TestFormValidationScreen]
class TestFormValidationRoute extends _i30.PageRouteInfo<void> {
  const TestFormValidationRoute({List<_i30.PageRouteInfo>? children})
    : super(TestFormValidationRoute.name, initialChildren: children);

  static const String name = 'TestFormValidationRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i17.TestFormValidationScreen();
    },
  );
}

/// generated route for
/// [_i18.TestFormsDemoScreen]
class TestFormsDemoRoute extends _i30.PageRouteInfo<void> {
  const TestFormsDemoRoute({List<_i30.PageRouteInfo>? children})
    : super(TestFormsDemoRoute.name, initialChildren: children);

  static const String name = 'TestFormsDemoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i18.TestFormsDemoScreen();
    },
  );
}

/// generated route for
/// [_i19.TestHapticsDemoScreen]
class TestHapticsDemoRoute extends _i30.PageRouteInfo<void> {
  const TestHapticsDemoRoute({List<_i30.PageRouteInfo>? children})
    : super(TestHapticsDemoRoute.name, initialChildren: children);

  static const String name = 'TestHapticsDemoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i19.TestHapticsDemoScreen();
    },
  );
}

/// generated route for
/// [_i20.TestNavStackScreen]
class TestNavStackRoute extends _i30.PageRouteInfo<void> {
  const TestNavStackRoute({List<_i30.PageRouteInfo>? children})
    : super(TestNavStackRoute.name, initialChildren: children);

  static const String name = 'TestNavStackRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i20.TestNavStackScreen();
    },
  );
}

/// generated route for
/// [_i21.TestPaginationDemoScreen]
class TestPaginationDemoRoute extends _i30.PageRouteInfo<void> {
  const TestPaginationDemoRoute({List<_i30.PageRouteInfo>? children})
    : super(TestPaginationDemoRoute.name, initialChildren: children);

  static const String name = 'TestPaginationDemoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i21.TestPaginationDemoScreen();
    },
  );
}

/// generated route for
/// [_i22.TestPlatformServicesScreen]
class TestPlatformServicesRoute extends _i30.PageRouteInfo<void> {
  const TestPlatformServicesRoute({List<_i30.PageRouteInfo>? children})
    : super(TestPlatformServicesRoute.name, initialChildren: children);

  static const String name = 'TestPlatformServicesRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i22.TestPlatformServicesScreen();
    },
  );
}

/// generated route for
/// [_i23.TestPredictiveBackDemoScreen]
class TestPredictiveBackDemoRoute extends _i30.PageRouteInfo<void> {
  const TestPredictiveBackDemoRoute({List<_i30.PageRouteInfo>? children})
    : super(TestPredictiveBackDemoRoute.name, initialChildren: children);

  static const String name = 'TestPredictiveBackDemoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i23.TestPredictiveBackDemoScreen();
    },
  );
}

/// generated route for
/// [_i24.TestSettingsDemoScreen]
class TestSettingsDemoRoute extends _i30.PageRouteInfo<void> {
  const TestSettingsDemoRoute({List<_i30.PageRouteInfo>? children})
    : super(TestSettingsDemoRoute.name, initialChildren: children);

  static const String name = 'TestSettingsDemoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i24.TestSettingsDemoScreen();
    },
  );
}

/// generated route for
/// [_i25.TestStatesDemoScreen]
class TestStatesDemoRoute extends _i30.PageRouteInfo<void> {
  const TestStatesDemoRoute({List<_i30.PageRouteInfo>? children})
    : super(TestStatesDemoRoute.name, initialChildren: children);

  static const String name = 'TestStatesDemoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i25.TestStatesDemoScreen();
    },
  );
}

/// generated route for
/// [_i26.TestSyncQueueScreen]
class TestSyncQueueRoute extends _i30.PageRouteInfo<void> {
  const TestSyncQueueRoute({List<_i30.PageRouteInfo>? children})
    : super(TestSyncQueueRoute.name, initialChildren: children);

  static const String name = 'TestSyncQueueRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i26.TestSyncQueueScreen();
    },
  );
}

/// generated route for
/// [_i27.TestThemeDemoScreen]
class TestThemeDemoRoute extends _i30.PageRouteInfo<void> {
  const TestThemeDemoRoute({List<_i30.PageRouteInfo>? children})
    : super(TestThemeDemoRoute.name, initialChildren: children);

  static const String name = 'TestThemeDemoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i27.TestThemeDemoScreen();
    },
  );
}

/// generated route for
/// [_i28.VerifyEmailScreen]
class VerifyEmailRoute extends _i30.PageRouteInfo<VerifyEmailRouteArgs> {
  VerifyEmailRoute({
    _i31.Key? key,
    required String email,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         VerifyEmailRoute.name,
         args: VerifyEmailRouteArgs(key: key, email: email),
         initialChildren: children,
       );

  static const String name = 'VerifyEmailRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<VerifyEmailRouteArgs>();
      return _i28.VerifyEmailScreen(key: args.key, email: args.email);
    },
  );
}

class VerifyEmailRouteArgs {
  const VerifyEmailRouteArgs({this.key, required this.email});

  final _i31.Key? key;

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

/// generated route for
/// [_i29.WidgetLibraryDemoScreen]
class WidgetLibraryDemoRoute extends _i30.PageRouteInfo<void> {
  const WidgetLibraryDemoRoute({List<_i30.PageRouteInfo>? children})
    : super(WidgetLibraryDemoRoute.name, initialChildren: children);

  static const String name = 'WidgetLibraryDemoRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i29.WidgetLibraryDemoScreen();
    },
  );
}
