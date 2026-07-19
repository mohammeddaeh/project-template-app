// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:app_template/Features/home/presentation/pages/home_screen.dart'
    as _i2;
import 'package:app_template/Features/settings/presentation/pages/settings_screen.dart'
    as _i4;
import 'package:app_template/Features/splash/presentation/pages/splash_screen.dart'
    as _i5;
import 'package:app_template/Features/test/presentation/pages/test_api_simulator_screen.dart'
    as _i6;
import 'package:app_template/Features/test/presentation/pages/test_bloc_states_screen.dart'
    as _i7;
import 'package:app_template/Features/test/presentation/pages/test_connectivity_screen.dart'
    as _i8;
import 'package:app_template/Features/test/presentation/pages/test_crud_demo_screen.dart'
    as _i9;
import 'package:app_template/Features/test/presentation/pages/test_dashboard_screen.dart'
    as _i10;
import 'package:app_template/Features/test/presentation/pages/test_failure_demo_screen.dart'
    as _i11;
import 'package:app_template/Features/test/presentation/pages/test_feature_wizard_screen.dart'
    as _i12;
import 'package:app_template/Features/test/presentation/pages/test_form_validation_screen.dart'
    as _i13;
import 'package:app_template/Features/test/presentation/pages/test_forms_demo_screen.dart'
    as _i14;
import 'package:app_template/Features/test/presentation/pages/test_haptics_demo_screen.dart'
    as _i15;
import 'package:app_template/Features/test/presentation/pages/test_nav_stack_screen.dart'
    as _i16;
import 'package:app_template/Features/test/presentation/pages/test_pagination_demo_screen.dart'
    as _i17;
import 'package:app_template/Features/test/presentation/pages/test_platform_services_screen.dart'
    as _i18;
import 'package:app_template/Features/test/presentation/pages/test_predictive_back_demo_screen.dart'
    as _i19;
import 'package:app_template/Features/test/presentation/pages/test_settings_demo_screen.dart'
    as _i20;
import 'package:app_template/Features/test/presentation/pages/test_states_demo_screen.dart'
    as _i21;
import 'package:app_template/Features/test/presentation/pages/test_sync_queue_screen.dart'
    as _i22;
import 'package:app_template/Features/test/presentation/pages/test_theme_demo_screen.dart'
    as _i23;
import 'package:app_template/shared/screens/error_view.dart' as _i1;
import 'package:app_template/shared/screens/main_shell_page.dart' as _i3;
import 'package:app_template/shared/screens/widget_library_demo_screen.dart'
    as _i24;
import 'package:auto_route/auto_route.dart' as _i25;
import 'package:flutter/material.dart' as _i26;

/// generated route for
/// [_i1.ErrorView]
class ErrorRoute extends _i25.PageRouteInfo<ErrorRouteArgs> {
  ErrorRoute({
    _i26.Key? key,
    _i26.FlutterErrorDetails? errorDetails,
    String? message,
    List<_i25.PageRouteInfo>? children,
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

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ErrorRouteArgs>(
        orElse: () => const ErrorRouteArgs(),
      );
      return _i1.ErrorView(
        key: args.key,
        errorDetails: args.errorDetails,
        message: args.message,
      );
    },
  );
}

class ErrorRouteArgs {
  const ErrorRouteArgs({this.key, this.errorDetails, this.message});

  final _i26.Key? key;

  final _i26.FlutterErrorDetails? errorDetails;

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
/// [_i2.HomeScreen]
class HomeRoute extends _i25.PageRouteInfo<void> {
  const HomeRoute({List<_i25.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i2.HomeScreen();
    },
  );
}

/// generated route for
/// [_i3.MainShellPage]
class MainShellRoute extends _i25.PageRouteInfo<void> {
  const MainShellRoute({List<_i25.PageRouteInfo>? children})
    : super(MainShellRoute.name, initialChildren: children);

  static const String name = 'MainShellRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i3.MainShellPage();
    },
  );
}

/// generated route for
/// [_i4.SettingsScreen]
class SettingsRoute extends _i25.PageRouteInfo<void> {
  const SettingsRoute({List<_i25.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i4.SettingsScreen();
    },
  );
}

/// generated route for
/// [_i5.SplashScreen]
class SplashRoute extends _i25.PageRouteInfo<void> {
  const SplashRoute({List<_i25.PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i5.SplashScreen();
    },
  );
}

/// generated route for
/// [_i6.TestApiSimulatorScreen]
class TestApiSimulatorRoute extends _i25.PageRouteInfo<void> {
  const TestApiSimulatorRoute({List<_i25.PageRouteInfo>? children})
    : super(TestApiSimulatorRoute.name, initialChildren: children);

  static const String name = 'TestApiSimulatorRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i6.TestApiSimulatorScreen();
    },
  );
}

/// generated route for
/// [_i7.TestBlocStatesScreen]
class TestBlocStatesRoute extends _i25.PageRouteInfo<void> {
  const TestBlocStatesRoute({List<_i25.PageRouteInfo>? children})
    : super(TestBlocStatesRoute.name, initialChildren: children);

  static const String name = 'TestBlocStatesRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i7.TestBlocStatesScreen();
    },
  );
}

/// generated route for
/// [_i8.TestConnectivityScreen]
class TestConnectivityRoute extends _i25.PageRouteInfo<void> {
  const TestConnectivityRoute({List<_i25.PageRouteInfo>? children})
    : super(TestConnectivityRoute.name, initialChildren: children);

  static const String name = 'TestConnectivityRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i8.TestConnectivityScreen();
    },
  );
}

/// generated route for
/// [_i9.TestCrudDemoScreen]
class TestCrudDemoRoute extends _i25.PageRouteInfo<void> {
  const TestCrudDemoRoute({List<_i25.PageRouteInfo>? children})
    : super(TestCrudDemoRoute.name, initialChildren: children);

  static const String name = 'TestCrudDemoRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i9.TestCrudDemoScreen();
    },
  );
}

/// generated route for
/// [_i10.TestDashboardScreen]
class TestDashboardRoute extends _i25.PageRouteInfo<void> {
  const TestDashboardRoute({List<_i25.PageRouteInfo>? children})
    : super(TestDashboardRoute.name, initialChildren: children);

  static const String name = 'TestDashboardRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i10.TestDashboardScreen();
    },
  );
}

/// generated route for
/// [_i11.TestFailureDemoScreen]
class TestFailureDemoRoute extends _i25.PageRouteInfo<void> {
  const TestFailureDemoRoute({List<_i25.PageRouteInfo>? children})
    : super(TestFailureDemoRoute.name, initialChildren: children);

  static const String name = 'TestFailureDemoRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i11.TestFailureDemoScreen();
    },
  );
}

/// generated route for
/// [_i12.TestFeatureWizardScreen]
class TestFeatureWizardRoute extends _i25.PageRouteInfo<void> {
  const TestFeatureWizardRoute({List<_i25.PageRouteInfo>? children})
    : super(TestFeatureWizardRoute.name, initialChildren: children);

  static const String name = 'TestFeatureWizardRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i12.TestFeatureWizardScreen();
    },
  );
}

/// generated route for
/// [_i13.TestFormValidationScreen]
class TestFormValidationRoute extends _i25.PageRouteInfo<void> {
  const TestFormValidationRoute({List<_i25.PageRouteInfo>? children})
    : super(TestFormValidationRoute.name, initialChildren: children);

  static const String name = 'TestFormValidationRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i13.TestFormValidationScreen();
    },
  );
}

/// generated route for
/// [_i14.TestFormsDemoScreen]
class TestFormsDemoRoute extends _i25.PageRouteInfo<void> {
  const TestFormsDemoRoute({List<_i25.PageRouteInfo>? children})
    : super(TestFormsDemoRoute.name, initialChildren: children);

  static const String name = 'TestFormsDemoRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i14.TestFormsDemoScreen();
    },
  );
}

/// generated route for
/// [_i15.TestHapticsDemoScreen]
class TestHapticsDemoRoute extends _i25.PageRouteInfo<void> {
  const TestHapticsDemoRoute({List<_i25.PageRouteInfo>? children})
    : super(TestHapticsDemoRoute.name, initialChildren: children);

  static const String name = 'TestHapticsDemoRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i15.TestHapticsDemoScreen();
    },
  );
}

/// generated route for
/// [_i16.TestNavStackScreen]
class TestNavStackRoute extends _i25.PageRouteInfo<void> {
  const TestNavStackRoute({List<_i25.PageRouteInfo>? children})
    : super(TestNavStackRoute.name, initialChildren: children);

  static const String name = 'TestNavStackRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i16.TestNavStackScreen();
    },
  );
}

/// generated route for
/// [_i17.TestPaginationDemoScreen]
class TestPaginationDemoRoute extends _i25.PageRouteInfo<void> {
  const TestPaginationDemoRoute({List<_i25.PageRouteInfo>? children})
    : super(TestPaginationDemoRoute.name, initialChildren: children);

  static const String name = 'TestPaginationDemoRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i17.TestPaginationDemoScreen();
    },
  );
}

/// generated route for
/// [_i18.TestPlatformServicesScreen]
class TestPlatformServicesRoute extends _i25.PageRouteInfo<void> {
  const TestPlatformServicesRoute({List<_i25.PageRouteInfo>? children})
    : super(TestPlatformServicesRoute.name, initialChildren: children);

  static const String name = 'TestPlatformServicesRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i18.TestPlatformServicesScreen();
    },
  );
}

/// generated route for
/// [_i19.TestPredictiveBackDemoScreen]
class TestPredictiveBackDemoRoute extends _i25.PageRouteInfo<void> {
  const TestPredictiveBackDemoRoute({List<_i25.PageRouteInfo>? children})
    : super(TestPredictiveBackDemoRoute.name, initialChildren: children);

  static const String name = 'TestPredictiveBackDemoRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i19.TestPredictiveBackDemoScreen();
    },
  );
}

/// generated route for
/// [_i20.TestSettingsDemoScreen]
class TestSettingsDemoRoute extends _i25.PageRouteInfo<void> {
  const TestSettingsDemoRoute({List<_i25.PageRouteInfo>? children})
    : super(TestSettingsDemoRoute.name, initialChildren: children);

  static const String name = 'TestSettingsDemoRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i20.TestSettingsDemoScreen();
    },
  );
}

/// generated route for
/// [_i21.TestStatesDemoScreen]
class TestStatesDemoRoute extends _i25.PageRouteInfo<void> {
  const TestStatesDemoRoute({List<_i25.PageRouteInfo>? children})
    : super(TestStatesDemoRoute.name, initialChildren: children);

  static const String name = 'TestStatesDemoRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i21.TestStatesDemoScreen();
    },
  );
}

/// generated route for
/// [_i22.TestSyncQueueScreen]
class TestSyncQueueRoute extends _i25.PageRouteInfo<void> {
  const TestSyncQueueRoute({List<_i25.PageRouteInfo>? children})
    : super(TestSyncQueueRoute.name, initialChildren: children);

  static const String name = 'TestSyncQueueRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i22.TestSyncQueueScreen();
    },
  );
}

/// generated route for
/// [_i23.TestThemeDemoScreen]
class TestThemeDemoRoute extends _i25.PageRouteInfo<void> {
  const TestThemeDemoRoute({List<_i25.PageRouteInfo>? children})
    : super(TestThemeDemoRoute.name, initialChildren: children);

  static const String name = 'TestThemeDemoRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i23.TestThemeDemoScreen();
    },
  );
}

/// generated route for
/// [_i24.WidgetLibraryDemoScreen]
class WidgetLibraryDemoRoute extends _i25.PageRouteInfo<void> {
  const WidgetLibraryDemoRoute({List<_i25.PageRouteInfo>? children})
    : super(WidgetLibraryDemoRoute.name, initialChildren: children);

  static const String name = 'WidgetLibraryDemoRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i24.WidgetLibraryDemoScreen();
    },
  );
}
