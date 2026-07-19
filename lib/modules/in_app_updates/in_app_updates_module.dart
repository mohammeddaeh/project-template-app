import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

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
    if (Platform.isAndroid) {
      await _checkAndroid(context, mode);
    } else if (Platform.isIOS && iosAppId != null) {
      await _redirectIos(context, iosAppId);
    }
  }

  // ── Android ────────────────────────────────────────────────────────────────

  static Future<void> _checkAndroid(
      BuildContext context, UpdateMode mode) async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        LogService.info('InAppUpdates: no update available', tag: 'UPDATE');
        return;
      }

      LogService.info(
          'InAppUpdates: update available — mode=${mode.name}', tag: 'UPDATE');

      if (mode == UpdateMode.immediate) {
        await InAppUpdate.performImmediateUpdate();
      } else {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      // Not critical — update check failures should never crash the app.
      LogService.warning('InAppUpdates: check failed: $e', tag: 'UPDATE');
    }
  }

  // ── iOS ────────────────────────────────────────────────────────────────────

  static Future<void> _redirectIos(
      BuildContext context, String appId) async {
    if (!context.mounted) return;
    final goToStore = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(LocaleKeys.updateAvailableTitle.tr()),
        content: Text(LocaleKeys.updateAvailableMessage.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleKeys.later.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocaleKeys.updateNow.tr()),
          ),
        ],
      ),
    );

    if (goToStore == true) {
      final url = Uri.parse('https://apps.apple.com/app/id$appId');
      LogService.info('InAppUpdates: redirecting to App Store', tag: 'UPDATE');
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

/// Update mode for Android in-app updates.
enum UpdateMode {
  /// Download in background — user continues using the app.
  flexible,

  /// Full-screen blocking update — use for critical security patches.
  immediate,
}
