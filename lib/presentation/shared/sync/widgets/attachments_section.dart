import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/media/media_service.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

import 'attachment_view.dart';

/// Photos and files for one row — **the entire cost of giving a feature
/// attachments on screen.**
///
/// ```dart
/// AttachmentsSection(entityName: 'notes', entityLocalId: note.id)
/// ```
///
/// Self-contained like `LogoutSection` and `PendingChangesChip`: it resolves its
/// own dependencies and renders nothing when `AppFeatures.offlineSync` is off,
/// so the call site never has to ask whether the module exists.
///
/// ## Capture is durable before it is visible
///
/// The camera path is `MediaService.capturePrivate()` — which does **not** save
/// to the device gallery — and the file is copied into private storage by
/// [AttachmentCapture] before the row is written. Between the shutter and that
/// copy, the OS may reclaim the temporary file; every step after it is safe.
class AttachmentsSection extends StatefulWidget {
  const AttachmentsSection({
    required this.entityName,
    required this.entityLocalId,
    super.key,
    this.role = 'photo',
  });

  final String entityName;
  final String entityLocalId;
  final String role;

  @override
  State<AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends State<AttachmentsSection> {
  List<AttachmentRecord> _records = const [];
  bool _busy = false;

  bool get _enabled =>
      AppFeatures.offlineSync && getIt.isRegistered<AttachmentStore>();

  @override
  void initState() {
    super.initState();
    if (_enabled) _load();
  }

  Future<void> _load() async {
    // Local first, and drawn immediately: the list of files this device knows
    // about is available offline, and waiting for the network to render it
    // would make an offline-first screen behave like an online one.
    final local = await getIt<AttachmentStore>().findForEntity(
      entityName: widget.entityName,
      entityLocalId: widget.entityLocalId,
    );
    if (!mounted) return;
    setState(() => _records = local);

    // Then reconcile with the server, if it answers. A refusal is not an error
    // here — the list already on screen is the truthful one for a device with
    // no connection.
    final refreshed = await getIt<AttachmentMetadataSync>().refreshForEntity(
      entityName: widget.entityName,
      entityLocalId: widget.entityLocalId,
    );
    if (!mounted || refreshed == null) return;

    final merged = await getIt<AttachmentStore>().findForEntity(
      entityName: widget.entityName,
      entityLocalId: widget.entityLocalId,
    );
    if (mounted) setState(() => _records = merged);
  }

  Future<void> _capture() async {
    setState(() => _busy = true);
    try {
      final file = await getIt<MediaService>().capturePrivate();
      if (file == null) return;

      final record = await getIt<AttachmentCapture>().capture(
        source: file,
        entityName: widget.entityName,
        entityLocalId: widget.entityLocalId,
        role: widget.role,
        mimeType: 'image/jpeg',
      );

      if (!mounted) return;
      if (record == null) {
        // The capture could not be secured, and the caller was holding the only
        // copy. Said out loud: a silent failure here is a photograph the user
        // believes they took.
        context.feedback.error(LocaleKeys.attachmentCaptureFailed.tr());
        return;
      }
      setState(() => _records = [..._records, record]);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;
    if (!_enabled) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                LocaleKeys.attachments.tr(),
                style: context.textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: _busy ? null : _capture,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(LocaleKeys.attachmentAdd.tr()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_records.isEmpty)
          Text(
            LocaleKeys.attachmentsEmpty.tr(),
            style: context.textTheme.bodySmall
                ?.copyWith(color: context.colors.textMuted),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _records.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final record = _records[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  AttachmentView(attachmentId: record.attachmentId, height: 110),
                  // A file this device still owes the server is marked — the
                  // user who took it is the one person who can tell whether it
                  // matters that it has not gone yet.
                  if (record.uploadStatus.isOwed)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 16,
                        color: context.colors.statusWarningFg,
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
