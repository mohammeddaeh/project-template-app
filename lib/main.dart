import 'dart:async';
import 'package:app_template/features/startup/startup_resolver.dart';
import 'package:app_template/features/auth/shared/current_user_repository.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:app_template/core/infra/session/data_origin_guard.dart';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/core/platform/observability/app_bloc_observer.dart';
import 'package:app_template/core/platform/storage/persistence_keys.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/modules_bootstrap.dart';
import 'package:app_template/resources/assets_files.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/widgets/wrappers/error_boundary.dart';
import 'package:app_template/app.dart';

void main() async {
  await runZonedGuarded(_bootstrap, _onError);
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── تهيئةٌ متزامنة، بلا كلفة ───────────────────────────────────────────────
  Bloc.observer = AppBlocObserver();
  EquatableConfig.stringify = true;
  Env.init();
  ErrorBoundary.install();

  // ── ثلاثةٌ مستقلّة — تُنتظر معاً لا واحدةً خلف أخرى ─────────────────────────
  //
  // و`initializeDateFormatting` **بلغتَي التطبيق وحدهما**: بلا وسيط تُهيَّأ
  // رموزُ ~١٨٠ لغة، ولا تُقرأ منها إلا `ar` و`en`. (والافتراضُ عند غياب
  // `Intl.defaultLocale` هو `en_US`، ويسقط إلى `en`.)
  await Future.wait<void>([
    Hive.initFlutter(),
    EasyLocalization.ensureInitialized(),
    initializeDateFormatting('ar'),
    initializeDateFormatting('en'),
  ]);

  // ── جذر التركيب — يبقى مُنتظَراً، فـ`App.initState` يقرأ منه ───────────────
  await configureInjection(Env.flavor);

  // ── الموديولات الاختيارية — **تُبدأ ولا تُنتظر** ───────────────────────────
  //
  // هذا العمل **لا يرسم شيئاً**: يفتح قواعد ويجدول عمّالاً عبر platform
  // channel. وانتظارُه هنا كان يجعله يقع قبل أن يرى المستخدم شيئاً؛ وبالفصل
  // يجري خلف شعار النظام وبالتوازي مع تسخين محرّك فلاتر.
  //
  // ومن ينتظره: `StartupResolver.resolve` عبر [ModulesBootstrap.ready].
  ModulesBootstrap.start(getIt);

  // ── ثلاثُ عملياتٍ مستقلّة تُطلَق معاً ثم تُحصَّل ────────────────────────────
  final fontKeyFuture = getIt<StorageService>().readString(
    PersistenceKeys.selectedFontKey,
  );
  final themeModeFuture = AdaptiveTheme.getThemeMode();
  // **الهاتف عموديٌّ وحده، واللوح بالاتجاهين.** وقفلُ الجميع عمودياً لا يُبقي
  // اللوحَ عمودياً بل **يحبسه**: أندرويد يضع النشاطَ المقفول داخل نافذةٍ بنسبة
  // هاتف ويملأ ما حولها بالأسود. راجع [OrientationPolicy].
  final systemUiFuture = Future.wait<void>([
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
    OrientationPolicy.applyAtStartup(),
  ]);

  final fontKey = await fontKeyFuture;
  final savedThemeMode = await themeModeFuture;
  await systemUiFuture;

  final savedFont = fontKey != null
      ? AppFonts.byKey(fontKey)
      : AppFonts.available.first;

  // ── الوجهةُ الأولى — تُحسب هنا، فيكون أوّلُ إطارٍ هو الوجهةَ نفسَها ─────────
  //
  // **ولا شاشةَ سبلاش بفلاتر.** كانت `SplashScreen` مساراً أوّلياً يعرض الشعار
  // ويقرّر ثم يستبدل نفسَه، فيرى المستخدم شعارَين متتاليَين — شعارَ النظام ثم
  // شعارَ فلاتر — ولو تطابقا بقيَ تلاشي النظام بينهما فيُقرأ انتقالَين.
  // و`splash` النظام يبقى معلَّقاً حتى يرسم فلاتر أوّلَ إطار، فما يقع هنا يقع
  // **خلف شعارٍ مرئي** لا خلف شاشةٍ سوداء.
  //
  // و[ModulesBootstrap.ready] يُنتظر **داخل** [StartupResolver.resolve] لا هنا
  // — راجع الصنف لترتيبه مع `debugSkipLogin`.
  final startAt = await StartupResolver(
    getIt<SessionRepository>(),
    getIt<CurrentUserRepository>(),
    getIt<DataOriginGuard>(),
  ).resolve();

  // ── Run ───────────────────────────────────────────────────────────────────
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: AssetsFiles.translation,
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      assetLoader: const CodegenLoader(),
      child: App(
        savedThemeMode: savedThemeMode,
        savedFont: savedFont,
        startAt: startAt,
      ),
    ),
  );
}

void _onError(Object error, StackTrace stack) {
  debugPrint('Uncaught error: $error\n$stack');
}
