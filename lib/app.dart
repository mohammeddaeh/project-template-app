import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_template/Features/settings/presentation/cubits/font_preference_cubit.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/foundation/contracts/locale_provider.dart';
import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:app_template/core/infra/session/locale_provider_impl.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/presentation/theme/app_theme.dart';
import 'package:app_template/routes/router.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/shared/widgets/layout/flavor_banner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatefulWidget {
  final AdaptiveThemeMode? savedThemeMode;
  final AppFontOption savedFont;

  const App({
    super.key,
    this.savedThemeMode,
    required this.savedFont,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _router;
  late final AppTheme _appTheme;
  late final AppLocaleProvider _localeProvider;
  late final FontPreferenceCubit _fontCubit;
  StreamSubscription<AuthEvent>? _authSub;

  @override
  void initState() {
    super.initState();
    _router = getIt<AppRouter>();
    _appTheme = getIt<AppTheme>();
    _localeProvider = getIt<LocaleProvider>() as AppLocaleProvider;
    _fontCubit = FontPreferenceCubit(
      getIt<StorageService>(),
      initial: widget.savedFont,
    );

    _authSub = AuthEventBus.instance.stream.listen(_handleAuthEvent);

    // الإطار الأول قبل أن يُطبَّق AnnotatedRegion — يضمن شفافية فورية.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localeProvider.setLanguage(context.locale.languageCode);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _fontCubit.close();
    super.dispose();
  }

  void _handleAuthEvent(AuthEvent event) {
    // لا يوجد auth feature بهذا التيمبليت — بدّل هذا لمسار الدخول الفعلي
    // بمجرد بناء feature حقيقية (راجع lib/Features/CLAUDE.md).
    _router.replaceAll([const SplashRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final initialFont = _fontCubit.state;

    return BlocProvider.value(
      value: _fontCubit,
      child: AdaptiveTheme(
        light: _appTheme.lightTheme(locale, initialFont),
        dark: _appTheme.darkTheme(locale, initialFont),
        initial: widget.savedThemeMode ?? AdaptiveThemeMode.system,
        builder: (theme, darkTheme) {
          return _ThemeSyncLayer(
            appTheme: _appTheme,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: theme,
              darkTheme: darkTheme,
              locale: locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: [
                ...context.localizationDelegates,
                CountryLocalizations.delegate,
              ],
              scrollBehavior: GlobalScrollBehavior(),
              routerConfig: _router.config(
                navigatorObservers: () => [],
              ),
              builder: (context, child) {
                // AnnotatedRegion يُحدِّث ألوان أيقونات شريط الحالة والتنقل
                // تلقائياً عند التبديل بين الثيم الفاتح والداكن.
                final isDark =
                    Theme.of(context).brightness == Brightness.dark;
                final iconBrightness =
                    isDark ? Brightness.light : Brightness.dark;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: iconBrightness,
                    statusBarBrightness:
                        isDark ? Brightness.dark : Brightness.light,
                    systemNavigationBarColor: Colors.transparent,
                    systemNavigationBarDividerColor: Colors.transparent,
                    systemNavigationBarIconBrightness: iconBrightness,
                    systemNavigationBarContrastEnforced: false,
                  ),
                  child: FlavorBanner(
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class GlobalScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}

/// Syncs [AdaptiveTheme] whenever the font or locale changes.
///
/// [AdaptiveTheme.didUpdateWidget] ignores `light`/`dark` prop changes,
/// so rebuilding the parent is not enough — we must call
/// [AdaptiveTheme.of(context).setTheme()] from *inside* its subtree.
///
/// This widget handles two triggers:
///   • Font change  → [BlocListener<FontPreferenceCubit>]
///   • Locale change → [didChangeDependencies] (EasyLocalization notifies here)
class _ThemeSyncLayer extends StatefulWidget {
  const _ThemeSyncLayer({required this.appTheme, required this.child});

  final AppTheme appTheme;
  final Widget child;

  @override
  State<_ThemeSyncLayer> createState() => _ThemeSyncLayerState();
}

class _ThemeSyncLayerState extends State<_ThemeSyncLayer> {
  Locale? _lastLocale;

  // Defer to post-frame to avoid "setState() called during build"
  // which occurs when BlocListener fires its callback inside build(),
  // or when didChangeDependencies() runs while AdaptiveTheme is building.
  void _applyThemeDeferred(AppFontOption font) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AdaptiveTheme.of(context).setTheme(
        light: widget.appTheme.lightTheme(context.locale, font),
        dark: widget.appTheme.darkTheme(context.locale, font),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.locale;
    if (_lastLocale != null && _lastLocale != locale) {
      final font = context.read<FontPreferenceCubit>().state;
      _applyThemeDeferred(font);
    }
    _lastLocale = locale;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FontPreferenceCubit, AppFontOption>(
      listener: (_, font) => _applyThemeDeferred(font),
      child: widget.child,
    );
  }
}
