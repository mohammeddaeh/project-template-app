import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/presentation/error/failure_ui_mapper.dart';
import 'package:app_template/presentation/error/ui_action.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/states/app_state_widget.dart';

/// A [Failure], rendered as the state it actually is.
///
/// ## Why this exists
///
/// Every list in this app used to render every failure the same way: a red
/// `ErrorStateWidget`. So "the server rejected this" and "your phone has no
/// network" produced the same panel, with the same icon, offering the same
/// retry — and the one thing the reader could have acted on (turn the wifi
/// back on) was the one thing the screen did not say. `lib/CLAUDE.md` has
/// required `NoInternetWidget` for the offline case since the widget was
/// written; nothing enforced it, so no list obeyed it.
///
/// Losing the network mid-scroll is the common case, not the exotic one, and
/// it is the only failure where the reader — not the server, not the app — is
/// the one who can fix it.
///
/// ## The two shapes
///
/// [FailureStateView] fills the space a list would occupy (nothing loaded).
/// [FailureStateView.compact] is one row for the bottom of a list that already
/// has rows: a full-height panel under fifteen loaded items reads as "the list
/// broke", when what happened is "the next page did not arrive".
class FailureStateView extends StatelessWidget {
  const FailureStateView({
    super.key,
    required this.failure,
    this.onRetry,
    this.compact = false,
  });

  /// One row instead of a full panel — for the tail of an already-populated
  /// list, where the loaded rows are still valid and still readable.
  const FailureStateView.compact({
    super.key,
    required this.failure,
    this.onRetry,
  }) : compact = true;

  final Failure failure;
  final VoidCallback? onRetry;
  final bool compact;

  /// Failures the reader can fix, as opposed to failures they can only retry.
  ///
  /// [BadCertificateFailure] is grouped here deliberately: in practice it is a
  /// captive-portal wifi (hotel, café, airport) answering the TLS handshake
  /// itself. To the person holding the phone that is "the internet is not
  /// working", and the fix is the same one.
  static bool isOffline(Failure failure) =>
      failure is NoInternetFailure || failure is BadCertificateFailure;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency
    context.locale;

    final action = FailureUiMapper.toAction(failure);

    // Session expiry navigates away on its own and cancellation is deliberate.
    // Drawing anything for either paints an error over a screen that is being
    // torn down — which reads as a fault in the screen the reader is leaving.
    if (action is! ShowError) return const SizedBox.shrink();

    final offline = isOffline(failure);
    final timedOut = failure is TimeoutFailure;

    if (compact) {
      return _CompactRow(
        message: offline
            ? LocaleKeys.noInternetConnection.tr()
            : action.message,
        icon: _iconFor(offline: offline, timedOut: timedOut),
        isOffline: offline,
        onRetry: onRetry,
      );
    }

    return AppStateWidget(
      type: offline ? AppStateType.noInternet : AppStateType.error,
      icon: _iconFor(offline: offline, timedOut: timedOut),
      titleKey: offline ? LocaleKeys.noInternet : action.message,
      // Only the offline case gets a second line, because it is the only one
      // where there is something for the reader to go and do.
      descriptionKey: offline ? LocaleKeys.offlineListHint : null,
      onAction: onRetry,
      actionLabelKey: onRetry == null ? null : LocaleKeys.retry,
    );
  }

  IconData _iconFor({required bool offline, required bool timedOut}) {
    if (offline) return Icons.wifi_off_rounded;
    if (timedOut) return Icons.timer_off_outlined;
    return Icons.error_outline;
  }
}

/// The tail-of-list shape: says what failed, offers the one button, and takes
/// the height of a row rather than the height of a screen.
class _CompactRow extends StatelessWidget {
  const _CompactRow({
    required this.message,
    required this.icon,
    required this.isOffline,
    required this.onRetry,
  });

  final String message;
  final IconData icon;
  final bool isOffline;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = isOffline ? colors.statusWarningFg : colors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmall?.copyWith(color: tone),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(LocaleKeys.retry.tr()),
            ),
          ],
        ],
      ),
    );
  }
}
