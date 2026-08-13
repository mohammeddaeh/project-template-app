import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/data_transfer/presentation/widgets/csv_preview_view.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

/// What to do with a file that has just been downloaded.
///
/// Replaces the previous behaviour, which opened the OS share sheet the instant
/// a download finished. That was one decision taken on the user's behalf and a
/// second one hidden: the file sat in the app's **temporary** directory, so
/// "share" was the only way it survived at all, and anyone who dismissed the
/// share sheet silently lost the file to the next cache sweep.
///
/// Four explicit choices instead:
///
/// | Action | What it does |
/// |---|---|
/// | Preview  | Parses the CSV and shows it as a table — before committing to anything |
/// | Save     | Writes it wherever the user picks, permanently |
/// | Share    | Hands it to another app |
/// | Open     | Opens it in Excel / Sheets / whatever handles the type |
class TransferFileSheet extends StatelessWidget {
  const TransferFileSheet._({required this.file, required this.titleKey});

  final File file;
  final String titleKey;

  static Future<void> show(
    BuildContext context, {
    required File file,
    required String titleKey,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => TransferFileSheet._(file: file, titleKey: titleKey),
      );

  bool get _isCsv => p.extension(file.path).toLowerCase() == '.csv';

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
            Text(titleKey.tr(), style: context.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.basename(file.path),
                    style: context.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _readableSize(file.lengthSync()),
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Preview first: it is the only action that changes nothing, and
            // the one that tells the user whether the other three are worth
            // taking.
            if (_isCsv)
              _Action(
                icon: Icons.table_rows_outlined,
                labelKey: LocaleKeys.filePreview,
                onTap: () => _preview(context),
              )
            else
              // XLSX is a zip container. Rendering it here would mean a
              // spreadsheet library for a worse result than the app the user
              // already has for the job.
              _Action(
                icon: Icons.open_in_new,
                labelKey: LocaleKeys.filePreviewExternal,
                onTap: () => _open(context),
              ),

            _Action(
              icon: Icons.save_alt,
              labelKey: LocaleKeys.fileSave,
              subtitleKey: LocaleKeys.fileSaveHint,
              onTap: () => _save(context),
            ),
            _Action(
              icon: Icons.ios_share,
              labelKey: LocaleKeys.fileShare,
              onTap: () => _share(context),
            ),
            if (_isCsv)
              _Action(
                icon: Icons.open_in_new,
                labelKey: LocaleKeys.fileOpenExternal,
                onTap: () => _open(context),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _preview(BuildContext context) async {
    final navigator = Navigator.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // Nearly full height: a table in a short sheet shows two columns and
      // teaches nothing about whether the file is right.
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      builder: (_) => CsvPreviewView(file: file),
    );
    if (!navigator.mounted) return;
  }

  /// Writes the file wherever the user chooses.
  ///
  /// `FilePicker.saveFile` rather than `path_provider`'s downloads directory:
  /// `getDownloadsDirectory()` **returns null on Android**, so the obvious
  /// implementation silently does nothing on the platform most of these users
  /// are on. `saveFile` goes through the system document picker, which needs no
  /// storage permission and lets the user put the file somewhere they will find
  /// it again.
  Future<void> _save(BuildContext context) async {
    final messenger = context;
    try {
      final bytes = await file.readAsBytes();
      final saved = await FilePicker.saveFile(
        fileName: p.basename(file.path),
        bytes: bytes,
      );

      if (!messenger.mounted) return;
      Navigator.of(messenger).pop();

      if (saved == null) return; // Cancelled — not an error.
      messenger.feedback.success(LocaleKeys.fileSaved.tr());
    } catch (e) {
      LogService.error('Transfer save failed: $e', tag: 'DATA_TRANSFER');
      if (!messenger.mounted) return;
      messenger.feedback.error(LocaleKeys.fileSaveFailed.tr());
    }
  }

  Future<void> _share(BuildContext context) async {
    final navigator = Navigator.of(context);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: p.basename(file.path)),
    );
    if (!navigator.mounted) return;
    navigator.pop();
  }

  Future<void> _open(BuildContext context) async {
    final result = await OpenFilex.open(file.path);
    if (!context.mounted) return;

    if (result.type != ResultType.done) {
      // "No app can open this" is a real, common outcome on a bare device, and
      // it must not look like the download failed.
      LogService.warning(
        'Transfer open — ${result.type}: ${result.message}',
        tag: 'DATA_TRANSFER',
      );
      context.feedback.warning(LocaleKeys.fileOpenFailed.tr());
      return;
    }
    Navigator.of(context).pop();
  }

  static String _readableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.labelKey,
    required this.onTap,
    this.subtitleKey,
  });

  final IconData icon;
  final String labelKey;
  final String? subtitleKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: context.colorScheme.primary),
        title: Text(labelKey.tr(), style: context.textTheme.headlineSmall),
        subtitle: subtitleKey == null
            ? null
            : Text(subtitleKey!.tr(), style: context.textTheme.bodySmall),
        onTap: onTap,
      );
}
