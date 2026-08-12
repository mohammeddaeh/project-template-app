import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/locale/locale_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/routes/router.gr.dart';

/// **The module's entire public surface for a feature screen.**
///
/// ```dart
/// IconButton(
///   icon: const Icon(Icons.import_export),
///   onPressed: () => DataTransferSheet.show(context, resource: 'notes'),
/// )
/// ```
///
/// One line, and the feature is transferable — provided the backend declares
/// the resource. `resource` is a plain string on purpose: a typed enum would
/// have to be regenerated every time the server gained a resource, which is
/// exactly the coupling this module exists to avoid.
class DataTransferSheet extends StatelessWidget {
  const DataTransferSheet._({required this.resource});

  final String resource;

  /// Opens the chooser. Safe to call unconditionally.
  ///
  /// When `AppFeatures.dataTransfer` is off, nothing is registered in the
  /// injector, so opening a screen would throw on its first `getIt` call.
  /// Refusing here — with a message rather than silence — means a caller never
  /// has to guard the call site, and a disabled module cannot produce a crash.
  static Future<void> show(
    BuildContext context, {
    required String resource,
  }) async {
    if (!AppFeatures.dataTransfer) {
      context.feedback.warning(LocaleKeys.transferDisabled.tr());
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => DataTransferSheet._(resource: resource),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return SafeArea(
      child: Padding(
        padding: 16.horizontalPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.dataTransfer.tr(),
              style: context.textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              LocaleKeys.dataTransferSubtitle.tr(),
              style: context.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _Option(
              icon: Icons.file_download_outlined,
              label: LocaleKeys.exportTitle.tr(),
              onTap: () => _go(context, TransferExportRoute(resource: resource)),
            ),
            _Option(
              icon: Icons.file_upload_outlined,
              label: LocaleKeys.importTitle.tr(),
              onTap: () => _go(context, TransferImportRoute(resource: resource)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Closes the sheet **before** pushing.
  ///
  /// Pushing first leaves the sheet in the stack under the new screen, so
  /// popping back lands on a stale sheet the user has to dismiss twice.
  void _go(BuildContext context, PageRouteInfo<dynamic> route) {
    final router = context.router;
    Navigator.of(context).pop();
    router.push(route);
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: context.colorScheme.primary),
        title: Text(label, style: context.textTheme.headlineSmall),
        trailing: Icon(
          context.isRtl ? Icons.chevron_left : Icons.chevron_right,
          size: 20,
        ),
        onTap: onTap,
      );
}
