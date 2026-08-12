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
    as _i39;
import 'package:app_template/Features/auth/forgot_password/presentation/pages/forgot_password_screen.dart'
    as _i3;
import 'package:app_template/Features/auth/forgot_password/presentation/pages/reset_password_screen.dart'
    as _i10;
import 'package:app_template/Features/auth/login/presentation/pages/login_screen.dart'
    as _i5;
import 'package:app_template/Features/auth/register/presentation/pages/register_screen.dart'
    as _i9;
import 'package:app_template/Features/auth/verify_email/presentation/pages/verify_email_screen.dart'
    as _i34;
import 'package:app_template/Features/home/presentation/pages/home_screen.dart'
    as _i4;
import 'package:app_template/Features/notes/domain/entities/note.dart' as _i38;
import 'package:app_template/Features/notes/presentation/pages/note_form_screen.dart'
    as _i7;
import 'package:app_template/Features/notes/presentation/pages/notes_screen.dart'
    as _i8;
import 'package:app_template/Features/settings/presentation/pages/settings_screen.dart'
    as _i11;
import 'package:app_template/Features/splash/presentation/pages/splash_screen.dart'
    as _i12;
import 'package:app_template/Features/test/presentation/pages/test_api_simulator_screen.dart'
    as _i13;
import 'package:app_template/Features/test/presentation/pages/test_bloc_states_screen.dart'
    as _i14;
import 'package:app_template/Features/test/presentation/pages/test_connectivity_screen.dart'
    as _i15;
import 'package:app_template/Features/test/presentation/pages/test_crud_demo_screen.dart'
    as _i16;
import 'package:app_template/Features/test/presentation/pages/test_dashboard_screen.dart'
    as _i17;
import 'package:app_template/Features/test/presentation/pages/test_data_transfer_screen.dart'
    as _i18;
import 'package:app_template/Features/test/presentation/pages/test_failure_demo_screen.dart'
    as _i19;
import 'package:app_template/Features/test/presentation/pages/test_feature_wizard_screen.dart'
    as _i20;
import 'package:app_template/Features/test/presentation/pages/test_form_validation_screen.dart'
    as _i21;
import 'package:app_template/Features/test/presentation/pages/test_forms_demo_screen.dart'
    as _i22;
import 'package:app_template/Features/test/presentation/pages/test_haptics_demo_screen.dart'
    as _i23;
import 'package:app_template/Features/test/presentation/pages/test_nav_stack_screen.dart'
    as _i24;
import 'package:app_template/Features/test/presentation/pages/test_pagination_demo_screen.dart'
    as _i25;
import 'package:app_template/Features/test/presentation/pages/test_platform_services_screen.dart'
    as _i26;
import 'package:app_template/Features/test/presentation/pages/test_predictive_back_demo_screen.dart'
    as _i27;
import 'package:app_template/Features/test/presentation/pages/test_settings_demo_screen.dart'
    as _i28;
import 'package:app_template/Features/test/presentation/pages/test_states_demo_screen.dart'
    as _i29;
import 'package:app_template/Features/test/presentation/pages/test_sync_queue_screen.dart'
    as _i30;
import 'package:app_template/Features/test/presentation/pages/test_theme_demo_screen.dart'
    as _i31;
import 'package:app_template/modules/data_transfer/presentation/pages/transfer_export_screen.dart'
    as _i32;
import 'package:app_template/modules/data_transfer/presentation/pages/transfer_import_screen.dart'
    as _i33;
import 'package:app_template/shared/screens/error_view.dart' as _i2;
import 'package:app_template/shared/screens/main_shell_page.dart' as _i6;
import 'package:app_template/shared/screens/widget_library_demo_screen.dart'
    as _i35;
import 'package:auto_route/auto_route.dart' as _i36;
import 'package:flutter/material.dart' as _i37;

/// generated route for
/// [_i1.ChangePasswordScreen]
class ChangePasswordRoute extends _i36.PageRouteInfo<void> {
  const ChangePasswordRoute({List<_i36.PageRouteInfo>? children})
    : super(ChangePasswordRoute.name, initialChildren: children);

  static const String name = 'ChangePasswordRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i1.ChangePasswordScreen();
    },
  );
}

/// generated route for
/// [_i2.ErrorView]
class ErrorRoute extends _i36.PageRouteInfo<ErrorRouteArgs> {
  ErrorRoute({
    _i37.Key? key,
    _i37.FlutterErrorDetails? errorDetails,
    String? message,
    List<_i36.PageRouteInfo>? children,
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

  static _i36.PageInfo page = _i36.PageInfo(
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

  final _i37.Key? key;

  final _i37.FlutterErrorDetails? errorDetails;

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
class ForgotPasswordRoute extends _i36.PageRouteInfo<void> {
  const ForgotPasswordRoute({List<_i36.PageRouteInfo>? children})
    : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i3.ForgotPasswordScreen();
    },
  );
}

/// generated route for
/// [_i4.HomeScreen]
class HomeRoute extends _i36.PageRouteInfo<void> {
  const HomeRoute({List<_i36.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i4.HomeScreen();
    },
  );
}

/// generated route for
/// [_i5.LoginScreen]
class LoginRoute extends _i36.PageRouteInfo<void> {
  const LoginRoute({List<_i36.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i5.LoginScreen();
    },
  );
}

/// generated route for
/// [_i6.MainShellPage]
class MainShellRoute extends _i36.PageRouteInfo<void> {
  const MainShellRoute({List<_i36.PageRouteInfo>? children})
    : super(MainShellRoute.name, initialChildren: children);

  static const String name = 'MainShellRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i6.MainShellPage();
    },
  );
}

/// generated route for
/// [_i7.NoteFormScreen]
class NoteFormRoute extends _i36.PageRouteInfo<NoteFormRouteArgs> {
  NoteFormRoute({
    _i37.Key? key,
    _i38.Note? note,
    List<_i36.PageRouteInfo>? children,
  }) : super(
         NoteFormRoute.name,
         args: NoteFormRouteArgs(key: key, note: note),
         initialChildren: children,
       );

  static const String name = 'NoteFormRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteFormRouteArgs>(
        orElse: () => const NoteFormRouteArgs(),
      );
      return _i7.NoteFormScreen(key: args.key, note: args.note);
    },
  );
}

class NoteFormRouteArgs {
  const NoteFormRouteArgs({this.key, this.note});

  final _i37.Key? key;

  final _i38.Note? note;

  @override
  String toString() {
    return 'NoteFormRouteArgs{key: $key, note: $note}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteFormRouteArgs) return false;
    return key == other.key && note == other.note;
  }

  @override
  int get hashCode => key.hashCode ^ note.hashCode;
}

/// generated route for
/// [_i8.NotesScreen]
class NotesRoute extends _i36.PageRouteInfo<void> {
  const NotesRoute({List<_i36.PageRouteInfo>? children})
    : super(NotesRoute.name, initialChildren: children);

  static const String name = 'NotesRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i8.NotesScreen();
    },
  );
}

/// generated route for
/// [_i9.RegisterScreen]
class RegisterRoute extends _i36.PageRouteInfo<void> {
  const RegisterRoute({List<_i36.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i9.RegisterScreen();
    },
  );
}

/// generated route for
/// [_i10.ResetPasswordScreen]
class ResetPasswordRoute extends _i36.PageRouteInfo<ResetPasswordRouteArgs> {
  ResetPasswordRoute({
    _i37.Key? key,
    required _i39.ForgotPasswordCubit cubit,
    List<_i36.PageRouteInfo>? children,
  }) : super(
         ResetPasswordRoute.name,
         args: ResetPasswordRouteArgs(key: key, cubit: cubit),
         initialChildren: children,
       );

  static const String name = 'ResetPasswordRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ResetPasswordRouteArgs>();
      return _i10.ResetPasswordScreen(key: args.key, cubit: args.cubit);
    },
  );
}

class ResetPasswordRouteArgs {
  const ResetPasswordRouteArgs({this.key, required this.cubit});

  final _i37.Key? key;

  final _i39.ForgotPasswordCubit cubit;

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
/// [_i11.SettingsScreen]
class SettingsRoute extends _i36.PageRouteInfo<void> {
  const SettingsRoute({List<_i36.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i11.SettingsScreen();
    },
  );
}

/// generated route for
/// [_i12.SplashScreen]
class SplashRoute extends _i36.PageRouteInfo<void> {
  const SplashRoute({List<_i36.PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i12.SplashScreen();
    },
  );
}

/// generated route for
/// [_i13.TestApiSimulatorScreen]
class TestApiSimulatorRoute extends _i36.PageRouteInfo<void> {
  const TestApiSimulatorRoute({List<_i36.PageRouteInfo>? children})
    : super(TestApiSimulatorRoute.name, initialChildren: children);

  static const String name = 'TestApiSimulatorRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i13.TestApiSimulatorScreen();
    },
  );
}

/// generated route for
/// [_i14.TestBlocStatesScreen]
class TestBlocStatesRoute extends _i36.PageRouteInfo<void> {
  const TestBlocStatesRoute({List<_i36.PageRouteInfo>? children})
    : super(TestBlocStatesRoute.name, initialChildren: children);

  static const String name = 'TestBlocStatesRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i14.TestBlocStatesScreen();
    },
  );
}

/// generated route for
/// [_i15.TestConnectivityScreen]
class TestConnectivityRoute extends _i36.PageRouteInfo<void> {
  const TestConnectivityRoute({List<_i36.PageRouteInfo>? children})
    : super(TestConnectivityRoute.name, initialChildren: children);

  static const String name = 'TestConnectivityRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i15.TestConnectivityScreen();
    },
  );
}

/// generated route for
/// [_i16.TestCrudDemoScreen]
class TestCrudDemoRoute extends _i36.PageRouteInfo<void> {
  const TestCrudDemoRoute({List<_i36.PageRouteInfo>? children})
    : super(TestCrudDemoRoute.name, initialChildren: children);

  static const String name = 'TestCrudDemoRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i16.TestCrudDemoScreen();
    },
  );
}

/// generated route for
/// [_i17.TestDashboardScreen]
class TestDashboardRoute extends _i36.PageRouteInfo<void> {
  const TestDashboardRoute({List<_i36.PageRouteInfo>? children})
    : super(TestDashboardRoute.name, initialChildren: children);

  static const String name = 'TestDashboardRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i17.TestDashboardScreen();
    },
  );
}

/// generated route for
/// [_i18.TestDataTransferScreen]
class TestDataTransferRoute extends _i36.PageRouteInfo<void> {
  const TestDataTransferRoute({List<_i36.PageRouteInfo>? children})
    : super(TestDataTransferRoute.name, initialChildren: children);

  static const String name = 'TestDataTransferRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i18.TestDataTransferScreen();
    },
  );
}

/// generated route for
/// [_i19.TestFailureDemoScreen]
class TestFailureDemoRoute extends _i36.PageRouteInfo<void> {
  const TestFailureDemoRoute({List<_i36.PageRouteInfo>? children})
    : super(TestFailureDemoRoute.name, initialChildren: children);

  static const String name = 'TestFailureDemoRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i19.TestFailureDemoScreen();
    },
  );
}

/// generated route for
/// [_i20.TestFeatureWizardScreen]
class TestFeatureWizardRoute extends _i36.PageRouteInfo<void> {
  const TestFeatureWizardRoute({List<_i36.PageRouteInfo>? children})
    : super(TestFeatureWizardRoute.name, initialChildren: children);

  static const String name = 'TestFeatureWizardRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i20.TestFeatureWizardScreen();
    },
  );
}

/// generated route for
/// [_i21.TestFormValidationScreen]
class TestFormValidationRoute extends _i36.PageRouteInfo<void> {
  const TestFormValidationRoute({List<_i36.PageRouteInfo>? children})
    : super(TestFormValidationRoute.name, initialChildren: children);

  static const String name = 'TestFormValidationRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i21.TestFormValidationScreen();
    },
  );
}

/// generated route for
/// [_i22.TestFormsDemoScreen]
class TestFormsDemoRoute extends _i36.PageRouteInfo<void> {
  const TestFormsDemoRoute({List<_i36.PageRouteInfo>? children})
    : super(TestFormsDemoRoute.name, initialChildren: children);

  static const String name = 'TestFormsDemoRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i22.TestFormsDemoScreen();
    },
  );
}

/// generated route for
/// [_i23.TestHapticsDemoScreen]
class TestHapticsDemoRoute extends _i36.PageRouteInfo<void> {
  const TestHapticsDemoRoute({List<_i36.PageRouteInfo>? children})
    : super(TestHapticsDemoRoute.name, initialChildren: children);

  static const String name = 'TestHapticsDemoRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i23.TestHapticsDemoScreen();
    },
  );
}

/// generated route for
/// [_i24.TestNavStackScreen]
class TestNavStackRoute extends _i36.PageRouteInfo<void> {
  const TestNavStackRoute({List<_i36.PageRouteInfo>? children})
    : super(TestNavStackRoute.name, initialChildren: children);

  static const String name = 'TestNavStackRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i24.TestNavStackScreen();
    },
  );
}

/// generated route for
/// [_i25.TestPaginationDemoScreen]
class TestPaginationDemoRoute extends _i36.PageRouteInfo<void> {
  const TestPaginationDemoRoute({List<_i36.PageRouteInfo>? children})
    : super(TestPaginationDemoRoute.name, initialChildren: children);

  static const String name = 'TestPaginationDemoRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i25.TestPaginationDemoScreen();
    },
  );
}

/// generated route for
/// [_i26.TestPlatformServicesScreen]
class TestPlatformServicesRoute extends _i36.PageRouteInfo<void> {
  const TestPlatformServicesRoute({List<_i36.PageRouteInfo>? children})
    : super(TestPlatformServicesRoute.name, initialChildren: children);

  static const String name = 'TestPlatformServicesRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i26.TestPlatformServicesScreen();
    },
  );
}

/// generated route for
/// [_i27.TestPredictiveBackDemoScreen]
class TestPredictiveBackDemoRoute extends _i36.PageRouteInfo<void> {
  const TestPredictiveBackDemoRoute({List<_i36.PageRouteInfo>? children})
    : super(TestPredictiveBackDemoRoute.name, initialChildren: children);

  static const String name = 'TestPredictiveBackDemoRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i27.TestPredictiveBackDemoScreen();
    },
  );
}

/// generated route for
/// [_i28.TestSettingsDemoScreen]
class TestSettingsDemoRoute extends _i36.PageRouteInfo<void> {
  const TestSettingsDemoRoute({List<_i36.PageRouteInfo>? children})
    : super(TestSettingsDemoRoute.name, initialChildren: children);

  static const String name = 'TestSettingsDemoRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i28.TestSettingsDemoScreen();
    },
  );
}

/// generated route for
/// [_i29.TestStatesDemoScreen]
class TestStatesDemoRoute extends _i36.PageRouteInfo<void> {
  const TestStatesDemoRoute({List<_i36.PageRouteInfo>? children})
    : super(TestStatesDemoRoute.name, initialChildren: children);

  static const String name = 'TestStatesDemoRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i29.TestStatesDemoScreen();
    },
  );
}

/// generated route for
/// [_i30.TestSyncQueueScreen]
class TestSyncQueueRoute extends _i36.PageRouteInfo<void> {
  const TestSyncQueueRoute({List<_i36.PageRouteInfo>? children})
    : super(TestSyncQueueRoute.name, initialChildren: children);

  static const String name = 'TestSyncQueueRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i30.TestSyncQueueScreen();
    },
  );
}

/// generated route for
/// [_i31.TestThemeDemoScreen]
class TestThemeDemoRoute extends _i36.PageRouteInfo<void> {
  const TestThemeDemoRoute({List<_i36.PageRouteInfo>? children})
    : super(TestThemeDemoRoute.name, initialChildren: children);

  static const String name = 'TestThemeDemoRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i31.TestThemeDemoScreen();
    },
  );
}

/// generated route for
/// [_i32.TransferExportScreen]
class TransferExportRoute extends _i36.PageRouteInfo<TransferExportRouteArgs> {
  TransferExportRoute({
    required String resource,
    _i37.Key? key,
    List<_i36.PageRouteInfo>? children,
  }) : super(
         TransferExportRoute.name,
         args: TransferExportRouteArgs(resource: resource, key: key),
         initialChildren: children,
       );

  static const String name = 'TransferExportRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TransferExportRouteArgs>();
      return _i32.TransferExportScreen(resource: args.resource, key: args.key);
    },
  );
}

class TransferExportRouteArgs {
  const TransferExportRouteArgs({required this.resource, this.key});

  final String resource;

  final _i37.Key? key;

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
/// [_i33.TransferImportScreen]
class TransferImportRoute extends _i36.PageRouteInfo<TransferImportRouteArgs> {
  TransferImportRoute({
    required String resource,
    _i37.Key? key,
    List<_i36.PageRouteInfo>? children,
  }) : super(
         TransferImportRoute.name,
         args: TransferImportRouteArgs(resource: resource, key: key),
         initialChildren: children,
       );

  static const String name = 'TransferImportRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TransferImportRouteArgs>();
      return _i33.TransferImportScreen(resource: args.resource, key: args.key);
    },
  );
}

class TransferImportRouteArgs {
  const TransferImportRouteArgs({required this.resource, this.key});

  final String resource;

  final _i37.Key? key;

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
/// [_i34.VerifyEmailScreen]
class VerifyEmailRoute extends _i36.PageRouteInfo<VerifyEmailRouteArgs> {
  VerifyEmailRoute({
    _i37.Key? key,
    required String email,
    List<_i36.PageRouteInfo>? children,
  }) : super(
         VerifyEmailRoute.name,
         args: VerifyEmailRouteArgs(key: key, email: email),
         initialChildren: children,
       );

  static const String name = 'VerifyEmailRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<VerifyEmailRouteArgs>();
      return _i34.VerifyEmailScreen(key: args.key, email: args.email);
    },
  );
}

class VerifyEmailRouteArgs {
  const VerifyEmailRouteArgs({this.key, required this.email});

  final _i37.Key? key;

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
/// [_i35.WidgetLibraryDemoScreen]
class WidgetLibraryDemoRoute extends _i36.PageRouteInfo<void> {
  const WidgetLibraryDemoRoute({List<_i36.PageRouteInfo>? children})
    : super(WidgetLibraryDemoRoute.name, initialChildren: children);

  static const String name = 'WidgetLibraryDemoRoute';

  static _i36.PageInfo page = _i36.PageInfo(
    name,
    builder: (data) {
      return const _i35.WidgetLibraryDemoScreen();
    },
  );
}
