/// Launcher shortcuts and the store review prompt — registered behind
/// `kit_contracts`.
///
/// Installed with `dart run scripts/kit.dart add system`; the app never
/// imports this file — `lib/core/di/kits.g.dart` does.
library;

import 'package:get_it/get_it.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'src/quick_actions_shortcuts.dart';
import 'src/store_review.dart';

void registerSystemKit(GetIt getIt) {
  getIt
    ..registerLazySingleton<AppShortcuts>(QuickActionsShortcuts.new)
    ..registerLazySingleton<AppReview>(StoreReview.new);
}
