import 'package:get_it/get_it.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// The developer tour on the home tab — see `SETUP.md` beside this file.
///
/// Registers nothing: the tour is widgets alone, drawn by `HomeScreen` when
/// [AppFeatures.showcase] is on. The plugin keeps the module's one line in
/// `ModulesBootstrap`, so «is it on?» reads like every other module.
abstract final class ShowcasePlugin {
  static const String _tag = 'SHOWCASE';

  static Future<void> initialize(GetIt di) async {
    LogService.debug(
      AppFeatures.showcase
          ? 'ShowcasePlugin on — HomeScreen shows the tour.'
          : 'ShowcasePlugin disabled (AppFeatures.showcase=false).',
      tag: _tag,
    );
  }
}
