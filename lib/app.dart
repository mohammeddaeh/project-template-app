import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_template/Features/auth/shared/session_sync_service.dart';
import 'package:app_template/Features/settings/presentation/cubits/font_preference_cubit.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/foundation/contracts/locale_provider.dart';
import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:app_template/core/infra/session/locale_provider_impl.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/app_theme.dart';
import 'package:app_template/resources/locale_keys.g.dart';
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
  late final SessionSyncService _sessionSync;

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

    // Started here rather than from a screen: the account must stay in step
    // with the server for as long as the app is alive, and any screen that
    // owned this would stop syncing the moment it was popped.
    _sessionSync = getIt<SessionSyncService>()..start();

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
    _sessionSync.dispose();
    _fontCubit.close();
    super.dispose();
  }

  /// A dead session sends the user to sign-in, and nowhere else.
  ///
  /// This used to route to `SplashRoute` with a comment explaining that no auth
  /// feature existed yet. One does now — and bouncing through splash re-ran the
  /// token check that had just failed, which on a slow disk read showed the
  /// logo for two seconds before landing on the same screen this goes to
  /// directly.
  ///
  /// `replaceAll` rather than `push`: the stack behind an expired session is
  /// screens that will refuse to load, and leaving them there means a back
  /// gesture returns to one.
  /// **Only a dead session sends anyone to sign in.**
  ///
  /// Switched exhaustively rather than acting on arrival, because this bus now
  /// carries an event that must NOT navigate. Qirtas hit exactly that: its
  /// handler navigated for any event, so the first 403 over one missing
  /// permission signed the user out in the middle of a task. A refusal is not
  /// an authentication failure.
  ///
  /// The exhaustive form is the guard: a future event added to the bus becomes
  /// a compile error here rather than a silent sign-out.
  ///
  /// **And it says why.** This used to navigate and nothing else: a user
  /// mid-task was dropped onto the sign-in screen with no explanation, which
  /// reads as the app crashing and losing their work — the two states that
  /// most look like a bug are the two the app knows the exact cause of. The
  /// keys existed (`sessionRevoked` was written the day the multi-device
  /// module landed) and simply had no call site.
  void _handleAuthEvent(AuthEvent event) {
    final String reasonKey;

    switch (event) {
      case AuthEvent.sessionExpired:
        reasonKey = LocaleKeys.sessionExpiredMessage;
      case AuthEvent.sessionRevoked:
        // Distinct from expiry on purpose: "your session ended" invites the
        // user to sign back in, while "another device signed you out" is the
        // only wording that lets them notice a sign-in they did not make.
        reasonKey = LocaleKeys.sessionRevoked;
      case AuthEvent.permissionsStale:
        // Handled by `AbilitiesStore`, which re-reads `/authz/me`. Nothing
        // about the session changed, so the user stays where they are.
        return;
    }

    _router.replaceAll([const LoginRoute()]);
    _announce(reasonKey);
  }

  /// Shows the sign-out reason on the screen the user has just landed on.
  ///
  /// Deferred to the next frame and read off the router's navigator: the
  /// feedback overlay lives *below* `MaterialApp`, so this State's own
  /// `context` cannot host a toast, and the login route is not mounted until
  /// the frame after `replaceAll`.
  ///
  /// Silent when no context is available — the app is tearing down, and a
  /// missing toast must never become an exception on top of an expired
  /// session.
  void _announce(String messageKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _router.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      ctx.feedback.warning(messageKey.tr());
    });
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
