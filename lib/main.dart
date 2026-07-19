import 'dart:async';

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
import 'package:app_template/app.dart';

// d
void main() async {
  await runZonedGuarded(_bootstrap, _onError);
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Storage ───────────────────────────────────────────────────────────────
  await Hive.initFlutter();

  // ── Localization ──────────────────────────────────────────────────────────
  await EasyLocalization.ensureInitialized();
  // إلزامي قبل أي DateFormat بلغة غير en — بدونه: LocaleDataException وقت التشغيل
  await initializeDateFormatting();

  // ── State management ──────────────────────────────────────────────────────
  Bloc.observer = AppBlocObserver();
  EquatableConfig.stringify = true;

  // ── Environment / flavor ──────────────────────────────────────────────────
  Env.init();

  // ── Dependency injection ──────────────────────────────────────────────────
  await configureInjection(Env.flavor);

  // ── Optional modules (Firebase, push, sync …) ────────────────────────────
  await ModulesBootstrap.initializeAll(getIt);

  // ── Font preference — الخط المحفوظ ───────────────────────────────────────
  final fontKey = await getIt<StorageService>().readString(
    PersistenceKeys.selectedFontKey,
  );
  final savedFont = fontKey != null
      ? AppFonts.byKey(fontKey)
      : AppFonts.available.first;

  // ── System UI — Edge-to-Edge ──────────────────────────────────────────────
  // يجعل التطبيق يرسم خلف status bar وشريط التنقل/منطقة الإيماءات.
  // النتيجة: MediaQuery.size.height ثابت في وضع الأزرار والإيماءات.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // ── Device orientation ────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Theme persistence ─────────────────────────────────────────────────────
  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  // ── Run ───────────────────────────────────────────────────────────────────
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: AssetsFiles.translation,
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      assetLoader: const CodegenLoader(),
      child: App(savedThemeMode: savedThemeMode, savedFont: savedFont),
    ),
  );
}

void _onError(Object error, StackTrace stack) {
  debugPrint('Uncaught error: $error\n$stack');
}
// 01