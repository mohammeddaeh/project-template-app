import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/data_transfer/domain/transfer_resource.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

/// Asks which file format, before anything is downloaded.
///
/// The template button used to take `importFormats.first` silently. That is a
/// decision made on the user's behalf about a file they are going to open in a
/// specific program — and the two formats are not interchangeable: CSV opens
/// anywhere and survives being edited in a text editor, XLSX keeps real types
/// so dates sort as dates and long numbers do not lose digits.
///
/// The options come from the descriptor, so a server that stops offering one
/// stops offering it here — no build knows the list in advance.
class TransferFormatSheet extends StatelessWidget {
  const TransferFormatSheet._({required this.formats, required this.titleKey});

  final List<TransferFormat> formats;
  final String titleKey;

  /// Returns the chosen format, or `null` if the user backed out.
  ///
  /// Skips the sheet entirely when there is only one format: a dialog with one
  /// button is a click that teaches nothing.
  static Future<TransferFormat?> show(
    BuildContext context, {
    required List<TransferFormat> formats,
    required String titleKey,
  }) async {
    if (formats.isEmpty) return null;
    if (formats.length == 1) return formats.first;

    return showModalBottomSheet<TransferFormat>(
      context: context,
      showDragHandle: true,
      builder: (_) => TransferFormatSheet._(formats: formats, titleKey: titleKey),
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
            Text(titleKey.tr(), style: context.textTheme.headlineMedium),
            const SizedBox(height: 12),
            for (final format in formats)
              ListTile(
                leading: Icon(
                  format == TransferFormat.csv
                      ? Icons.description_outlined
                      : Icons.grid_on_outlined,
                  color: context.colorScheme.primary,
                ),
                title: Text(format.label, style: context.textTheme.headlineSmall),
                // The trade-off in one line, so the choice is informed rather
                // than a coin toss between two acronyms.
                subtitle: Text(
                  format == TransferFormat.csv
                      ? LocaleKeys.formatCsvHint.tr()
                      : LocaleKeys.formatXlsxHint.tr(),
                  style: context.textTheme.bodySmall,
                ),
                onTap: () => Navigator.of(context).pop(format),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
