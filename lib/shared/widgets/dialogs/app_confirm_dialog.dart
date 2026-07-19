import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/extensions/dialog_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

/// Dialog تأكيد موحّد — يُستخدم قبل أي عملية خطرة (حذف، تسجيل خروج، ...).
///
/// ```dart
/// // حذف — زر التأكيد أحمر
/// AppConfirmDialog.show(
///   context,
///   titleKey:   LocaleKeys.deleteConfirmTitle,
///   messageKey: LocaleKeys.deleteConfirmMessage,
///   isDestructive: true,
///   onConfirm: () => context.read<ProductsListCubit>().delete(id),
/// );
///
/// // تسجيل خروج — زر التأكيد عادي
/// AppConfirmDialog.show(
///   context,
///   titleKey:   LocaleKeys.logoutTitle,
///   messageKey: LocaleKeys.logoutMessage,
///   onConfirm: () => context.read<AuthCubit>().logout(),
/// );
///
/// // مع انتظار النتيجة
/// final confirmed = await AppConfirmDialog.show(context, ...);
/// if (confirmed) { ... }
/// ```
class AppConfirmDialog {
  AppConfirmDialog._();

  /// يُظهر الـ dialog ويُرجع `true` عند التأكيد، `false` عند الإلغاء.
  ///
  /// [titleKey] و [messageKey] — مفاتيح `LocaleKeys.*` تُترجم تلقائياً.
  /// [isDestructive] — يُحوّل زر التأكيد للأحمر (للحذف والعمليات الخطرة).
  static Future<bool> show(
    BuildContext context, {
    required String titleKey,
    required String messageKey,
    String? confirmKey,
    String? cancelKey,
    bool isDestructive = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) async {
    final result = await context.showCustomDialog<bool>(
      barrierDismissible: barrierDismissible,
      child: _AppConfirmDialogContent(
        title:         titleKey.tr(),
        message:       messageKey.tr(),
        confirmText:   (confirmKey ?? LocaleKeys.confirm).tr(),
        cancelText:    (cancelKey  ?? LocaleKeys.cancel).tr(),
        isDestructive: isDestructive,
        onConfirm:     onConfirm,
        onCancel:      onCancel,
      ),
    );
    return result ?? false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content widget (مُعزَّل لتسهيل الاختبار والقراءة)
// ─────────────────────────────────────────────────────────────────────────────

class _AppConfirmDialogContent extends StatelessWidget {
  const _AppConfirmDialogContent({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.isDestructive,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              if (isDestructive) ...[
                Icon(Icons.warning_amber_rounded,
                    color: context.colors.stateError, size: 22),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDestructive
                        ? context.colors.stateError
                        : context.colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // الرسالة
          Text(
            message,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // الأزرار
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // إلغاء
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  onCancel?.call();
                },
                child: Text(
                  cancelText,
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ),
              const SizedBox(width: 8),

              // تأكيد
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isDestructive
                      ? context.colors.stateError
                      : context.colors.primary,
                ),
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onConfirm?.call();
                },
                child: Text(confirmText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
