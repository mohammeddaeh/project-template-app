import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/connectivity/connectivity_service.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

/// Renders one attachment, resolving it through the three-state access path.
///
/// ```
/// on disk       → the image
/// not here + online  → fetch, verify, then the image
/// not here + offline → "not available offline", **not an error**
/// ```
///
/// ## The third state is the one that matters
///
/// An optional file evicted last week, on a device out of coverage today, is a
/// system working exactly as designed. Drawing a red error for it teaches the
/// user that the app is broken — and a user who has learned that stops
/// reporting the failures that are real.
///
/// So the offline state gets a neutral placeholder and a sentence, and the
/// failed state — where the server *was* reached and something went wrong —
/// gets the error treatment and a retry.
class AttachmentView extends StatefulWidget {
  const AttachmentView({
    required this.attachmentId,
    super.key,
    this.height = 160,
    this.fit = BoxFit.cover,
  });

  final String attachmentId;
  final double height;
  final BoxFit fit;

  @override
  State<AttachmentView> createState() => _AttachmentViewState();
}

class _AttachmentViewState extends State<AttachmentView> {
  late Future<AttachmentAccess> _access;

  @override
  void initState() {
    super.initState();
    _access = _resolve();
  }

  @override
  void didUpdateWidget(AttachmentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A recycled list tile must not keep showing the previous row's photo —
    // the failure mode is a grid where every image is one scroll behind.
    if (oldWidget.attachmentId != widget.attachmentId) {
      _access = _resolve();
    }
  }

  Future<AttachmentAccess> _resolve() async {
    if (!AppFeatures.offlineSync ||
        !getIt.isRegistered<AttachmentDownloadManager>()) {
      return const AttachmentUnavailable(AttachmentUnavailability.fetchFailed);
    }
    return getIt<AttachmentDownloadManager>().access(
      widget.attachmentId,
      isOnline: await ConnectivityService.isOnline(),
    );
  }

  void _retry() => setState(() => _access = _resolve());

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: FutureBuilder<AttachmentAccess>(
        future: _access,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _Placeholder(
              icon: Icons.hourglass_empty_rounded,
              label: LocaleKeys.attachmentLoading.tr(),
              height: widget.height,
            );
          }

          return switch (snapshot.data) {
            AttachmentReady(:final file) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(file.path),
                  fit: widget.fit,
                  // A file that vanished between resolution and paint — the
                  // cache manager can run at any moment. Handled rather than
                  // thrown, because the answer is simply to fetch it again.
                  errorBuilder: (_, _, _) => _Placeholder(
                    icon: Icons.refresh_rounded,
                    label: LocaleKeys.attachmentUnavailable.tr(),
                    height: widget.height,
                    onTap: _retry,
                  ),
                ),
              ),
            AttachmentUnavailable(reason: AttachmentUnavailability.offline) =>
              _Placeholder(
                icon: Icons.cloud_off_rounded,
                label: LocaleKeys.attachmentOfflineUnavailable.tr(),
                height: widget.height,
              ),
            _ => _Placeholder(
                icon: Icons.error_outline_rounded,
                label: LocaleKeys.attachmentFailed.tr(),
                height: widget.height,
                isError: true,
                onTap: _retry,
              ),
          };
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.label,
    required this.height,
    this.isError = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final double height;
  final bool isError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Neutral by default. Only a real failure — the server answered and
    // something went wrong — gets the error colour; "not here, you are
    // offline" is an ordinary state of an offline-first app.
    final color = isError ? context.colors.stateError : context.colors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: context.colors.bgNeutral,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
