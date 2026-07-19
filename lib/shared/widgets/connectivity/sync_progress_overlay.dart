import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

/// مربع حوار يعرض تقدم المزامنة — لا يمكن إغلاقه بالضغط خارجه.
///
/// widget مستقل — يأخذ [done] و[total] كمعاملات.
/// يُدار من خارجه عبر BlocBuilder يراقب حالة الـ SyncModule.
///
/// ```dart
/// // مثال الاستخدام مع الـ sync module
/// BlocBuilder<SyncManagerCubit, SyncManagerState>(
///   builder: (context, state) {
///     if (!state.isSyncing) return const SizedBox.shrink();
///     return SyncProgressOverlay(
///       done: state.completedSteps,
///       total: state.totalSteps,
///     );
///   },
/// )
/// ```
class SyncProgressOverlay extends StatelessWidget {
  const SyncProgressOverlay({
    super.key,
    required this.done,
    required this.total,
  });

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (done / total).clamp(0.0, 1.0) : null;

    return PopScope(
      canPop: false,
      child: Positioned.fill(
        child: ColoredBox(
          color: Colors.black54,
          child: Center(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 32,
                      color: context.colors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocaleKeys.syncing.tr(),
                      style: context.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: context.colors.dividerSubtle,
                      color: context.colors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '$done / $total',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
