import 'dart:async';
import 'package:app_template/modules/analytics/adapters/analytics_route_observer.dart';
import 'package:auto_route/auto_route.dart';
import 'package:app_template/features/startup/startup_destination.dart';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_template/features/auth/shared/session_sync_service.dart';
import 'package:app_template/features/settings/presentation/cubits/font_preference_cubit.dart';
import 'package:app_template/features/settings/presentation/cubits/theme_preset_cubit.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/foundation/contracts/locale_provider.dart';
import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:app_template/core/infra/session/locale_provider_impl.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/overlays/app_overlays.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/theme/app_theme_presets.dart';
import 'package:app_template/ui/theme/theme_reveal.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/deep_link_resolver.dart';
import 'package:app_template/routes/router.dart';
import 'package:app_template/routes/router.gr.dart';
import 'package:app_template/ui/state/connectivity/connectivity_cubit.dart';
import 'package:app_template/ui/widgets/connectivity/connectivity_overlay.dart';
import 'package:app_template/ui/widgets/layout/flavor_banner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kit_contracts/kit_contracts.dart';

class App extends StatefulWidget {
  final AdaptiveThemeMode? savedThemeMode;
  final AppFontOption savedFont;

  /// غائباً = `AppThemePresets.fallback`.
  final AppThemePreset? savedThemePreset;

  /// أينَ يبدأ التطبيق — قرارٌ اتُّخذ بـ`main()` قبل أول إطار.
  final StartupDestination startAt;

  const App({
    super.key,
    this.savedThemeMode,
    required this.savedFont,
    this.savedThemePreset,
    required this.startAt,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _router;
  late final AppTheme _appTheme;
  late final AppLocaleProvider _localeProvider;
  late final FontPreferenceCubit _fontCubit;
  late final ThemePresetCubit _presetCubit;
  StreamSubscription<AuthEvent>? _authSub;
  StreamSubscription<String>? _shortcutSub;
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
    _presetCubit = ThemePresetCubit(
      getIt<StorageService>(),
      initial: widget.savedThemePreset,
    );

    _authSub = AuthEventBus.instance.stream.listen(_handleAuthEvent);

    // A launcher shortcut is a route path (`kit_system`), pushed through the
    // router's guards like a deep link. Pushed, not navigated: navigating
    // rebuilds the stack and pops the shell, whose back guard reads that as
    // "exit the app?".
    if (getIt.isRegistered<AppShortcuts>()) {
      _shortcutSub = getIt<AppShortcuts>().launches.listen(_openShortcut);
    }

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

  /// On top of the start route, once the router has one: a cold start through
  /// a shortcut arrives before the first route is placed, and a push then
  /// lands underneath it — back would reveal a second, stray screen.
  void _openShortcut(String path) {
    if (_router.stack.isNotEmpty) {
      _router.pushPath(path);
      return;
    }
    void ready() {
      if (_router.stack.isEmpty) return;
      _router.removeListener(ready);
      _router.pushPath(path);
    }

    _router.addListener(ready);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _shortcutSub?.cancel();
    _sessionSync.dispose();
    _fontCubit.close();
    _presetCubit.close();
    super.dispose();
  }

  /// وجهةُ [App.startAt] كمسار.
  ///
  /// والمطابقةُ **شاملة** بقصد: وجهةٌ جديدة تصير خطأَ ترجمةٍ هنا، لا سقوطاً
  /// صامتاً إلى الدخول.
  PageRouteInfo get _startRoute => switch (widget.startAt) {
    StartupDestination.welcome => const WelcomeRoute(),
    StartupDestination.login => const LoginRoute(),
    StartupDestination.shell => const MainShellRoute(),
  };

  /// **Only a dead session sends anyone to sign in** — directly, with no
  /// intermediate screen.
  ///
  /// Switched exhaustively because the bus carries events that must NOT
  /// navigate: a handler that navigates on any event turns the first 403 over
  /// one missing permission into a sign-out mid-task. A refusal is not an
  /// authentication failure. A new event on the bus becomes a compile error
  /// here rather than a silent sign-out.
  ///
  /// `replaceAll` rather than `push`: the stack behind an expired session is
  /// screens that will refuse to load, and a back gesture would return to one.
  ///
  /// **And it says why** ([_announce]): a user dropped onto sign-in with no
  /// explanation reads it as a crash that lost their work.
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
      case AuthEvent.sessionRefreshDeferred:
        // A refresh that never reached a server. The session is untouched and
        // the user is mid-task — navigating here would sign them out for a
        // dropped packet. The offline banner already tells them what they
        // need.
        return;
    }

    // Where a dead session lands depends on whether signing in is required:
    // `optional` keeps the user in the app as a guest, and `none` never holds
    // a session to lose.
    switch (AppFeatures.authMode) {
      case AuthMode.none:
        return;
      case AuthMode.required:
        _router.replaceAll([const LoginRoute()]);
      case AuthMode.optional:
        _router.replaceAll([const MainShellRoute()]);
    }
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
    final initialPreset = _presetCubit.state;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _fontCubit),
        BlocProvider.value(value: _presetCubit),
      ],
      child: AdaptiveTheme(
        light: _appTheme.lightTheme(locale, initialFont, preset: initialPreset),
        dark: _appTheme.darkTheme(locale, initialFont, preset: initialPreset),
        initial: widget.savedThemeMode ?? AdaptiveThemeMode.system,
        builder: (theme, darkTheme) {
          return _ThemeSyncLayer(
            appTheme: _appTheme,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              // **لا تدرّجَ لونيّ عند تبدّل الثيم** — [ThemeReveal] يكشف الثيم
              // الجديد بدائرة، والتدرّجُ تحتها يُري ألواناً بين الثيمين داخلها.
              themeAnimationDuration: Duration.zero,
              theme: theme,
              darkTheme: darkTheme,
              locale: locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: [
                ...context.localizationDelegates,
                CountryLocalizations.delegate,
              ],
              scrollBehavior: GlobalScrollBehavior(),
              // **الوجهةُ الأولى تدخل من هنا لا من `initial: true`.**
              //
              // `deepLinkBuilder` يُنادى بكل رسالة رابطٍ من النظام — إقلاعاً
              // بارداً عادياً، أو رابطاً حقيقياً عند الإقلاع أو والتطبيق يعمل
              // أصلاً — لا مرّة واحدة فقط. القرار نفسه
              // بـ`resolveDeepLink` (`routes/deep_link_resolver.dart`) كي يبقى
              // قابلاً للاختبار بمعزل عن هذه الشجرة. و`AutoRoute(initial: true)`
              // **يُحذف من الموجّه** لأنه يفوز على قرار الإقلاع العادي؛ راجع
              // `router.dart`.
              routerConfig: _router.config(
                // **وهو غيرُ ضارٍّ حين يكون التحليلُ مطفأً** — يقرأ `getIt` لحظةَ
                // الحدث ويخرج إن لم تُسجَّل الخدمة. راجع الصنف.
                navigatorObservers: () => [AnalyticsRouteObserver()],
                deepLinkBuilder: (platformLink) => resolveDeepLink(
                  initial: platformLink.initial,
                  path: platformLink.path,
                  startRoute: _startRoute,
                ),
              ),
              builder: (context, child) {
                // AnnotatedRegion يُحدِّث ألوان أيقونات شريط الحالة والتنقل
                // تلقائياً عند التبديل بين الثيم الفاتح والداكن.
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final iconBrightness = isDark
                    ? Brightness.light
                    : Brightness.dark;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: iconBrightness,
                    statusBarBrightness: isDark
                        ? Brightness.dark
                        : Brightness.light,
                    systemNavigationBarColor: Colors.transparent,
                    systemNavigationBarDividerColor: Colors.transparent,
                    systemNavigationBarIconBrightness: iconBrightness,
                    systemNavigationBarContrastEnforced: false,
                  ),
                  // **فوق كل ما يُرسم** — يلتقط الشاشة كاملةً حين يتبدّل الثيم.
                  child: ThemeReveal(
                    // **مقاييسُ الشاشة تُحسب هنا، فوق كلّ مسارٍ وحوارٍ وورقة** —
                    // ومعها يُقيَّد «تكبير الخط» الآتي من إعدادات النظام. راجع
                    // [ResponsiveScope] لسبب السقف ١٫٣ وغياب الأرضية.
                    child: ResponsiveScope(
                      child: FlavorBanner(
                        // طبقاتُ الموديولات — كلٌّ يسجّل نفسه بـ[AppOverlays]،
                        // فلا يستورد هذا الملف أيّاً من طبقاتها.
                        child: AppOverlayHost(
                          navigatorKey: _router.navigatorKey,
                          child: _ConnectivityLayer(
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
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

/// Mounts the app-wide offline signal over every route.
///
/// [ConnectivityOverlay] is mounted once, here, so "the network stopped" has
/// one app-wide answer instead of whatever each screen does about it.
///
/// It sits inside `MaterialApp.builder` so it covers every route including
/// dialogs and sheets, and under `Positioned.fill` because the overlay's own
/// children are positioned — given loose constraints it would collapse to
/// nothing and place its banner off-screen.
class _ConnectivityLayer extends StatelessWidget {
  const _ConnectivityLayer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConnectivityCubit>.value(
      value: getIt<ConnectivityCubit>(),
      child: Stack(
        children: [
          child,
          const Positioned.fill(child: ConnectivityOverlay()),
        ],
      ),
    );
  }
}

class GlobalScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}

/// Syncs [AdaptiveTheme] whenever the font, theme preset or locale changes.
///
/// [AdaptiveTheme.didUpdateWidget] ignores `light`/`dark` prop changes,
/// so rebuilding the parent is not enough — we must call
/// [AdaptiveTheme.of(context).setTheme()] from *inside* its subtree.
///
/// This widget handles three triggers:
///   • Font change   → [BlocListener<FontPreferenceCubit>]
///   • Preset change → [BlocListener<ThemePresetCubit>]
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
  //
  // Both cubits are read at apply time rather than passed in: a font change
  // must not drop the current preset, nor a preset change the current font.
  void _applyThemeDeferred() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final font = context.read<FontPreferenceCubit>().state;
      final preset = context.read<ThemePresetCubit>().state;
      AdaptiveTheme.of(context).setTheme(
        light: widget.appTheme.lightTheme(context.locale, font, preset: preset),
        dark: widget.appTheme.darkTheme(context.locale, font, preset: preset),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.locale;
    if (_lastLocale != null && _lastLocale != locale) {
      _applyThemeDeferred();
    }
    _lastLocale = locale;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FontPreferenceCubit, AppFontOption>(
          listener: (_, _) => _applyThemeDeferred(),
        ),
        BlocListener<ThemePresetCubit, AppThemePreset>(
          listener: (_, _) => _applyThemeDeferred(),
        ),
      ],
      child: widget.child,
    );
  }
}
