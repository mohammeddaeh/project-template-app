import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/in_app_updates/data/app_update_settings_api.dart';
import 'package:app_template/modules/in_app_updates/data/app_update_settings_store.dart';
import 'package:app_template/modules/in_app_updates/domain/app_update_settings.dart';
import 'package:app_template/modules/in_app_updates/integration/app_update_settings_refresh_task.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

/// Entry point for the in-app updates module.
///
/// Checks whether a newer version is available on the store and prompts
/// the user to update.
///
/// - **Android**: uses Google Play's native in-app update API
///   (`Flexible` or `Immediate` update flow).
/// - **iOS**: redirects to the App Store (no native API exists).
///
/// ## Setup — see `SETUP.md` in this folder.
///
/// ## Usage
/// ```dart
/// // Call after login or on app resume:
/// await InAppUpdatesModule.checkAndPrompt(
///   context,
///   mode: UpdateMode.flexible,   // or UpdateMode.immediate
/// );
/// ```
abstract final class InAppUpdatesModule {
  static const _refreshTaskName = 'in-app-updates.settings-refresh';
  static bool _initialized = false;
  static bool _promptInProgress = false;
  static String? _lastPromptedSignature;

  /// Registers the local snapshot and the task that refreshes it inside sync.
  /// It performs no network request itself.
  static Future<void> initialize(GetIt di) async {
    if (_initialized || !AppFeatures.inAppUpdates) return;
    if (!di.isRegistered<AppUpdateSettingsStore>()) {
      di.registerLazySingleton<AppUpdateSettingsStore>(
        () => AppUpdateSettingsStore(di<StorageService>()),
      );
    }
    if (!di.isRegistered<AppUpdateSettingsApi>()) {
      di.registerLazySingleton<AppUpdateSettingsApi>(
        () => AppUpdateSettingsApi(di<Dio>()),
      );
    }
    registerAppUpdateRefreshTask(di, instanceName: _refreshTaskName);
    _initialized = true;
  }

  /// Checks for an available update and prompts the user.
  ///
  /// [mode] (Android only):
  /// - [UpdateMode.flexible]  — downloads in background, installs when ready.
  /// - [UpdateMode.immediate] — full-screen blocking update (critical releases).
  ///
  /// On iOS this method redirects to the App Store page if [iosAppId] is set.
  static Future<void> checkAndPrompt(
    BuildContext context, {
    UpdateMode mode = UpdateMode.flexible,
    String? iosAppId,
  }) async {
    // The guard lives here, not at the call site, so the application keeps one
    // unconditional line and the flag stays the single answer to "is this on?".
    // Same shape as every other module's `initialize()`.
    if (!AppFeatures.inAppUpdates) return;

    final di = GetIt.instance;
    if (!di.isRegistered<AppUpdateSettingsStore>()) return;
    final settings = await di<AppUpdateSettingsStore>().read();
    if (settings == null) return;

    final currentVersion = (await PackageInfo.fromPlatform()).version;
    if (!isVersionOlder(currentVersion, settings.version)) return;
    final signature =
        '${settings.version}|${settings.downloadUrl}|'
        '${settings.forceUpdate}';
    if (_promptInProgress || _lastPromptedSignature == signature) return;
    if (!context.mounted) return;

    _promptInProgress = true;
    try {
      final effectiveMode = settings.forceUpdate ? UpdateMode.immediate : mode;
      if (Platform.isAndroid) {
        final handled = await _checkAndroid(effectiveMode);
        if (handled) {
          _lastPromptedSignature = signature;
        } else if (settings.downloadUrl.isNotEmpty && context.mounted) {
          // Mark only when a real prompt is about to be shown. Previously this
          // was stamped before checking Play/the URL, so an empty URL consumed
          // the version forever and adding its link later did nothing.
          _lastPromptedSignature = signature;
          await _promptForUrl(context, settings);
        }
      } else if (Platform.isIOS) {
        final fallback = iosAppId == null
            ? ''
            : 'https://apps.apple.com/app/id$iosAppId';
        final url = settings.downloadUrl.isEmpty
            ? fallback
            : settings.downloadUrl;
        if (url.isNotEmpty && context.mounted) {
          _lastPromptedSignature = signature;
          await _promptForUrl(
            context,
            AppUpdateSettings(
              version: settings.version,
              downloadUrl: url,
              forceUpdate: settings.forceUpdate,
            ),
          );
        }
      }
    } finally {
      _promptInProgress = false;
    }
  }

  // ── Android ────────────────────────────────────────────────────────────────

  static Future<bool> _checkAndroid(UpdateMode mode) async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        LogService.info('InAppUpdates: no update available', tag: 'UPDATE');
        return false;
      }

      LogService.info(
        'InAppUpdates: update available — mode=${mode.name}',
        tag: 'UPDATE',
      );

      if (mode == UpdateMode.immediate) {
        await InAppUpdate.performImmediateUpdate();
      } else {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
      return true;
    } catch (e) {
      // Not critical — update check failures should never crash the app.
      LogService.warning('InAppUpdates: check failed: $e', tag: 'UPDATE');
      return false;
    }
  }

  // ── iOS ────────────────────────────────────────────────────────────────────

  static Future<void> _promptForUrl(
    BuildContext context,
    AppUpdateSettings settings,
  ) async {
    if (!context.mounted) return;
    final goToStore = await showDialog<bool>(
      context: context,
      barrierDismissible: !settings.forceUpdate,
      builder: (_) => PopScope(
        canPop: !settings.forceUpdate,
        child: AlertDialog(
          title: Text(LocaleKeys.updateAvailableTitle.tr()),
          content: Text(LocaleKeys.updateAvailableMessage.tr()),
          actions: [
            if (!settings.forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(LocaleKeys.later.tr()),
              ),
            TextButton(
              onPressed: settings.forceUpdate
                  ? () => _openUpdateUrl(settings.downloadUrl)
                  : () => Navigator.pop(context, true),
              child: Text(LocaleKeys.updateNow.tr()),
            ),
          ],
        ),
      ),
    );

    if (goToStore == true) {
      await _openUpdateUrl(settings.downloadUrl);
    }
  }

  static Future<void> _openUpdateUrl(String rawUrl) async {
    final url = Uri.tryParse(rawUrl);
    if (url == null || !url.hasScheme) return;
    LogService.info('InAppUpdates: opening update URL', tag: 'UPDATE');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

/// Update mode for Android in-app updates.
enum UpdateMode {
  /// Download in background — user continues using the app.
  flexible,

  /// Full-screen blocking update — use for critical security patches.
  immediate,
}
